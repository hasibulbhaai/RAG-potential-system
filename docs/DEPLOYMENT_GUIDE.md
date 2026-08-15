# Deployment Guide — Step by Step

A fully walked-through deployment, written for someone doing this for the first time.

---

## Step 0: Provision a VM

Any of these work — pick based on what you already have access to or want experience with:

| Provider | Suggested Instance Type | Approx. Cost |
|---|---|---|
| AWS | `t3.xlarge` (4 vCPU, 16GB) or `m5.2xlarge` for more headroom | ~$0.15-0.35/hr |
| Azure | `Standard_D4s_v5` | ~$0.15-0.20/hr |
| GCP | `e2-standard-4` | ~$0.13-0.15/hr |
| Local/Homelab | Any Ubuntu 22.04 VM with 16GB+ RAM | Free |

**Important:** Shut the VM down when not actively demoing/testing if using a paid cloud provider — this stack idles fine but there's no reason to pay for 24/7 uptime on a POC. Note costs and pricing may have changed since this guide was written — confirm current rates with your provider before provisioning.

SSH into the VM once it's running:
```bash
ssh ubuntu@<vm-ip>
```

---

## Step 1: Get the Code Onto the VM

```bash
# If using git:
git clone <your-repo-url> rag-platform-poc
cd rag-platform-poc

# Or, if working from a local zip:
# scp the zip to the VM, then:
unzip rag-platform-poc.zip
cd rag-platform-poc
```

---

## Step 2: Provision the VM Environment

```bash
chmod +x scripts/*.sh
./scripts/01-provision-vm.sh
```

**What to expect:** This installs Docker, configures the firewall, and installs supporting tools. Takes 3-5 minutes. If this is the VM's first Docker install, **you'll need to log out and back in** (or run `newgrp docker`) before continuing, so your user picks up docker group permissions.

---

## Step 3: Configure Environment Variables

```bash
cp .env.example .env
nano .env   # or vim, whatever you prefer
```

At minimum, change `GRAFANA_ADMIN_PASSWORD` from the default. Review `MODEL_NAME` — the default (`llama3.1:8b`) is a good balance of quality and CPU-friendliness, but if your VM is on the smaller end, consider `phi3:mini` instead (faster, lower quality).

---

## Step 4: Deploy the Stack

```bash
./scripts/02-deploy.sh
```

**What to expect:** Docker builds the `rag-api` image (1-2 minutes first time), then starts all six containers. The script waits up to 90 seconds for health checks to pass. You'll see a service status table at the end.

**If something looks unhealthy:** Check `docker compose ps` and `docker compose logs <service>` — see `RUNBOOK.md` for common issues.

---

## Step 5: Pull the LLM Model

```bash
./scripts/03-pull-model.sh
```

**What to expect:** This downloads the model (4-8GB depending on choice) — can take 5-15 minutes on a typical connection. Grab a coffee. The script also pulls the embedding model and runs a warm-up query.

---

## Step 6: Ingest Sample Documents

```bash
./scripts/04-ingest-docs.sh
```

**What to expect:** If `./data/documents` is empty, this creates a sample document about platform engineering so you have something to query immediately. To ingest your own documents, drop `.txt`, `.md`, or `.pdf` files into `./data/documents/` first, then re-run this script.

---

## Step 7: Verify Everything Works

```bash
./scripts/06-health-check.sh
```

**What to expect:** A full smoke test — container status, each service's health endpoint, and an actual end-to-end `/chat` query. All checks should show ✓. If anything shows ✗, the script points you to `RUNBOOK.md`.

---

## Step 8: Try It Yourself

```bash
# Ask a question about the ingested sample doc
curl -s -X POST http://localhost/chat \
  -H "Content-Type: application/json" \
  -d '{"question": "What is a golden path in platform engineering?"}' | jq .

# Or open the interactive API docs in a browser
# http://<vm-ip>/docs
```

Open Grafana at `http://<vm-ip>:3000` (login with the credentials you set in `.env`) to watch metrics populate as you send requests.

---

## Step 9: Run the Security Pipeline

```bash
./scripts/05-security-scan.sh
```

**What to expect:** Installs Syft/Trivy/Cosign if not present, generates an SBOM, scans for vulnerabilities, and explains the image signing flow (which requires a container registry to complete meaningfully — see `SECURITY.md` for details).

---

## Step 10: Explore, Break Things, Learn

At this point you have a fully working system. Good next experiments:
- Ingest your own real documents and see retrieval quality firsthand
- Try a different model size (`./scripts/03-pull-model.sh phi3:mini`) and compare latency/quality trade-offs
- Watch the Grafana dashboard while running a few dozen `/chat` requests in a loop to see latency percentiles move
- Deliberately break something (stop the Qdrant container mid-query) and use `RUNBOOK.md` to diagnose and recover — this kind of hands-on failure recovery is exactly the kind of story that lands well in interviews

---

## Tearing Down

```bash
./scripts/07-teardown.sh          # stop, keep data/models for next time
./scripts/07-teardown.sh --full   # stop and wipe everything
```
