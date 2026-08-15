#!/usr/bin/env bash
# ==============================================================================
# 05-security-scan.sh
# ------------------------------------------------------------------------------
# Runs the supply-chain security pass on the rag-api image:
#   1. Generate an SBOM (Software Bill of Materials) with Syft
#   2. Scan for known vulnerabilities with Trivy
#   3. Sign the image with Cosign (keyless, via Sigstore's public transparency log)
#
# This script installs Syft, Trivy, and Cosign locally if not already present.
#
# Usage:
#   ./05-security-scan.sh
#
# Output:
#   ./security-reports/sbom.json           - full SBOM in CycloneDX format
#   ./security-reports/vuln-report.json    - Trivy vulnerability findings
#   ./security-reports/vuln-report.txt     - human-readable summary
#
# Note: Keyless signing with Cosign requires an OIDC identity (e.g., a GitHub
# account) and opens a browser for auth on first use — expected for a POC/
# local run. CI pipelines use OIDC tokens instead; see .github/workflows/ci-security.yml
# ==============================================================================

set -euo pipefail

log() { echo -e "\n\033[1;34m[security-scan]\033[0m $1"; }
error_exit() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; exit 1; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

IMAGE_NAME="rag-platform/rag-api:latest"
REPORT_DIR="./security-reports"
mkdir -p "$REPORT_DIR"

# --- Install Syft if missing -----------------------------------------------------
if ! command -v syft &> /dev/null; then
    log "Installing Syft (SBOM generator)..."
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
fi

# --- Install Trivy if missing -----------------------------------------------------
if ! command -v trivy &> /dev/null; then
    log "Installing Trivy (vulnerability scanner)..."
    curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

# --- Install Cosign if missing -----------------------------------------------------
if ! command -v cosign &> /dev/null; then
    log "Installing Cosign (image signing)..."
    COSIGN_VERSION="v2.4.0"
    curl -sSfLo /tmp/cosign "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
    sudo install -m 0755 /tmp/cosign /usr/local/bin/cosign
fi

# --- Ensure the image exists --------------------------------------------------------
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    error_exit "$IMAGE_NAME not found locally. Run ./02-deploy.sh first to build it."
fi

# --- 1. Generate SBOM -----------------------------------------------------------------
log "Generating SBOM (CycloneDX format)..."
syft "$IMAGE_NAME" -o cyclonedx-json="$REPORT_DIR/sbom.json"
syft "$IMAGE_NAME" -o table="$REPORT_DIR/sbom-summary.txt"
log "SBOM written to $REPORT_DIR/sbom.json"

# --- 2. Vulnerability scan -------------------------------------------------------------
log "Scanning for vulnerabilities with Trivy..."
trivy image --severity HIGH,CRITICAL --format json --output "$REPORT_DIR/vuln-report.json" "$IMAGE_NAME"
trivy image --severity HIGH,CRITICAL --format table --output "$REPORT_DIR/vuln-report.txt" "$IMAGE_NAME"

CRITICAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$REPORT_DIR/vuln-report.json" 2>/dev/null || echo "0")
HIGH_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$REPORT_DIR/vuln-report.json" 2>/dev/null || echo "0")

log "Scan summary: ${CRITICAL_COUNT} CRITICAL, ${HIGH_COUNT} HIGH severity findings"
log "Full report: $REPORT_DIR/vuln-report.txt"

if (( CRITICAL_COUNT > 0 )); then
    echo -e "\033[1;31m⚠ CRITICAL vulnerabilities found. Review $REPORT_DIR/vuln-report.txt before deploying beyond local POC use.\033[0m"
fi

# --- 3. Sign the image -------------------------------------------------------------------
log "Signing image with Cosign (keyless — this will open a browser for OIDC auth on first run)..."
log "NOTE: keyless signing requires the image to be pushed to a registry first."
log "For a pure local POC, this step is illustrative — see docs/SECURITY.md for the registry-push variant."
echo ""
echo "  To sign after pushing to a registry:"
echo "    docker tag $IMAGE_NAME <your-registry>/$IMAGE_NAME"
echo "    docker push <your-registry>/$IMAGE_NAME"
echo "    cosign sign <your-registry>/$IMAGE_NAME"
echo ""
echo "  To verify a signed image:"
echo "    cosign verify <your-registry>/$IMAGE_NAME \\"
echo "      --certificate-identity=<your-oidc-identity> \\"
echo "      --certificate-oidc-issuer=https://github.com/login/oauth"

log "Security scan pass complete. Reports available in $REPORT_DIR/"
