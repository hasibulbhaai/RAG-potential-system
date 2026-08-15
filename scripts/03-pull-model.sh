#!/usr/bin/env bash
# ==============================================================================
# 03-pull-model.sh
# ------------------------------------------------------------------------------
# Pulls the LLM and embedding model into the running Ollama container, then
# runs a small warm-up query so the first real user request isn't the one
# paying the cold-start cost.
#
# Usage:
#   ./03-pull-model.sh                     # uses MODEL_NAME from .env
#   ./03-pull-model.sh mistral:7b          # override model explicitly
# ==============================================================================

set -euo pipefail

log() { echo -e "\n\033[1;34m[pull-model]\033[0m $1"; }
error_exit() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; exit 1; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

[[ -f .env ]] && source .env

MODEL="${1:-${MODEL_NAME:-llama3.1:8b}}"
EMBED_MODEL="${EMBEDDING_MODEL:-nomic-embed-text}"

docker compose ps ollama | grep -q "Up" || error_exit "Ollama container is not running. Run ./02-deploy.sh first."

log "Pulling chat model: $MODEL (this can take several minutes depending on model size and connection speed)"
docker compose exec ollama ollama pull "$MODEL"

log "Pulling embedding model: $EMBED_MODEL"
docker compose exec ollama ollama pull "$EMBED_MODEL"

log "Warming up the model with a test prompt..."
docker compose exec ollama ollama run "$MODEL" "Respond with exactly: OK" --verbose=false || true

log "Models ready. Listing installed models:"
docker compose exec ollama ollama list

log "Model setup complete. Next: ./scripts/04-ingest-docs.sh"
