#!/usr/bin/env bash
# ==============================================================================
# 02-deploy.sh
# ------------------------------------------------------------------------------
# Builds and starts the full RAG platform stack via Docker Compose.
#
# Usage:
#   ./02-deploy.sh              # normal deploy
#   ./02-deploy.sh --rebuild    # force rebuild of the rag-api image (no cache)
#
# Requires: Docker + Docker Compose plugin installed (see 01-provision-vm.sh)
#           .env file present (copy from .env.example if missing)
# ==============================================================================

set -euo pipefail

log() { echo -e "\n\033[1;34m[deploy]\033[0m $1"; }
error_exit() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; exit 1; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# --- Pre-flight checks ---------------------------------------------------------
command -v docker &> /dev/null || error_exit "Docker not found. Run 01-provision-vm.sh first."
docker compose version &> /dev/null || error_exit "Docker Compose plugin not found."

if [[ ! -f .env ]]; then
    log ".env not found — copying from .env.example. Review and edit it before production use."
    cp .env.example .env
fi

mkdir -p data/documents
log "Ensured ./data/documents exists (mounted read-only into rag-api for ingestion)."

# --- Build ----------------------------------------------------------------------
BUILD_FLAG=""
if [[ "${1:-}" == "--rebuild" ]]; then
    log "Rebuilding rag-api image with no cache..."
    BUILD_FLAG="--no-cache"
fi

log "Building rag-api image..."
docker compose build $BUILD_FLAG rag-api

# --- Deploy -----------------------------------------------------------------------
log "Starting full stack (ollama, qdrant, rag-api, nginx, prometheus, grafana)..."
docker compose up -d

log "Waiting for services to report healthy (up to 90s)..."
ATTEMPTS=0
MAX_ATTEMPTS=18
until docker compose ps --format json | grep -q '"Health":"healthy".*rag-api\|rag-api.*"Health":"healthy"' 2>/dev/null || (( ATTEMPTS >= MAX_ATTEMPTS )); do
    sleep 5
    ATTEMPTS=$((ATTEMPTS + 1))
    echo -n "."
done
echo ""

log "Current service status:"
docker compose ps

log "Deployment complete."
log "Next steps:"
echo "  1. Pull the LLM model:   ./scripts/03-pull-model.sh"
echo "  2. Ingest sample docs:   ./scripts/04-ingest-docs.sh"
echo "  3. Run health checks:    ./scripts/06-health-check.sh"
