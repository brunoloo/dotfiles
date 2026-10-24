#!/usr/bin/env bash
# Aplicaciones: Brave, VirtualBox, Wireshark, VS Code y Node.js

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "apps"

install_packages curl ca-certificates

# Brave: repositorio oficial
if is_installed brave-browser; then
  log_success "brave-browser is already installed"
else
  log_info "Setting up Brave apt repository..."
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
    https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
  sudo apt update && install_packages brave-browser
fi

# VirtualBox y VS Code: repositorios de extrepo (firmados)
install_packages extrepo
# VirtualBox vive en contrib/non-free y extrepo solo trae habilitada la política main
for policy in contrib non-free; do
  if ! grep -qx -- "- $policy" /etc/extrepo/config.yaml; then
    log_info "Enabling extrepo policy '$policy'..."
    sudo sed -i "/^enabled_policies:/a - $policy" /etc/extrepo/config.yaml
  fi
done
for repo in virtualbox vscode; do
  if [ -f "/etc/apt/sources.list.d/extrepo_${repo}.sources" ]; then
    log_success "extrepo repository '$repo' is already enabled"
  else
    log_info "Enabling extrepo repository '$repo'..."
    sudo extrepo enable "$repo"
    NEED_APT_UPDATE=true
  fi
done
[ "${NEED_APT_UPDATE:-false}" = true ] && sudo apt update

# VirtualBox necesita headers del kernel y dkms para compilar sus módulos
install_packages dkms linux-headers-amd64 virtualbox-7.2 code

# Wireshark: captura sin ser root (respuesta de debconf antes de instalar)
if ! is_installed wireshark; then
  echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
  sudo DEBIAN_FRONTEND=noninteractive apt install -y wireshark
else
  log_success "wireshark is already installed"
fi

# Grupos: wireshark (capturar) y vboxusers (USB y redes de VirtualBox)
for group in wireshark vboxusers; do
  if id -nG "$USER" | tr ' ' '\n' | grep -qx "$group"; then
    log_success "$USER is already in group $group"
  else
    sudo usermod -aG "$group" "$USER"
    log_success "$USER added to group $group (log out and in to apply)"
  fi
done

# Node.js: el de Debian
install_packages nodejs npm

end_timer
