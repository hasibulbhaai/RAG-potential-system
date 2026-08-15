"""
RAG Assistant API
==================
FastAPI service exposing:
  GET  /health           - liveness/readiness probe
  POST /ingest            - ingest a document into the vector store
  POST /chat               - RAG-augmented chat completion
  GET  /metrics           - Prometheus metrics endpoint

Design notes:
  - Kept deliberately simple/synchronous for POC clarity. A production version
    would move ingestion to an async task queue (e.g., Celery/RQ) so large
    documents don't block the request thread.
  - No authentication is implemented here — see docs/SECURITY.md for what's
    explicitly out of scope for this POC and why.
"""

import logging
import os
import time
from typing import List, Optional

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import Response
from pydantic import BaseModel

from rag_chain import RAGPipeline
from metrics import (
    REQUEST_COUNT,
    REQUEST_LATENCY,
    INGEST_COUNT,
    generate_metrics,
)

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("rag-api")

app = FastAPI(
    title="Self-Hosted RAG Assistant API",
    description="Reference RAG platform: Ollama + Qdrant + LangChain",
    version="1.0.0",
)

# Instantiated once at startup; holds connections to Ollama + Qdrant
pipeline: Optional[RAGPipeline] = None


@app.on_event("startup")
def startup_event():
    global pipeline
    logger.info("Initializing RAG pipeline...")
    pipeline = RAGPipeline(
        ollama_host=os.getenv("OLLAMA_HOST", "http://ollama:11434"),
        qdrant_host=os.getenv("QDRANT_HOST", "qdrant"),
        qdrant_port=int(os.getenv("QDRANT_PORT", "6333")),
        model_name=os.getenv("MODEL_NAME", "llama3.1:8b"),
        embedding_model=os.getenv("EMBEDDING_MODEL", "nomic-embed-text"),
        collection_name=os.getenv("COLLECTION_NAME", "rag_documents"),
    )
    pipeline.ensure_collection()
    logger.info("RAG pipeline ready.")


class ChatRequest(BaseModel):
    question: str
    top_k: int = 4  # number of retrieved chunks to use as context


class ChatResponse(BaseModel):
    answer: str
    sources: List[str]
    latency_ms: float


class IngestResponse(BaseModel):
    filename: str
    chunks_ingested: int
    status: str


@app.get("/health")
def health():
    """
    Liveness/readiness probe. Checks that both Ollama and Qdrant are reachable,
    not just that this process is running — a shallow "return 200" health check
    hides real failures in dependent services.
    """
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not initialized")
    ollama_ok = pipeline.check_ollama()
    qdrant_ok = pipeline.check_qdrant()
    if not (ollama_ok and qdrant_ok):
        raise HTTPException(
            status_code=503,
            detail=f"Dependency check failed — ollama_ok={ollama_ok}, qdrant_ok={qdrant_ok}",
        )
    return {"status": "healthy", "ollama": ollama_ok, "qdrant": qdrant_ok}


@app.post("/ingest", response_model=IngestResponse)
async def ingest(file: UploadFile = File(...)):
    """
    Ingests a document (.txt, .md, or .pdf) into the vector store.
    For a POC this is synchronous; see module docstring for the production note.
    """
    start = time.time()
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not initialized")

    allowed_ext = (".txt", ".md", ".pdf")
    if not file.filename.lower().endswith(allowed_ext):
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed: {allowed_ext}",
        )

    content = await file.read()
    try:
        chunks_ingested = pipeline.ingest_document(file.filename, content)
    except Exception as e:
        logger.exception("Ingestion failed")
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {e}")

    INGEST_COUNT.inc()
    logger.info(
        "Ingested %s -> %d chunks in %.2fs",
        file.filename,
        chunks_ingested,
        time.time() - start,
    )
    return IngestResponse(
        filename=file.filename,
        chunks_ingested=chunks_ingested,
        status="success",
    )


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    """
    RAG-augmented chat: retrieves top_k relevant chunks from Qdrant, then
    prompts the LLM (via Ollama) with those chunks as context.
    """
    start = time.time()
    if pipeline is None:
        raise HTTPException(status_code=503, detail="Pipeline not initialized")

    with REQUEST_LATENCY.labels(endpoint="/chat").time():
        try:
            answer, sources = pipeline.query(req.question, top_k=req.top_k)
        except Exception as e:
            logger.exception("Chat query failed")
            REQUEST_COUNT.labels(endpoint="/chat", status="error").inc()
            raise HTTPException(status_code=500, detail=f"Query failed: {e}")

    REQUEST_COUNT.labels(endpoint="/chat", status="success").inc()
    latency_ms = (time.time() - start) * 1000
    return ChatResponse(answer=answer, sources=sources, latency_ms=round(latency_ms, 2))


@app.get("/metrics")
def metrics():
    """Prometheus scrape endpoint."""
    return Response(content=generate_metrics(), media_type="text/plain")
