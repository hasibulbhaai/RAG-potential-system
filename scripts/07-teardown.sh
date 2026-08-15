#!/usr/bin/env bash
# ==============================================================================
# 07-teardown.sh
# ------------------------------------------------------------------------------
# Cleanly shuts down the stack. By default, preserves volumes (models,
# vector data, dashboards) so you can restart without re-pulling models.
#
# Usage:
#   ./07-teardown.sh              # stop containers, keep volumes/data
#   ./07-teardown.sh --full       # stop containers AND delete all volumes
#                                    (models will need to be re-pulled)
# ==============================================================================

set -euo pipefail

log() { echo -e "\n\033[1;34m[teardown]\033[0m $1"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ "${1:-}" == "--full" ]]; then
    log "Stopping stack and REMOVING all volumes (models, vector data, dashboards will be lost)..."
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    if [[ "$confirm" == "yes" ]]; then
        docker compose down -v
        log "Full teardown complete. All data removed."
    else
        log "Aborted."
        exit 0
    fi
else
    log "Stopping stack (volumes preserved — models and data will remain for next startup)..."
    docker compose down
    log "Teardown complete. Run ./02-deploy.sh to bring the stack back up quickly (no re-pull needed)."
fi
