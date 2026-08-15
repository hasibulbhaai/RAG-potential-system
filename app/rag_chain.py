"""
RAG Pipeline
============
Wraps document chunking, embedding, vector storage (Qdrant), and LLM
querying (Ollama) behind a single class so main.py stays thin.

Design notes:
  - Chunk size/overlap are tuned conservatively (500/50) for general text.
    Document-type-specific tuning (e.g., code vs. prose) is a documented
    follow-up in docs/ARCHITECTURE.md, not implemented here.
  - Retrieval is plain top-k similarity search. No re-ranking step —
    intentionally out of scope for a POC; flagged as a "next step" in the
    architecture doc since it's a common interview follow-up question.
"""

import io
import logging
from typing import List, Tuple

import requests
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Qdrant
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from qdrant_client import QdrantClient
from qdrant_client.http import models as qdrant_models
from pypdf import PdfReader

logger = logging.getLogger("rag-api.pipeline")

PROMPT_TEMPLATE = """You are a helpful assistant answering questions using ONLY the context provided below.
If the answer is not contained in the context, say "I don't have enough information to answer that" rather than guessing.

Context:
{context}

Question: {question}

Answer:"""


class RAGPipeline:
    def __init__(
        self,
        ollama_host: str,
        qdrant_host: str,
        qdrant_port: int,
        model_name: str,
        embedding_model: str,
        collection_name: str,
    ):
        self.ollama_host = ollama_host
        self.model_name = model_name
        self.collection_name = collection_name

        self.qdrant_client = QdrantClient(host=qdrant_host, port=qdrant_port)
        self.embeddings = OllamaEmbeddings(base_url=ollama_host, model=embedding_model)
        self.llm = Ollama(base_url=ollama_host, model=model_name, temperature=0.1)
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=500,
            chunk_overlap=50,
        )

    # ------------------------------------------------------------------ #
    # Health checks
    # ------------------------------------------------------------------ #
    def check_ollama(self) -> bool:
        try:
            resp = requests.get(f"{self.ollama_host}/api/tags", timeout=5)
            return resp.status_code == 200
        except requests.RequestException:
            return False

    def check_qdrant(self) -> bool:
        try:
            self.qdrant_client.get_collections()
            return True
        except Exception:
            return False

    # ------------------------------------------------------------------ #
    # Collection setup
    # ------------------------------------------------------------------ #
    def ensure_collection(self, vector_size: int = 768):
        """
        Creates the Qdrant collection if it doesn't exist.
        vector_size=768 matches nomic-embed-text's output dimension —
        change this if you swap embedding models (see ARCHITECTURE.md).
        """
        collections = [c.name for c in self.qdrant_client.get_collections().collections]
        if self.collection_name not in collections:
            logger.info("Creating Qdrant collection: %s", self.collection_name)
            self.qdrant_client.create_collection(
                collection_name=self.collection_name,
                vectors_config=qdrant_models.VectorParams(
                    size=vector_size,
                    distance=qdrant_models.Distance.COSINE,
                ),
            )
        else:
            logger.info("Qdrant collection already exists: %s", self.collection_name)

    # ------------------------------------------------------------------ #
    # Ingestion
    # ------------------------------------------------------------------ #
    def _extract_text(self, filename: str, content: bytes) -> str:
        if filename.lower().endswith(".pdf"):
            reader = PdfReader(io.BytesIO(content))
            return "\n".join(page.extract_text() or "" for page in reader.pages)
        return content.decode("utf-8", errors="ignore")

    def ingest_document(self, filename: str, content: bytes) -> int:
        text = self._extract_text(filename, content)
        if not text.strip():
            raise ValueError(f"No extractable text found in {filename}")

        chunks = self.text_splitter.split_text(text)
        vectorstore = Qdrant(
            client=self.qdrant_client,
            collection_name=self.collection_name,
            embeddings=self.embeddings,
        )
        metadatas = [{"source": filename, "chunk_index": i} for i in range(len(chunks))]
        vectorstore.add_texts(texts=chunks, metadatas=metadatas)
        return len(chunks)

    # ------------------------------------------------------------------ #
    # Query
    # ------------------------------------------------------------------ #
    def query(self, question: str, top_k: int = 4) -> Tuple[str, List[str]]:
        vectorstore = Qdrant(
            client=self.qdrant_client,
            collection_name=self.collection_name,
            embeddings=self.embeddings,
        )
        results = vectorstore.similarity_search(question, k=top_k)

        if not results:
            return (
                "I don't have any ingested documents to answer from yet. "
                "Try /ingest first.",
                [],
            )

        context = "\n\n---\n\n".join(doc.page_content for doc in results)
        sources = sorted({doc.metadata.get("source", "unknown") for doc in results})

        prompt = PROMPT_TEMPLATE.format(context=context, question=question)
        answer = self.llm.invoke(prompt)

        return answer.strip(), sources
