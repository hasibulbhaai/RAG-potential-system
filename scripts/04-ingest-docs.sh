#!/usr/bin/env bash
# ==============================================================================
# 04-ingest-docs.sh
# ------------------------------------------------------------------------------
# Ingests all documents from ./data/documents into the running RAG API.
# If the directory is empty, creates one sample document so you have
# something to test /chat against immediately.
#
# Usage:
#   ./04-ingest-docs.sh              # ingest everything in ./data/documents
#   ./04-ingest-docs.sh myfile.pdf   # ingest a single specific file
# ==============================================================================

set -euo pipefail

log() { echo -e "\n\033[1;34m[ingest]\033[0m $1"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

DOCS_DIR="./data/documents"
API_URL="${VM_HOST:+http://$VM_HOST}"
API_URL="${API_URL:-http://localhost}"

mkdir -p "$DOCS_DIR"

# --- Create a sample doc if the folder is empty ---------------------------------
if [[ -z "$(ls -A "$DOCS_DIR" 2>/dev/null)" ]]; then
    log "No documents found in $DOCS_DIR — creating a sample document for testing."
    cat > "$DOCS_DIR/sample-platform-overview.md" << 'EOF'
# Sample Document: Platform Engineering Overview

Platform engineering is the discipline of designing and building toolchains
and workflows that enable self-service capabilities for software engineering
organizations. A platform team treats internal developers as customers and
the platform itself as a product.

Key concepts include:
- Golden paths: pre-approved, well-documented ways of building and deploying
  software that reduce cognitive load on application teams.
- Internal Developer Platforms (IDPs): tools like Backstage that provide a
  unified interface for service catalogs, documentation, and scaffolding.
- Self-service infrastructure: enabling developers to provision resources
  (databases, environments, pipelines) without filing tickets to a central
  infrastructure team.

This document exists purely as a test fixture for the RAG ingestion pipeline.
EOF
fi

# --- Ingest single file if specified ---------------------------------------------
if [[ $# -eq 1 ]]; then
    FILE="$DOCS_DIR/$1"
    [[ -f "$FILE" ]] || FILE="$1"
    log "Ingesting single file: $FILE"
    curl -s -X POST "$API_URL/ingest" -F "file=@${FILE}" | jq .
    exit 0
fi

# --- Ingest all files -------------------------------------------------------------
log "Ingesting all documents in $DOCS_DIR ..."
for file in "$DOCS_DIR"/*; do
    [[ -f "$file" ]] || continue
    log "  -> $(basename "$file")"
    curl -s -X POST "$API_URL/ingest" -F "file=@${file}" | jq .
done

log "Ingestion complete. Test it with:"
echo "  curl -s -X POST $API_URL/chat -H 'Content-Type: application/json' \\"
echo "    -d '{\"question\": \"What is a golden path in platform engineering?\"}' | jq ."
