# 12-Week Intensive Upskilling Sprint
### Goal: Interview-Ready with One Flagship Project, a Rewritten Narrative, and Active Pipeline — Not Deep Mastery

---

## Reality Check Before You Start

**What 1-3 months CAN get you:**
- One polished, demoable, end-to-end project you can screen-share in interviews
- Working fluency (not expertise) in managed AI services + one platform engineering concept
- A resume/LinkedIn narrative that reads as forward-looking, not dated
- An active network and interview pipeline

**What it CANNOT get you:**
- Deep AI/ML engineering expertise (that's 1-2 years)
- Genuine platform engineering mastery at scale
- A stack of new certifications (most take 4-8 weeks each to prep properly — pick ONE, not four)

**Time commitment assumed:** 20-25 hrs/week. If you're doing this while working full-time, that's early mornings + evenings + weekends. If you're between roles, treat this like a full-time job. **Either way, something in your current life has to give for 12 weeks. Say that out loud to whoever you live with now.**

---

## Week-by-Week Plan

### 🔥 Weeks 1-2: Foundation Sprint
**Time: ~22 hrs/week**

| Task | Hours | Resource |
|---|---|---|
| Rewrite resume + LinkedIn in business-outcome language | 4 hrs | Use your existing resume as base; reframe every bullet as $ / % / time saved |
| Stand up Azure OpenAI Service (or AWS Bedrock) — deploy a model endpoint, call it via API | 6 hrs | [Azure OpenAI quickstart](https://learn.microsoft.com/azure/ai-services/openai/quickstart) |
| Deploy Ollama locally, run a model, understand the self-hosted vs. managed trade-off cold | 4 hrs | [Ollama GitHub](https://github.com/ollama/ollama) |
| Identify 15 target companies + 10 people currently in your target role to reach out to | 3 hrs | LinkedIn Sales Navigator or free search |
| Send first 5 networking messages (not asking for a job — asking for 20 min of their time) | 2 hrs | — |
| Read: 2-3 job postings/day for your target title, log recurring keywords | 3 hrs | LinkedIn, company career pages |

**Deliverable by end of Week 2:** Updated resume draft, 5 networking conversations scheduled, both a managed and self-hosted LLM running.

---

### 🔥 Weeks 3-5: Flagship Project Build (AI + Platform, Combined)
**Time: ~25 hrs/week — this is the core of the sprint**

Build ONE project that demonstrates AI infra + your existing platform/DevOps strength together. Don't split into four separate projects — one deep, well-documented project beats four shallow ones in an interview.

**The project: "Self-Service RAG Assistant Platform"**
A RAG chatbot, deployed via your existing GitOps pipeline, with a lightweight developer self-service layer on top.

| Component | Tool | Time |
|---|---|---|
| LLM serving | Azure OpenAI Service (managed) **+** Ollama fallback (self-hosted) — build both so you can speak to either | 4 hrs |
| Vector DB | [Qdrant](https://github.com/qdrant/qdrant) (fastest to deploy) | 3 hrs |
| RAG orchestration | [LangChain](https://github.com/langchain-ai/langchain) — keep it simple, one working pipeline | 5 hrs |
| Deployment | Containerize, deploy via your existing K8s + GitOps (ArgoCD) skillset — this is where YOUR expertise shows, not the AI part | 6 hrs |
| Self-service layer | [Backstage](https://github.com/backstage/backstage) — add ONE service catalog entry for this project, don't build a full IDP | 5 hrs |
| Observability | Prometheus/Grafana dashboard for the RAG app (latency, token usage) | 3 hrs |
| Documentation | Architecture diagram + README written as if onboarding a new engineer | 3 hrs |

**Deliverable by end of Week 5:** A working, demoable, documented project on your GitHub. This is your single most important artifact for the next 12 weeks.

**⚠️ Reality check:** This is genuinely tight. If you fall behind, cut the Backstage layer first — the RAG-on-K8s pipeline alone is enough to be credible. Don't sacrifice depth on the core pipeline to hit the timeline.

---

### 🔥 Weeks 6-7: Security Layer + Business Case
**Time: ~20 hrs/week**

Bolt a lightweight security story onto the same project — don't start a new one.

| Task | Hours | Resource |
|---|---|---|
| Add SBOM generation to your project's pipeline | 2 hrs | [Syft](https://github.com/anchore/syft) |
| Add vulnerability scanning | 2 hrs | [Trivy](https://github.com/aquasecurity/trivy) |
| Add image signing | 3 hrs | [Cosign](https://github.com/sigstore/cosign) |
| Write a one-page "platform strategy" business case pitching this project to a CFO (cost, risk, productivity ROI) | 4 hrs | Your own writing — this becomes an interview story |
| Continue networking: 3-5 more conversations | 4 hrs | — |
| Start applying to 5-10 roles/week | 5 hrs | — |

**Deliverable by end of Week 7:** Full pipeline (RAG + security scanning + signing), a written business case, applications actively going out.

---

### 🔥 Weeks 8-9: Visibility Sprint
**Time: ~18 hrs/week**

Skills without visibility convert less efficiently. This is where you make the work findable.

| Task | Hours | Resource |
|---|---|---|
| Write a LinkedIn article/post walking through your flagship project (architecture + why decisions were made) | 5 hrs | — |
| Clean up GitHub profile — pin the project, write a strong README, add architecture diagram | 3 hrs | — |
| Post 2-3 more times about the security layer, the business case, lessons learned | 3 hrs | — |
| Continue networking: aim for 2-3 conversations/week | 4 hrs | — |
| Continue applying: 5-10 roles/week, tailor resume per role using job posting keywords from Week 1-2 | 5 hrs | — |

**Deliverable by end of Week 9:** Public visibility on LinkedIn + GitHub, steady application flow, growing network.

---

### 🔥 Weeks 10-12: Interview Prep + Close
**Time: ~20 hrs/week**

| Task | Hours | Resource |
|---|---|---|
| Prep 5-6 STAR-format stories from your career (include your new project as one) | 5 hrs | — |
| Do 3-5 mock interviews (peers, a coach, or practice out loud) — technical AND behavioral | 6 hrs | — |
| Prepare a whiteboard-able architecture walkthrough of your flagship project | 3 hrs | — |
| Keep networking + applying — this doesn't stop just because interviews start | 4 hrs | — |
| Negotiation prep: know your numbers before an offer arrives | 2 hrs | — |

**Deliverable by end of Week 12:** Active interview pipeline, polished stories, a demoable project, and (realistically) offers in progress or close.

---

## What Got Cut From the Original Plan (On Purpose)

To make this fit 12 weeks, I deliberately dropped or shrank:
- ❌ FinOps certification (takes 4-8 weeks alone to prep properly — do this *after* landing, not before)
- ❌ Prosci change management cert (same reason)
- ❌ Deep Kubeflow/MLOps pipeline work (nice-to-have, not interview-critical for most roles)
- ❌ Full IDP build-out (one Backstage catalog entry is enough to speak to the concept)
- ❌ CKS/advanced K8s security certs (you already hold strong certs — new ones have low marginal value right now)

If a specific target job posting asks for one of these explicitly, swap it back in — but don't add without cutting something else. The whole point of this plan is ruthless focus.

---

## Weekly Accountability Checklist

Copy this into a note and check off weekly:

```
Week 1:  [ ] Resume rewritten  [ ] Azure OpenAI running  [ ] 5 networking msgs sent
Week 2:  [ ] Ollama running    [ ] Target list built     [ ] Job posting keywords logged
Week 3:  [ ] LLM serving live  [ ] Vector DB deployed
Week 4:  [ ] RAG pipeline works [ ] Deployed via GitOps
Week 5:  [ ] Backstage entry   [ ] Observability dashboard [ ] README written
Week 6:  [ ] SBOM + scanning added [ ] Business case drafted
Week 7:  [ ] Signing added     [ ] Applications started (5-10/wk)
Week 8:  [ ] LinkedIn post #1  [ ] GitHub cleaned up
Week 9:  [ ] LinkedIn post #2-3 [ ] Networking steady
Week 10: [ ] STAR stories ready [ ] Mock interview #1
Week 11: [ ] Mock interviews #2-3 [ ] Architecture walkthrough prepped
Week 12: [ ] Negotiation prep  [ ] Pipeline active
```

---

## If You Have to Choose: The Absolute Minimum Viable Version

If life happens and you can't do all 12 weeks fully, protect these in order:
1. **The flagship project (Weeks 3-5)** — non-negotiable, this is your proof
2. **Resume/LinkedIn rewrite (Week 1)** — costs almost nothing, high leverage
3. **Networking (ongoing)** — highest ROI activity in this entire plan, don't let it slide
4. **Applications (Week 7+)** — start these even if the project isn't 100% done; a 70%-finished demoable project is enough

Everything else (security layer, visibility posts, business case) is valuable but secondary to these four.
