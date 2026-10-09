#!/usr/bin/env bash
# ProtonVPN CLI installation from upstream repository
# Idempotent: skips repo setup and packages already present
#
# Notes:
# - Pulls a LOT of GUI deps (GTK, mesa, fonts, gnome-keyring) via NM-openvpn-gnome.
#   Headless boxes still get them, but they sit unused.
# - Installs the NM backend modules manually because proton-vpn-cli's deps don't
#   pull them in (Debian packaging gap).
# - linux-headers-amd64 is required for the daemon's BPF split-tunneling; installed in core.sh.
# - Drops a polkit rule so users in the netdev group can modify NM system connections
#   from a TTY/headless session. Without it, connect fails with
#   "nm-settings-error-quark: Insufficient privileges" because the polkit default
#   requires an active seat (graphical session).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "protonvpn"

# Helper: disable the kill switch. The CLI 1.0.1 NM-based kill switch creates
# a dummy interface (pvpnksintrf0) with metric 98 that hijacks the default
# route for 2-8s during VPN flip. If the CLI is interrupted, the
# `pvpn-killswitch` / `pvpn-routed-killswitch` NM connections remain, leaving
# the bad route in place until reboot. We disable it here and rely on the
# vpn-up/vpn-down/vpn-cleanup wrappers in scripts-local for orphan cleanup.
# See docs/protonvpn-debian.md for the full rationale.
disable_kill_switch() {
  if ! command_exists protonvpn; then
    return 0
  fi
  log_info "Disabling ProtonVPN kill switch (see docs/protonvpn-debian.md)..."
  # The CLI prints noisy auth lines on stdout; filter them.
  if protonvpn config set kill-switch off 2>&1 | grep -viE 'authenticating|^$' || true; then
    log_success "Kill switch set to off"
  fi
}

if command_exists protonvpn; then
  log_success "ProtonVPN CLI is already installed: $(protonvpn --version 2>/dev/null || echo present)"
  disable_kill_switch
  end_timer "skipped"
  exit 0
fi

log_info "Installing ProtonVPN CLI..."

# Setup ProtonVPN apt repository
if ! dpkg -s protonvpn-stable-release &>/dev/null; then
  log_info "Setting up ProtonVPN apt repository..."
  PVPN_DEB="/tmp/protonvpn-stable-release_1.0.8_all.deb"
  PVPN_SHA="0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180"
  wget -qO "$PVPN_DEB" https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb
  echo "$PVPN_SHA  $PVPN_DEB" | sha256sum --check -
  sudo dpkg -i "$PVPN_DEB"
  rm -f "$PVPN_DEB"
  sudo apt update
fi

# Install CLI + NM backend modules
log_info "Installing ProtonVPN packages..."
sudo apt install -y \
  proton-vpn-cli \
  python3-proton-vpn-network-manager \
  python3-proton-vpn-network-manager-wireguard \
  python3-proton-vpn-network-manager-openvpn \
  python3-proton-vpn-killswitch-network-manager \
  python3-proton-vpn-killswitch-network-manager-wireguard

# Install polkit rule for netdev-group users on headless sessions
log_info "Installing polkit rule for headless NM access..."
sudo tee /etc/polkit-1/rules.d/49-proton-vpn-netdev.rules > /dev/null <<'EOF'
// Allow netdev group users to modify NetworkManager system connections
// without requiring an active local seat. Needed for headless/TTY-only
// sessions where Proton VPN's kill-switch and connection profiles must
// be installed but no graphical session exists for polkit to authenticate.
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.NetworkManager.settings.modify.system" ||
         action.id == "org.freedesktop.NetworkManager.network-control" ||
         action.id == "org.freedesktop.NetworkManager.settings.modify.own") &&
        subject.isInGroup("netdev")) {
        return polkit.Result.YES;
    }
});
EOF
sudo systemctl restart polkit

# Ensure user is in netdev (the polkit rule's group)
if ! groups "$USER" | grep -qw netdev; then
  sudo usermod -aG netdev "$USER"
  log_info "Added $USER to netdev group (re-login required for it to apply)"
fi

disable_kill_switch

log_success "ProtonVPN CLI installed. Sign in with: protonvpn signin <username>"

end_timer "success"
