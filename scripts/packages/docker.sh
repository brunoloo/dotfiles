#!/usr/bin/env bash
# Docker CE installation from upstream repository
# Idempotent: checks if Docker CE is already installed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "docker"

# Check if Docker CE is already installed
if command_exists docker && docker --version 2>/dev/null | grep -q "Docker"; then
  log_success "Docker is already installed: $(docker --version)"
  end_timer "skipped"
  exit 0
fi

log_info "Installing Docker CE..."

# Remove conflicting packages
log_info "Removing conflicting packages..."
CONFLICTING=$(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc 2>/dev/null | cut -f1 || true)
if [ -n "$CONFLICTING" ]; then
  sudo apt remove -y $CONFLICTING 2>/dev/null || true
fi

# Setup Docker's apt repository
log_info "Setting up Docker apt repository..."
sudo apt update
sudo apt install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add repository to apt sources
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

# Install Docker
log_info "Installing Docker CE packages..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
if ! groups "$USER" | grep -q docker; then
  sudo usermod -aG docker "$USER"
  log_info "Added $USER to docker group (re-login required)"
fi

# Enable and start
if sudo systemctl is-active --quiet docker; then
  log_success "Docker is running: $(docker --version)"
else
  sudo systemctl start docker
  sudo systemctl enable docker
  log_success "Docker started and enabled: $(docker --version)"
fi

end_timer "success"
