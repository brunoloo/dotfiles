#!/usr/bin/env bash
# earlyoom — userspace OOM guard that prevents memory-exhaustion hard freezes.
# Idempotent: installs the package if missing, always (re)writes the tuned config.
#
# Why: on a low-RAM shared dev box, filling RAM + swap makes the kernel thrash
# for minutes before its own OOM killer frees anything — the box goes fully
# unresponsive and needs a manual power-cycle. earlyoom acts *early* (before swap
# is gone), kills one disposable process, logs it, and everyone else keeps working.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "earlyoom"

# earlyoom tuning (see `man earlyoom`):
#   -m 8  : SIGTERM when available RAM  < 8%  (SIGKILL at 4%)
#   -s 8  : ...and free swap < 8% — act BEFORE swap fills and the kernel thrashes
#   -r 3600 : hourly memory report to the journal (kill events are always logged)
#   --prefer : kill these first — disposable dev processes
#   --avoid  : never auto-kill session/infra or the databases; killing dockerd or
#              a DB mid-write is worse than the memory pressure itself
# NOTE: earlyoom matches /proc/*/comm, which the kernel truncates to 15 chars.
EARLYOOM_CONF='EARLYOOM_ARGS="-m 8 -s 8 -r 3600 --prefer '"'"'(^|/)(claude|node|electron|chrome|Renderer)$'"'"' --avoid '"'"'(^|/)(sshd|systemd|systemd-.*|dbus.*|tmux.*|mosh-server|bash|sudo|login|init|mongod|postgres|dockerd|containerd)$'"'"'"'

# 1. Install the package if missing
install_packages earlyoom || { end_timer "failed"; exit 1; }

# 2. Deploy the tuned config (only restart when it actually changes)
CONF_PATH="/etc/default/earlyoom"
if [ -f "$CONF_PATH" ] && diff -q <(printf '%s\n' "$EARLYOOM_CONF") <(grep -v '^\s*#' "$CONF_PATH" | grep -v '^\s*$') >/dev/null 2>&1; then
  log_success "earlyoom config already up to date"
  CONF_CHANGED=false
else
  log_info "Writing earlyoom config to $CONF_PATH..."
  sudo tee "$CONF_PATH" > /dev/null <<EOF
# Managed by dotfiles-debian (scripts/packages/earlyoom.sh) — edit there, not here.
$EARLYOOM_CONF
EOF
  log_success "earlyoom config written"
  CONF_CHANGED=true
fi

# 3. Enable + (re)start
sudo systemctl enable earlyoom >/dev/null 2>&1 || true
if ! sudo systemctl is-active --quiet earlyoom; then
  sudo systemctl start earlyoom
  log_success "earlyoom started and enabled"
elif [ "$CONF_CHANGED" = true ]; then
  sudo systemctl restart earlyoom
  log_success "earlyoom restarted with updated config"
else
  log_success "earlyoom already running"
fi

end_timer "success"
