# Architecture

## 1. System Diagram

```
                                   ┌─────────────────────────────────────────┐
                                   │              Single VM                  │
                                   │                                         │
   ┌────────┐   HTTP :80          │   ┌───────┐        ┌─────────────────┐  │
   │ Client │ ───────────────────►│   │ Nginx │───────►│    RAG API      │  │
   └────────┘                     │   │ :80   │        │  (FastAPI)      │  │
                                   │   └───────┘        │  :8000          │  │
                                   │                     └────┬──────┬────┘  │
                                   │                          │      │       │
                                   │              ┌───────────┘      └────┐  │
                                   │              ▼                       ▼  │
                                   │   ┌─────────────────┐    ┌──────────────┐│
                                   │   │     Ollama      │    │   Qdrant     ││
                                   │   │  (LLM serving)   │    │ (vector DB)  ││
                                   │   │  :11434          │    │  :6333       ││
                                   │   └─────────────────┘    └──────────────┘│
                                   │                                          │
                                   │   ┌──────────────┐    ┌────────────────┐│
                                   │   │  Prometheus   │◄───│  RAG API       ││
                                   │   │  :9090        │    │  /metrics      ││
                                   │   └──────┬────────┘    └────────────────┘│
                                   │          │                               │
                                   │          ▼                               │
                                   │   ┌──────────────┐                       │
                                   │   │   Grafana     │                       │
                                   │   │   :3000       │                       │
                                   │   └──────────────┘                       │
                                   └─────────────────────────────────────────┘
```

**Request flow for a `/chat` call:**
1. Client → Nginx (port 80, rate-limited, timeouts extended for LLM latency)
2. Nginx → RAG API (`/chat` endpoint)
3. RAG API embeds the question (via Ollama's embedding model) and queries Qdrant for the top-k most similar chunks
4. RAG API constructs a prompt (retrieved context + question) and sends it to Ollama's chat model
5. Ollama returns a completion → RAG API returns `{answer, sources, latency_ms}` to the client
6. Every request increments Prometheus counters/histograms, scraped by Prometheus and visualized in Grafana

---

## 2. Key Design Decisions (and Their Trade-offs)

### 2.1 Docker Compose vs. Kubernetes
**Decision:** Docker Compose on a single VM.

**Why:** This is a POC meant to be stood up quickly and reasoned about end-to-end by one person. Kubernetes adds real value at multi-node scale, multi-tenancy, and auto-scaling — none of which apply to a single-VM POC. Introducing K8s here would add operational complexity without a corresponding benefit.

**What changes if this goes to Kubernetes next:**
- Ollama would likely move to a GPU-backed node pool with a `Deployment` + `HorizontalPodAutoscaler`, or be replaced with vLLM for higher-throughput serving
- Qdrant would run as a `StatefulSet` with persistent volume claims
- Nginx would become an Ingress controller (or the cluster's existing ingress)
- Prometheus/Grafana would likely be replaced by the cluster's existing observability stack (e.g., via the kube-prometheus-stack Helm chart)
- This is a natural "here's how I'd scale this" answer in an interview — the POC intentionally stays simple so that story is easy to tell clearly.

### 2.2 Ollama vs. vLLM for LLM Serving
**Decision:** Ollama.

**Why:** Ollama has close to zero operational overhead — pull a model, run it, done. It runs acceptably on CPU-only hardware, which matches the "single VM, no GPU required" goal of this POC.

**Trade-off:** Ollama's throughput under concurrent load is meaningfully lower than vLLM's, which uses continuous batching and PagedAttention for much higher requests/sec on the same hardware (assuming a GPU). **vLLM is the right choice once you have real concurrent traffic and GPU access** — this is a good, honest answer if asked "why not vLLM?" in an interview.

### 2.3 Qdrant vs. Weaviate vs. Milvus
**Decision:** Qdrant.

**Why:** Smallest resource footprint of the three for a single-VM POC, simple REST/gRPC API, official LangChain integration is mature. Weaviate offers more built-in features (hybrid search, modules) but at a higher resource cost; Milvus is built for much larger-scale deployments (billions of vectors) and is arguably over-engineered for a POC.

### 2.4 Synchronous Ingestion (No Task Queue)
**Decision:** `/ingest` processes documents synchronously within the request.

**Why:** Simplicity for a POC — no need to stand up Redis/Celery/RQ just to demonstrate the concept.

**Trade-off:** Large documents (100+ page PDFs) will make the ingest request slow and could time out. **In production, this would move to an async task queue** with a job-status endpoint (`POST /ingest` returns a job ID immediately, `GET /ingest/{id}/status` polls for completion). This is a documented, deliberate simplification — not an oversight — and worth stating as such if asked.

### 2.5 No Re-ranking Step
**Decision:** Plain top-k cosine similarity search, no re-ranking.

**Why:** Keeps the retrieval pipeline simple and fast to build for a POC.

**Trade-off:** Re-ranking (e.g., with a cross-encoder model) generally improves retrieval precision meaningfully, especially as the document corpus grows. This is a well-known "next step" in RAG systems and a good thing to flag proactively in an interview — it signals you know the difference between a POC and a production-grade RAG pipeline.

### 2.6 No Authentication
**Decision:** No auth on any endpoint in this POC.

**Why:** Out of scope for demonstrating the core RAG/platform/security concepts; see `SECURITY.md` for the explicit list of what's deliberately excluded and why, plus what a production version would add (API keys at minimum, OAuth2/OIDC for a real multi-user system).

---

## 3. Scaling Considerations (Beyond This POC)

| Concern | This POC | Production Path |
|---|---|---|
| LLM throughput | Ollama, CPU-only, single instance | vLLM on GPU nodes, horizontally scaled |
| Vector DB scale | Single Qdrant instance | Qdrant cluster mode, or managed offering |
| Ingestion | Synchronous, in-request | Async task queue (Celery/RQ) with status polling |
| High availability | None — single VM, single point of failure | Multi-node deployment, load balancing, health-based failover |
| Secrets management | `.env` file | Vault, cloud-native secrets manager (Azure Key Vault, AWS Secrets Manager) |
| Multi-tenancy | None | Namespace/collection-per-tenant in Qdrant, API-key-scoped access |

---

## 4. Data Flow: Embedding Dimension Consistency

The Qdrant collection is created with `vector_size=768`, matching `nomic-embed-text`'s output dimension. **If you swap embedding models, you must update this value and recreate the collection** — mismatched vector dimensions will cause insert/query failures, not silent errors. This is called out explicitly in `rag_chain.py`'s `ensure_collection()` docstring and is a common real-world gotcha worth mentioning if asked about operational pitfalls.
