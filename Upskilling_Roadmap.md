# Technology Leadership Upskilling Roadmap
### A 9-Month Plan to Build AI Infrastructure, Platform Engineering, Security, and Executive Skills

---

## How to Use This Roadmap

This is a **phased, project-driven plan** — not a list of courses to passively consume. Each phase pairs learning resources with a **hands-on open-source project** you can point to in interviews or add to your resume as a case study. Work through phases in order, or run Phase 1 and Phase 4 in parallel since one is technical and one is a soft-skill track.

**Time commitment:** ~5-8 hours/week gets you through this in 9 months. Compress to 5-6 months if you can dedicate 10+ hours/week.

---

## Phase 1 (Months 1-3): AI/GenAI Infrastructure Fluency

**Goal:** Be able to design, deploy, and speak credibly about LLM-powered systems on infrastructure you already know (Kubernetes, cloud).

### Learn
| Resource | Type | Why |
|---|---|---|
| [DeepLearning.AI short courses](https://www.deeplearning.ai/short-courses/) | Free courses | "LangChain for LLM App Development", "Building RAG Apps", "LLMOps" — all 1-2 hours each, built by Andrew Ng's team |
| [Kubeflow docs](https://www.kubeflow.org/docs/) | Documentation | The standard for ML/AI workloads on Kubernetes — directly extends your K8s expertise |
| [vLLM documentation](https://docs.vllm.ai/) | Documentation | Industry-standard for serving LLMs efficiently at scale |
| [Full Stack Deep Learning](https://fullstackdeeplearning.com/) | Free course | Covers LLMOps, deployment, and production ML systems from an engineering (not data science) lens |

### Build (Open Source Projects to Fork/Deploy)
- **[Ollama](https://github.com/ollama/ollama)** — Deploy and run open-source LLMs (Llama, Mistral) locally or on your Kubernetes cluster. Start here; it's the easiest on-ramp.
- **[vLLM](https://github.com/vllm-project/vllm)** — Once comfortable with Ollama, deploy vLLM on Kubernetes for production-grade inference serving. This is what real companies use.
- **[LangChain](https://github.com/langchain-ai/langchain)** or **[LlamaIndex](https://github.com/run-llama/llama_index)** — Build a RAG (Retrieval-Augmented Generation) pipeline. Pick one, not both.
- **[Weaviate](https://github.com/weaviate/weaviate)** or **[Qdrant](https://github.com/qdrant/qdrant)** — Deploy a vector database (Docker/Kubernetes) to pair with your RAG pipeline.
- **[MLflow](https://github.com/mlflow/mlflow)** — Learn experiment tracking and model lifecycle management; this is the "DevOps of ML" and maps directly onto your existing CI/CD mental model.

### 🎯 Portfolio Project
Deploy a **self-hosted RAG chatbot on Kubernetes**: Ollama (or vLLM) + Weaviate + LangChain, containerized, deployed via your existing GitOps pipeline (ArgoCD), with Prometheus/Grafana observability on top. This single project demonstrates AI infra + your existing platform skills in one artifact — an excellent portfolio piece and resume bullet.

---

## Phase 2 (Months 2-5): Platform Engineering & Internal Developer Platforms

**Goal:** Move from "cloud/K8s operator" to "platform-as-product" leader — the framing that gets Director-level interviews.

### Learn
| Resource | Type | Why |
|---|---|---|
| [Backstage.io docs](https://backstage.io/docs/overview/what-is-backstage) | Documentation | Spotify's open-source IDP framework — the de facto standard |
| [CNCF Platform Engineering whitepaper](https://tag-app-delivery.cncf.io/whitepapers/platform-engineering/) | Whitepaper | Free, defines the vocabulary hiring managers now expect |
| [Team Topologies](https://teamtopologies.com/) (book) | Book | The foundational text for "platform as a product" thinking — widely referenced in Director/VP interviews |
| [FinOps Foundation free training](https://www.finops.org/introduction/) | Free course | Intro-level, leads into the paid certification |

### Build (Open Source Projects to Fork/Deploy)
- **[Backstage](https://github.com/backstage/backstage)** — Stand up your own instance, add a service catalog for a sample microservices app, integrate with GitHub/GitLab. This is the single highest-value project on this list for platform engineering credibility.
- **[Crossplane](https://github.com/crossplane/crossplane)** — Extend your IaC skills into "infrastructure as an API" — increasingly the standard for platform teams offering self-service infra to developers.
- **[OpenCost](https://github.com/opencost/opencost)** (CNCF project) — Deploy this for real-time Kubernetes cost visibility; pairs directly with your FinOps learning and gives you a concrete cost-optimization story to tell.
- **[Kyverno](https://github.com/kyverno/kyverno)** — Policy-as-code for Kubernetes; strengthens your governance/guardrails narrative for platform teams.

### 🎯 Portfolio Project
Build a **"Golden Path" developer platform**: Backstage service catalog + Crossplane self-service infrastructure templates + OpenCost dashboards, all documented as if onboarding a new engineering team. Frame this as: *"Reduced time-to-first-deploy for new services from X days to Y hours."*

### Certification Target
**FinOps Certified Practitioner** (~$500, self-paced exam) — high recognition, directly relevant, relatively fast to obtain after the free training above.

---

## Phase 3 (Months 4-7): Security & Compliance Depth

**Goal:** Extend your existing Zero Trust/DevSecOps foundation into supply chain security and cloud security posture management — increasingly non-negotiable in regulated industries.

### Learn
| Resource | Type | Why |
|---|---|---|
| [SLSA framework docs](https://slsa.dev/) | Documentation | The emerging standard for software supply chain integrity |
| [Sigstore docs](https://docs.sigstore.dev/) | Documentation | How modern artifact signing/verification works |
| [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/) | Free guide | Structured, practical, maps well to what you already know |
| [CNCF Security courses (Linux Foundation)](https://training.linuxfoundation.org/) | Paid courses | "Kubernetes Security Essentials" (LFS260) — builds toward CKS if you don't already hold it (you do — consider skipping) |

### Build (Open Source Projects to Fork/Deploy)
- **[Syft](https://github.com/anchore/syft)** + **[Grype](https://github.com/anchore/grype)** — Generate SBOMs (Software Bill of Materials) and scan for vulnerabilities in your existing container images. Quick to integrate into a CI pipeline.
- **[Cosign](https://github.com/sigstore/cosign)** (part of Sigstore) — Add artifact/image signing and verification to your GitLab/ArgoCD pipeline.
- **[Trivy](https://github.com/aquasecurity/trivy)** — All-in-one scanner (containers, IaC, SBOM); integrate into your existing DevSecOps pipeline if you haven't already.
- **[OPA / Gatekeeper](https://github.com/open-policy-agent/opa)** — Policy-as-code for admission control in Kubernetes; strong pairing with Kyverno from Phase 2 (pick whichever your target companies tend to use — OPA has broader adoption, Kyverno is more K8s-native and simpler).

### 🎯 Portfolio Project
Add a **secure software supply chain** layer to your Phase 1 or Phase 2 project: SBOM generation (Syft) → vulnerability scan (Grype/Trivy) → image signing (Cosign) → policy enforcement at deploy time (OPA/Kyverno), all wired into your GitOps pipeline. This gives you an end-to-end "SLSA-aligned pipeline" story — a strong, differentiated interview talking point.

---

## Phase 4 (Ongoing, Months 1-9 in parallel): Executive & Business Leadership Skills

**Goal:** Build the business fluency that separates Director/VP candidates from strong ICs. This track runs in parallel with the technical phases above.

### Learn
| Resource | Type | Why |
|---|---|---|
| [Coursera: "Technology Strategy" or "Digital Transformation" specializations](https://www.coursera.org/) | Paid courses (often $49/mo, cancel after) | Structured, credential-bearing, business-school-adjacent content |
| ["The First 90 Days" by Michael Watkins](https://www.amazon.com) | Book | Standard reading for stepping into senior leadership transitions |
| [Prosci Change Management Certification](https://www.prosci.com/) | Paid certification | The most recognized change management credential; valuable if targeting transformation-heavy roles |
| Internal: shadow or request time with your organization's Finance/Product leaders | Free (internal networking) | Nothing replaces real exposure to how budget and roadmap decisions get made |

### Practice (No Open Source Here — This Is Reps, Not Repos)
- **Rewrite 3 of your technical achievement bullets in business terms.** E.g., "Deployed Kubernetes cluster" → "Reduced infrastructure costs by $X and cut deployment time by Y%, enabling the business to ship features Z% faster."
- **Volunteer to present a technical initiative to non-technical stakeholders** at your current company — this is the single fastest way to build this muscle.
- **Draft one internal business case** (even informally) proposing a platform investment, including rough cost/benefit — practice thinking like the person who has to approve your budget.

### 🎯 Portfolio Project
Write a **one-page "platform strategy" document** — as if pitching your Phase 2 IDP project to a CFO — covering cost, risk reduction, and developer productivity ROI. This document itself becomes an interview artifact ("Walk me through how you'd pitch this to leadership").

---

## Suggested Timeline at a Glance

| Month | Focus |
|---|---|
| 1-2 | Phase 1 (AI infra) + start Phase 4 (leadership reading) |
| 2-3 | Finish Phase 1 portfolio project; start Phase 2 (Backstage) |
| 4-5 | Finish Phase 2; FinOps certification; start Phase 3 |
| 5-6 | Continue Phase 3; begin business case writing (Phase 4) |
| 6-7 | Finish Phase 3 portfolio project (secure pipeline) |
| 7-9 | Consolidate all four portfolio projects into resume bullets, LinkedIn posts, and interview stories; pursue Prosci cert if targeting transformation-heavy roles |

---

## A Note on Prioritization

If you have to cut this down, keep in this order:
1. **Phase 1 portfolio project** (RAG chatbot on K8s) — highest market demand, fastest to build credibility
2. **Phase 2's Backstage project** — most directly maps to Director-level platform engineering roles
3. **Phase 4's business-case writing practice** — costs no money, highest leverage for landing Director/VP interviews
4. Phase 3 — valuable but the least differentiating if your target roles are less security-focused

---

*A note on sourcing: the projects and resources above are real, actively maintained open-source tools and public resources as of my knowledge — but check current GitHub activity, star counts, and course availability before committing, since the landscape moves fast and I can't verify real-time status.*
