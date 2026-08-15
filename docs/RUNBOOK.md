# Operational Runbook

Common operational scenarios and how to handle them. Written as if handing this project to another engineer.

---

## Starting / Stopping the Stack

```bash
# Start everything
./scripts/02-deploy.sh

# Stop everything (preserves data/models)
./scripts/07-teardown.sh

# Stop and wipe all data (fresh start)
./scripts/07-teardown.sh --full

# Restart a single service
docker compose restart rag-api

# View logs for a service
docker compose logs -f rag-api
docker compose logs -f ollama --tail 100
```

---

## Scenario: `/chat` requests are timing out

**Likely causes, in order of likelihood:**

1. **Model not pulled yet.** Check with:
   ```bash
   docker compose exec ollama ollama list
   ```
   If empty, run `./scripts/03-pull-model.sh`.

2. **First request after startup is always slow** (cold model load into memory). Subsequent requests should be faster. If every request is slow, see #3.

3. **VM is CPU-only and under-provisioned.** Check resource usage:
   ```bash
   docker stats
   ```
   If `ollama` is pegged at 100% CPU and requests take 60s+, the VM likely doesn't meet the minimum spec in the README. Options: upgrade VM size, switch to a smaller model (e.g., `phi3:mini` instead of `llama3.1:8b`), or add GPU support.

4. **Nginx timeout too low.** Already set to 120s in `nginx/nginx.conf` — if you need longer, increase `proxy_read_timeout`.

---

## Scenario: `/ingest` fails or returns empty chunks

1. **Check the file actually has extractable text.** Scanned PDFs (images of text, no OCR layer) will extract empty strings — this is a known limitation; `_extract_text()` in `rag_chain.py` does not include OCR.
2. **Check file size.** Nginx caps uploads at 20MB (`client_max_body_size` in `nginx.conf`). Increase if needed.
3. **Check logs:**
   ```bash
   docker compose logs rag-api --tail 50
   ```

---

## Scenario: Qdrant collection dimension mismatch error

**Symptom:** Errors like `Wrong input: Vector dimension error` on ingest or query.

**Cause:** You changed `EMBEDDING_MODEL` in `.env` after the collection was already created with a different embedding model's dimension.

**Fix:**
```bash
# Delete the collection and let it recreate on next startup
docker compose exec qdrant curl -X DELETE http://localhost:6333/collections/rag_documents
docker compose restart rag-api
# Then re-ingest all documents — old embeddings are gone
./scripts/04-ingest-docs.sh
```

---

## Scenario: Out of disk space

Model files are large (4-8GB+ per model). Check usage:
```bash
docker system df
df -h /
```

Clean up unused Docker resources:
```bash
docker system prune -a --volumes   # CAUTION: removes all unused containers/images/volumes, not just this project's
```

For this project specifically, remove unused Ollama models:
```bash
docker compose exec ollama ollama list
docker compose exec ollama ollama rm <model-name>
```

---

## Scenario: Need to reset everything and start fresh

```bash
./scripts/07-teardown.sh --full
./scripts/02-deploy.sh
./scripts/03-pull-model.sh
./scripts/04-ingest-docs.sh
./scripts/06-health-check.sh
```

---

## Scenario: Grafana dashboard shows "No Data"

1. Confirm Prometheus is scraping successfully: visit `http://<host>:9090/targets` — the `rag-api` target should show as `UP`.
2. Confirm the RAG API has actually received traffic — metrics only populate after at least one request. Run the health check script, which includes an end-to-end query.
3. Confirm the Grafana datasource is correctly provisioned:
   ```bash
   docker compose logs grafana | grep -i datasource
   ```

---

## Routine Maintenance

| Task | Frequency | Command |
|---|---|---|
| Check for image updates | Monthly | `docker compose pull && docker compose up -d` |
| Re-run security scan | Before any demo/interview, and monthly | `./scripts/05-security-scan.sh` |
| Review disk usage | Weekly if actively developing | `docker system df` |
| Rotate Grafana admin password | Immediately after first deploy | Grafana UI → Admin → Users |

---

## Log Locations

| Service | Command |
|---|---|
| RAG API | `docker compose logs -f rag-api` |
| Ollama | `docker compose logs -f ollama` |
| Qdrant | `docker compose logs -f qdrant` |
| Nginx (access + error) | `docker compose logs -f nginx` |
| All services combined | `docker compose logs -f` |
