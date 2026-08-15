# How to Present This Project in Interviews

## The 30-Second Summary
"I built a self-hosted RAG platform to get hands-on with the AI infrastructure layer — deployed Ollama for LLM serving and Qdrant for vector search, wrapped in a FastAPI/LangChain orchestration layer, all deployed through the same GitOps-style approach I've used for years. I also added a supply chain security pipeline — SBOM generation, vulnerability scanning, and image signing — because that's a real gap in a lot of AI deployments I've seen, and observability with Prometheus/Grafana so it's not a black box in production."

## Likely Follow-Up Questions and How to Answer Honestly

**"Why self-hosted instead of using OpenAI's API?"**
Because I wanted to understand the operational reality of running LLM infrastructure myself — model serving, resource sizing, latency trade-offs — not just calling an API. That said, I also worked with Azure OpenAI Service separately, and I'd choose managed vs. self-hosted based on the actual constraint: data residency and cost control push toward self-hosted; speed to market and not owning GPU capacity pushes toward managed.

**"Why Ollama and not vLLM?"**
Ollama has near-zero operational overhead and runs fine on CPU-only hardware, which matched my POC constraints (single VM, no GPU). vLLM is the right answer once you have real concurrent load and GPU access — it uses continuous batching for much higher throughput. I documented this trade-off explicitly rather than pretending Ollama is production-grade at scale.

**"What would you change to make this production-ready?"**
Straight from `SECURITY.md`: authentication, TLS, a real secrets manager, and a formal security review. From `ARCHITECTURE.md`: move ingestion to an async task queue, add a re-ranking step to retrieval, and likely move to Kubernetes with vLLM on GPU nodes if traffic justified it. I can list these because I documented them deliberately as out-of-scope, not because I didn't think about them.

**"How did you handle [X failure scenario]?"**
Point to `RUNBOOK.md` — walk through one scenario you actually hit while building this (dimension mismatch errors are a good one; they're a real, non-obvious gotcha).

**"What was the hardest part?"**
Be honest about something specific — e.g., getting Nginx timeouts right for LLM latency (default timeouts are way too short), or getting the embedding dimension right when the collection didn't match. Specific, technical answers land better than vague ones.

**"Have you done this on Kubernetes?"**
If not: "Not yet on this project — I deliberately kept this on Docker Compose for a single-VM POC, but I documented exactly what changes if we move it to Kubernetes: Ollama/vLLM as a GPU-backed Deployment, Qdrant as a StatefulSet, Nginx becomes an Ingress. That's a natural next iteration." This is a strong answer — it shows you know the difference and made a deliberate choice, not that you're avoiding K8s because you don't know it.

## What NOT to Do
- Don't claim this is "production-grade" — the security doc explicitly lists what's missing. Own that honestly; it reads as more senior, not less.
- Don't oversell the AI/ML depth — this demonstrates infrastructure and platform engineering competence around AI, not ML research or model training expertise. Be precise about what you're claiming.
- Don't memorize a script — know the project well enough to improvise if asked to whiteboard part of the architecture live.
