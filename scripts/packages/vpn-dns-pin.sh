#!/usr/bin/env bash
# vpn-dns-pin.sh — make DNS survive ProtonVPN (and any NM VPN) up/down flips.
#
# Problem: the primary uplink (enp0s31f6) is UNMANAGED by NetworkManager and there
# is no systemd-resolved. When ProtonVPN's NM connection sets DNS and then tears
# down, NM has no baseline to restore, so /etc/resolv.conf is left pointing at
# Proton's resolver (10.2.0.1) or emptied. Every lookup then fails with ENOENT and
# all Claude Code / API traffic dies across every session until reboot.
#
# Fix: tell NetworkManager to never manage resolv.conf (dns=none), pin a static
# public resolver, and set the immutable bit so NOTHING can rewrite it. While
# ProtonVPN is up these queries egress through the tunnel (Cloudflare sees the
# Proton exit IP, not yours) — functional, and not an ISP-visible DNS leak.
#
# Idempotent.  Apply:  sudo bash vpn-dns-pin.sh
#              Revert:  sudo bash vpn-dns-pin.sh --revert

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run as root: sudo bash $0" >&2; exit 1; }

DROPIN=/etc/NetworkManager/conf.d/90-dns-none.conf

if [ "${1:-}" = "--revert" ]; then
  chattr -i /etc/resolv.conf 2>/dev/null || true
  rm -f "$DROPIN"
  systemctl reload NetworkManager 2>/dev/null || systemctl restart NetworkManager || true
  echo "reverted: NM manages resolv.conf again; immutable bit cleared"
  exit 0
fi

# 1. NetworkManager stops managing resolv.conf entirely.
mkdir -p /etc/NetworkManager/conf.d
printf '[main]\ndns=none\n' > "$DROPIN"

# 2. Pin a static resolver (clear immutable first so we can write).
chattr -i /etc/resolv.conf 2>/dev/null || true
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

# 3. Apply NM config, then lock the file so no VPN/openvpn/proton can clobber it.
systemctl reload NetworkManager 2>/dev/null || systemctl restart NetworkManager || true
chattr +i /etc/resolv.conf

echo "DNS pinned: /etc/resolv.conf = 1.1.1.1/8.8.8.8 (immutable), NM dns=none"
if getent hosts api.anthropic.com >/dev/null 2>&1; then
  echo "verify: api.anthropic.com resolves OK"
else
  echo "WARN: resolution failed — check network" >&2
fi
