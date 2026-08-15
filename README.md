# Self-Hosted RAG Assistant Platform — POC

A production-shaped, fully self-hosted Retrieval-Augmented Generation (RAG) platform deployed on a single VM. Built as a portfolio/POC project demonstrating AI infrastructure, platform engineering, and DevSecOps skills together — not a toy demo, but a real reference architecture you can defend in a technical deep-dive.

**Stack:** Ollama (LLM serving) → Qdrant (vector DB) → FastAPI + LangChain (RAG orchestration) → Nginx (reverse proxy) → Prometheus + Grafana (observability) → Syft/Trivy/Cosign (supply chain security)

---

## 1. What This Demonstrates

| Skill Area | How This Project Shows It |
|---|---|
| AI Infrastructure | Self-hosted LLM serving (Ollama), vector search (Qdrant), RAG pipeline design |
| Platform Engineering | Containerized, reproducible deployment; single-command spin-up; documented golden path |
| DevSecOps | SBOM generation, vulnerability scanning, image signing, all wired into the deploy flow |
| Observability | Metrics (Prometheus), dashboards (Grafana), structured logging |
| Documentation Discipline | Architecture decisions, runbooks, and troubleshooting guides — the things that separate a POC from production-shaped work |

---

## 2. Repository Layout

```
rag-platform-poc/
├── README.md                    # This file — start here
├── docker-compose.yml           # Full stack orchestration
├── .env.example                 # Environment variable template
├── app/                         # RAG API service
│   ├── main.py                  # FastAPI app: /health, /ingest, /chat
│   ├── ingest.py                # Document ingestion logic
│   ├── rag_chain.py             # LangChain RAG pipeline construction
│   ├── metrics.py               # Prometheus instrumentation
│   ├── requirements.txt
│   └── Dockerfile
├── nginx/
│   └── nginx.conf               # Reverse proxy + basic rate limiting
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       ├── datasource.yml
│       └── dashboard.json       # Pre-built RAG platform dashboard
├── scripts/
│   ├── 01-provision-vm.sh       # Fresh VM setup (Docker, deps, firewall)
│   ├── 02-deploy.sh             # Build + deploy the full stack
│   ├── 03-pull-model.sh         # Pull and warm the Ollama model
│   ├── 04-ingest-docs.sh        # Sample document ingestion
│   ├── 05-security-scan.sh      # SBOM + vuln scan + image signing
│   ├── 06-health-check.sh       # Post-deploy smoke tests
│   └── 07-teardown.sh           # Clean shutdown / resource reclaim
├── docs/
│   ├── ARCHITECTURE.md          # System design, diagrams, decisions
│   ├── RUNBOOK.md               # Operational procedures
│   ├── SECURITY.md              # Threat model + supply chain controls
│   ├── DEPLOYMENT_GUIDE.md      # Step-by-step VM deployment walkthrough
│   └── INTERVIEW_TALKING_POINTS.md  # How to present this project
└── .github/workflows/
    └── ci-security.yml          # Reference CI pipeline (SBOM/scan on push)
```

---

## 3. Quick Start (TL;DR)

```bash
# On a fresh Ubuntu 22.04 VM with at least 16GB RAM, 4 vCPUs, 100GB disk
git clone <your-repo-url> rag-platform-poc && cd rag-platform-poc
cp .env.example .env                       # edit values as needed
chmod +x scripts/*.sh
./scripts/01-provision-vm.sh               # installs Docker, firewall rules, deps
./scripts/02-deploy.sh                     # builds and starts the full stack
./scripts/03-pull-model.sh                 # pulls the LLM into Ollama
./scripts/04-ingest-docs.sh                # loads sample docs into Qdrant
./scripts/06-health-check.sh               # verifies everything is up
```

Then open:
- **Chat API docs:** `http://<vm-ip>/docs` (FastAPI Swagger UI)
- **Grafana:** `http://<vm-ip>:3000` (default admin/admin — **change immediately**, see SECURITY.md)
- **Prometheus:** `http://<vm-ip>:9090`

Full walkthrough with explanations: see [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md).

---

## 4. Minimum VM Sizing

| Resource | Minimum | Recommended |
|---|---|---|
| vCPUs | 4 | 8 |
| RAM | 16 GB | 32 GB |
| Disk | 100 GB SSD | 200 GB SSD |
| GPU | None (CPU inference works, slower) | Optional NVIDIA GPU for faster inference |
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |

**Note on model size:** This POC defaults to a smaller open model (`llama3.1:8b` or `mistral:7b`) specifically so it runs on CPU-only VMs within these specs. See `docs/ARCHITECTURE.md` for guidance on scaling up if you have GPU access.

---

## 5. Why These Design Choices

- **Docker Compose, not Kubernetes** — deliberate. This is a single-VM POC; Compose keeps it reproducible and simple to reason about. `docs/ARCHITECTURE.md` includes notes on what changes if you port this to Kubernetes later (which is a natural "next step" story for an interview).
- **Ollama over vLLM for this POC** — Ollama has a far lower operational bar for a single-VM CPU-friendly deployment. `docs/ARCHITECTURE.md` documents the trade-off and when you'd choose vLLM instead (higher-throughput, GPU-backed, production-scale serving).
- **Qdrant over Weaviate/Milvus** — smallest resource footprint of the mainstream open-source vector DBs, fastest to stand up for a POC.

---

## 6. Status & Honest Scope Note

This is a **POC / reference architecture**, not a hardened production system. It includes real security tooling (SBOM, scanning, signing) so you can speak credibly to supply chain security, but it has **not** been through a formal security review, load testing, or HA design. `docs/SECURITY.md` is explicit about what's in scope and what's deliberately out of scope for a POC, which is itself a useful thing to be able to articulate in an interview.
