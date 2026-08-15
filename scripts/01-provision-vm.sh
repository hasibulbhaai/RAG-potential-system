#!/usr/bin/env bash
# ==============================================================================
# 01-provision-vm.sh
# ------------------------------------------------------------------------------
# Prepares a fresh Ubuntu 22.04 VM to run the RAG platform stack.
# Idempotent: safe to re-run if a step fails partway through.
#
# What this does:
#   1. Updates apt packages
#   2. Installs Docker Engine + Docker Compose plugin
#   3. Installs supporting CLI tools (curl, jq, htop)
#   4. Configures UFW firewall rules for the ports this stack uses
#   5. Adds the current user to the docker group (avoids needing sudo for docker)
#
# Usage:
#   chmod +x 01-provision-vm.sh
#   ./01-provision-vm.sh
#
# Requires: sudo privileges, Ubuntu 22.04 LTS
# ==============================================================================

set -euo pipefail

log() { echo -e "\n\033[1;34m[provision]\033[0m $1"; }
error_exit() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; exit 1; }

# --- Sanity checks -----------------------------------------------------------
if [[ "$(lsb_release -is 2>/dev/null)" != "Ubuntu" ]]; then
    log "WARNING: This script is tested on Ubuntu 22.04. Proceeding anyway, but expect possible issues."
fi

if [[ $EUID -eq 0 ]]; then
    error_exit "Do not run this script as root directly. Run as a regular user with sudo access."
fi

# --- 1. System update ----------------------------------------------------------
log "Updating apt package index..."
sudo apt-get update -y

log "Upgrading existing packages (this may take a few minutes)..."
sudo apt-get upgrade -y

# --- 2. Install Docker --------------------------------------------------------
if command -v docker &> /dev/null; then
    log "Docker already installed ($(docker --version)). Skipping install."
else
    log "Installing Docker Engine..."
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log "Adding current user ($USER) to the docker group..."
    sudo usermod -aG docker "$USER"
    log "NOTE: You must log out and back in (or run 'newgrp docker') for group changes to take effect."
fi

# --- 3. Supporting tools -------------------------------------------------------
log "Installing supporting CLI tools (curl, jq, htop, git)..."
sudo apt-get install -y curl jq htop git

# --- 4. Firewall configuration --------------------------------------------------
log "Configuring UFW firewall rules..."
if ! command -v ufw &> /dev/null; then
    sudo apt-get install -y ufw
fi

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp    comment "RAG API via nginx"
sudo ufw allow 3000/tcp  comment "Grafana"
sudo ufw allow 9090/tcp  comment "Prometheus"
# Ollama (11434) and Qdrant (6333) are intentionally NOT opened externally —
# they should only be reachable from within the docker network.
# See docs/SECURITY.md for the reasoning.

log "Enabling UFW (if not already active)..."
sudo ufw --force enable
sudo ufw status verbose

# --- 5. Disk space check --------------------------------------------------------
AVAILABLE_GB=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
if (( AVAILABLE_GB < 50 )); then
    log "WARNING: Only ${AVAILABLE_GB}GB free on / — recommended minimum is 100GB. Model downloads alone can consume 10-20GB."
fi

log "Provisioning complete."
log "If this is your first Docker install, log out and back in now, then proceed to ./02-deploy.sh"
