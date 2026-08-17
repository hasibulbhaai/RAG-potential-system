#!/usr/bin/env bash
# ==============================================================================
# 06-health-check.sh
# ------------------------------------------------------------------------------
# Post-deploy smoke test suite. Verifies every service is reachable and
# functioning, not just "container is running."
#
# Usage:
#   ./06-health-check.sh
#
# Exit code: 0 if all checks pass, 1 if any check fails (useful in CI/cron).
# ==============================================================================

set -uo pipefail  # deliberately not -e: we want to run all checks even if one fails

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"
[[ -f .env ]] && source .env

HOST="${VM_HOST:-localhost}"
FAILURES=0

pass() { echo -e "  \033[1;32m✓\033[0m $1"; }
fail() { echo -e "  \033[1;31m✗\033[0m $1"; FAILURES=$((FAILURES + 1)); }

echo "=== RAG Platform Health Check ==="
echo "Target host: $HOST"
echo ""

# --- Container status --------------------------------------------------------------
echo "-- Container Status --"
for svc in ollama qdrant rag-api nginx prometheus grafana; do
    status=$(docker compose ps --format json "$svc" 2>/dev/null | jq -r '.State' 2>/dev/null || echo "not found")
    if [[ "$status" == "running" ]]; then
        pass "$svc container running"
    else
        fail "$svc container status: $status"
    fi
done

echo ""
echo "-- Service Endpoints --"

# --- RAG API health (via nginx) -----------------------------------------------------
if curl -sf "http://$HOST/health" -o /tmp/health_resp.json 2>/dev/null; then
    pass "RAG API /health responding via nginx"
    cat /tmp/health_resp.json | jq . 2>/dev/null | sed 's/^/      /'
else
    fail "RAG API /health NOT responding via nginx (http://$HOST/health)"
fi

# --- Ollama direct check -------------------------------------------------------------
if curl -sf "http://$HOST:11434/api/tags" &> /dev/null || docker compose exec -T ollama ollama list &> /dev/null; then
    pass "Ollama API responding"
else
    fail "Ollama API not responding"
fi

# --- Qdrant direct check -------------------------------------------------------------
if curl -sf "http://$HOST:6333/healthz" &> /dev/null; then
    pass "Qdrant API responding"
else
    fail "Qdrant API not responding (checked http://$HOST:6333/healthz)"
fi

# --- Prometheus ------------------------------------------------------------------------
if curl -sf "http://$HOST:9090/-/healthy" &> /dev/null; then
    pass "Prometheus healthy"
else
    fail "Prometheus not responding"
fi

# --- Grafana ---------------------------------------------------------------------------
if curl -sf "http://$HOST:3000/api/health" &> /dev/null; then
    pass "Grafana healthy"
else
    fail "Grafana not responding"
fi

# --- End-to-end RAG query test -----------------------------------------------------------
echo ""
echo "-- End-to-End Query Test --"
RESPONSE=$(curl -sf -X POST "http://$HOST/chat" \
    -H "Content-Type: application/json" \
    -d '{"question": "test query for health check", "top_k": 1}' 2>/dev/null || echo "FAILED")

if [[ "$RESPONSE" != "FAILED" ]] && echo "$RESPONSE" | jq -e '.answer' &> /dev/null; then
    pass "End-to-end /chat query succeeded"
    LATENCY=$(echo "$RESPONSE" | jq -r '.latency_ms')
    echo "      Latency: ${LATENCY}ms"
else
    fail "End-to-end /chat query failed — check that a model has been pulled (./03-pull-model.sh)"
fi

echo ""
echo "=== Summary ==="
if (( FAILURES == 0 )); then
    echo -e "\033[1;32mAll checks passed.\033[0m"
    exit 0
else
    echo -e "\033[1;31m${FAILURES} check(s) failed.\033[0m See docs/RUNBOOK.md for troubleshooting steps."
    exit 1
fi
