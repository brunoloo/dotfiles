#!/usr/bin/env bash
# Core system packages for Debian servers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "core"

log_info "Installing core system packages..."
echo ""

sudo apt update

install_packages \
  git \
  vim \
  curl \
  wget \
  htop \
  btop \
  tree \
  unzip \
  ufw \
  gnupg \
  stow \
  tmux \
  jq \
  lazygit \
  openssh-server \
  net-tools \
  isc-dhcp-client \
  less \
  man-db \
  bash-completion \
  fdisk \
  dmidecode \
  lshw \
  build-essential \
  linux-headers-amd64 \
  ripgrep \
  fd-find \
  fzf \
  bat \
  direnv \
  gh \
  pulseaudio-utils

end_timer "success"
