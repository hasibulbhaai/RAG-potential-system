# Security

This document is deliberately explicit about what security controls this POC implements, and — just as importantly — what it does **not**, and why. Being able to articulate this distinction clearly is itself a useful interview signal: it shows you understand the difference between a POC and a production system, rather than either ignoring security entirely or over-engineering a demo.

---

## 1. What This POC Implements

| Control | Implementation | Where |
|---|---|---|
| Software Bill of Materials (SBOM) | Generated via Syft, CycloneDX format | `scripts/05-security-scan.sh` |
| Vulnerability scanning | Trivy, HIGH/CRITICAL severity gate | `scripts/05-security-scan.sh` |
| Image signing | Cosign, keyless (Sigstore) | `scripts/05-security-scan.sh` |
| Non-root container execution | `rag-api` runs as `appuser`, not root | `app/Dockerfile` |
| Minimal base images | `python:3.11-slim`, multi-stage build | `app/Dockerfile` |
| Network segmentation | Ollama (11434) and Qdrant (6333) not exposed to host firewall externally | `scripts/01-provision-vm.sh` |
| Rate limiting | 10 req/s per IP at the Nginx layer | `nginx/nginx.conf` |
| Firewall rules | UFW restricting exposed ports to only what's needed | `scripts/01-provision-vm.sh` |
| No secrets in source | `.env.example` template, actual `.env` gitignored | `.gitignore` |

---

## 2. What Is Explicitly Out of Scope (and Why)

| Missing Control | Why It's Out of Scope for This POC | What Production Would Add |
|---|---|---|
| **Authentication/Authorization** | Adds meaningful complexity (user management, token issuance/validation) that isn't needed to demonstrate the core RAG/platform concepts | API key auth minimum; OAuth2/OIDC for real multi-user access; per-user rate limiting |
| **TLS/HTTPS** | Requires a domain name and cert management (or self-signed certs, which teach bad habits) — deliberately deferred | Let's Encrypt via Certbot, or a managed cert service; TLS termination at Nginx or a load balancer |
| **Secrets management system** | `.env` file is adequate for single-VM POC; a full secrets manager is disproportionate overhead here | HashiCorp Vault, Azure Key Vault, or AWS Secrets Manager, injected at container startup |
| **Input sanitization on `/chat` prompts** | No prompt injection defenses implemented — the LLM response is only ever returned to the same user who submitted it, not executed as code or shown to other users | Prompt injection detection/filtering; output validation if LLM responses ever drive downstream actions |
| **Audit logging** | Basic request logs exist, but no structured, tamper-evident audit trail | Centralized logging (e.g., ELK/Loki) with retention policy, especially important in regulated industries |
| **Penetration testing / formal security review** | Not performed — this is self-assessed, not independently verified | Required before any real production deployment, especially in Financial Services |
| **Data encryption at rest** | Qdrant/Ollama volumes are unencrypted Docker volumes | Encrypted disk volumes at the VM/cloud provider level |
| **DDoS protection beyond basic rate limiting** | Nginx rate limiting is a POC-level mitigation only | CDN/WAF layer (Cloudflare, AWS Shield, Azure Front Door) |

---

## 3. Threat Model Summary (POC Scope)

**In scope:** Supply chain integrity of the container image (what's IN the image, is it vulnerable, is it tamper-evident).

**Explicitly out of scope:** Network-level attacks beyond basic rate limiting, application-layer attacks (prompt injection, auth bypass — since there's no auth to bypass), and physical/VM-level security (assumed to be the cloud provider's or IT's responsibility).

This scoping is intentional — the goal of this POC is to demonstrate **credible working knowledge of a modern software supply chain security pipeline** (SBOM → scan → sign), not to build a hardened production system. If asked "what's your threat model," this table is the honest answer.

---

## 4. Running the Security Pipeline

```bash
./scripts/05-security-scan.sh
```

This produces:
- `security-reports/sbom.json` — full dependency inventory (CycloneDX)
- `security-reports/sbom-summary.txt` — human-readable summary
- `security-reports/vuln-report.json` / `.txt` — Trivy findings, HIGH/CRITICAL only by default

**Interpreting results:** Any CRITICAL finding should be investigated before considering this "demo-ready." HIGH findings are worth reviewing but are common in base images and not automatically blocking for a POC — use judgment on whether the vulnerable component is actually reachable in this application's usage pattern.

---

## 5. Before Using This for Anything Beyond a Local Demo

At minimum, add:
1. Authentication (even basic API key auth)
2. TLS via Let's Encrypt
3. Change all default credentials (Grafana admin password is `admin`/`admin` by default — **change this immediately**, it's called out in `.env.example` for a reason)
4. Restrict SSH access to the VM to known IPs
5. Review the UFW rules in `01-provision-vm.sh` against your actual network requirements
