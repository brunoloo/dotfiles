# ProtonVPN CLI on headless Debian — notes

> **See also:** [protonvpn-dns-networking.md](protonvpn-dns-networking.md) — why a
> VPN up/down *flip* can break all networking (ENOENT / API errors) and how it's
> permanently pinned.

A fresh `apt install proton-vpn-cli` on a TTY-only Debian box (no graphical
session) sign-ins fine but `protonvpn connect` fails with:

```
An unexpected error occurred. Please try again.
```

This has hit at least three machines. Root cause is three independent Debian
packaging / system gaps stacked on top of each other. `scripts/packages/protonvpn.sh`
handles all three for new installs; this doc explains what they are so a future
me can diagnose if anything regresses.

## Symptom

- `protonvpn signin <user>` — succeeds (the file keyring fallback works).
- `protonvpn connect --country US` — prints the generic "unexpected error"
  message and exits non-zero. The CLI's catch-all swallows the real traceback
  (`proton/vpn/cli/__init__.py` around line 191), so the underlying problem
  isn't visible without digging.

## Three root causes, in the order they bite

### 1. `proton-vpn-daemon` requires kernel headers but doesn't depend on them

`me.proton.vpn.split_tunneling.service` is the daemon the CLI talks to over
D-Bus. On startup it eagerly initializes the app-based split-tunneling socket
monitor, which uses `bcc`/BPF and compiles a BPF program at runtime. That
compile needs:

- `modprobe` on PATH (provided by `kmod`, normally fine)
- `/lib/modules/$(uname -r)/build` — i.e. kernel headers

Without `linux-headers-amd64` the daemon crashes immediately and the CLI gets
`Backend: None` because nothing's listening on D-Bus.

Diagnosis:

```bash
systemctl status me.proton.vpn.split_tunneling.service   # will be failed
sudo /usr/bin/python3 -m proton.vpn.daemon                # shows the BPF error
```

Fix: install kernel headers, restart the daemon.

```bash
sudo apt install -y linux-headers-amd64
sudo systemctl restart me.proton.vpn.split_tunneling.service
```

`linux-headers-amd64` is already in `scripts/packages/core.sh` so a fresh `./install`
covers this.

### 2. `proton-vpn-cli` 1.0.1 doesn't pull the NM backend modules

Older `proton-vpn-cli` versions had `python3-proton-vpn-network-manager` as a
hard dep. The current Debian package dropped it. Without those modules the
connector loads but has no protocol backend, so it never reaches NetworkManager.
Symptom in the log: `Protocol: wireguard / Backend: None` followed by silence.

The five missing packages:

- `python3-proton-vpn-network-manager`
- `python3-proton-vpn-network-manager-wireguard`
- `python3-proton-vpn-network-manager-openvpn`
- `python3-proton-vpn-killswitch-network-manager`
- `python3-proton-vpn-killswitch-network-manager-wireguard`

The CLI registers them via `proton.vpn.core.api.create_registry` which does
`registry.register_from_module('proton.vpn.backend.networkmanager.protocol.wireguard')`
etc. (the proton-loader entry_points story is irrelevant — that import path is
what matters).

Diagnosis:

```bash
python3 -c "from proton.vpn.core.registry import Registry; \
  r = Registry(); \
  r.register_from_module('proton.vpn.backend.networkmanager.protocol.wireguard'); \
  print(r._registry)"
# should print {'wireguard': <class '...Wireguard'>}
# if the module isn't installed you get ModuleNotFoundError
```

Fix: install the five packages. Already handled by `protonvpn.sh`.

### 3. NetworkManager polkit rule requires an active seat — TTY sessions have none

This is the real one. Even with daemon up and backend loaded, the WireGuard
kill switch tries to install a system NM connection and gets:

```
RuntimeError: Error adding KS connection: nm-settings-error-quark: Insufficient privileges (1)
```

Debian's `/usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules`:

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.local && subject.active &&
        (subject.isInGroup ("sudo") || subject.isInGroup ("netdev"))) {
        return polkit.Result.YES;
    }
});
```

`subject.active` is true only for a session on an active seat — i.e. a logged-in
graphical session on `seat0`. On a headless or TTY-only machine `loginctl`
shows `SEAT -` and all sessions are inactive from polkit's perspective. Group
membership doesn't matter; the rule is gated on the active check.

Diagnosis:

```bash
loginctl                          # SEAT column will be "-"
echo $XDG_SESSION_TYPE            # "tty" (not "x11" / "wayland")
```

Fix: drop a polkit rule that grants the action to `netdev` members without
requiring `subject.active`. `protonvpn.sh` installs this at
`/etc/polkit-1/rules.d/49-proton-vpn-netdev.rules`. The user must also be in
the `netdev` group (the script adds them).

This is the standard headless-NM workaround and applies to anything that needs
to mutate system NM connections from a TTY/SSH session, not just ProtonVPN.

## Confirmation that everything's wired up

After a fresh install:

```bash
systemctl is-active me.proton.vpn.split_tunneling.service   # active
python3 -c "import proton.vpn.backend.networkmanager.protocol.wireguard"  # no error
ls /etc/polkit-1/rules.d/49-proton-vpn-netdev.rules         # exists
groups | grep -q netdev && echo OK                          # OK
protonvpn signin <username>
protonvpn connect --country US                              # Connected to US-XX#NNN
```

## Logs worth checking when something breaks differently

- `~/.cache/Proton/VPN/logs/vpn-cli.log` — connector state changes; the CLI
  itself doesn't append the final traceback here, but earlier failures
  (keyring, server-list fetch) show up
- `~/.cache/Proton/VPN/logs/vpn-daemon.log` — split-tunneling daemon
- `sudo journalctl -u me.proton.vpn.split_tunneling.service` — daemon stderr
  including BPF compile errors
- `journalctl --user -n 100` — gnome-keyring / gcr-prompter failures and
  D-Bus activation errors
- `journalctl -n 100 | grep NetworkManager` — NM-side errors during connect

To surface the real traceback the CLI is hiding, replicate the call without
going through `protonvpn`:

```bash
python3 -c "
from proton.vpn.cli import main
main(cli_args=['connect', '--country', 'US'])
"
```

The catch-all in `main()` still re-raises after the print, but running it
this way the traceback lands on stderr instead of being eaten by the installed
script wrapper.

## Kill switch causes orphaned routes / disconnect hangs / Claude API drops

CLI 1.0.1 ships an NM-based kill switch that is broken in a way that wedges
the box's networking until reboot. We disable it at install time and
distribute four wrapper scripts (`vpn-up`, `vpn-down`, `vpn-status`,
`vpn-cleanup` — see `scripts-local/.local/bin/`) that the recon skill and any
ad-hoc caller should use instead of `protonvpn connect/disconnect` directly.

### What goes wrong

On every connect, the kill switch creates a dummy NM connection
`pvpn-killswitch` backed by interface `pvpnksintrf0` with:

- `ipv4.route-metric: 98` (lower number wins — beats the real default route)
- `ipv4.gateway: 100.85.0.1` (fake, unreachable)
- `ipv4.dns: 0.0.0.0` with `dns-priority: -1400` (overrides everything else)

While that connection is up, all traffic to e.g. `api.anthropic.com` is
routed at the dummy interface and gets `ECONNREFUSED` synchronously. The
window is 2-8 seconds during connect AND during disconnect — long enough to
kill an active Claude Code session mid-call.

Worse, if the CLI is interrupted (35s `timeout`, SIGKILL, async race
inside `wait_for_current_tasks()` — the 10s asyncio barrier in the
`disconnect` command), the `pvpn-killswitch` and `pvpn-routed-killswitch` NM
connections are not torn down. The metric-98 dummy route survives, and the
box has no working default route until reboot.

This bites us specifically because `enp0s31f6` is `managed=false` (ifupdown).
NM's priority system can't cleanly supersede the default route on an
unmanaged interface; both routes coexist and the dummy wins on metric.

### Mitigation

1. **Installer disables the kill switch.** `scripts/packages/protonvpn.sh`
   runs `protonvpn config set kill-switch off` on every install. With
   kill-switch off, the dummy connections are never created.

2. **Wrappers run cleanup on every disconnect.** `vpn-down` always calls
   `vpn-cleanup` after `protonvpn disconnect`, even on success. Cleanup is
   idempotent (`nmcli connection delete … 2>/dev/null || true` per name) and
   covers `pvpn-killswitch`, `pvpn-killswitch-perm`,
   `pvpn-routed-killswitch`, `pvpn-routed-killswitch-perm`,
   `pvpn-killswitch-ipv6`, `pvpn-ipv6leak-protection`.

3. **Wrappers cap CLI hangs.** All wrappers wrap their `protonvpn` call in
   `timeout 35`. For `vpn-down`/`vpn-status` a timeout (exit 124) is
   soft-success — the state change has already happened, just the asyncio
   cleanup hung. For `vpn-up` a timeout is a hard failure (route table may
   be inconsistent); the caller should rotate to a different country.

4. **The wrapper config never re-enables the kill switch.** Only the
   installer touches `protonvpn config set kill-switch`. The runtime
   wrappers only manage the NM connections, never the config setting.

### Trade-off

There is a 2-8s IP-leak window during every `vpn-up` and `vpn-down`. For
recon workflows that's acceptable — the actual scan tools run only after
the tunnel is confirmed up. If leak protection is critical for a different
workflow, options are:

- Per-app firewall rules binding specific tools to `tun0` (no system-wide
  kill switch needed).
- A different VPN client (Mullvad, `wg-quick`) whose kill switch isn't
  built on NM dummy interfaces.

Do **not** re-enable the kill switch via the GUI or `protonvpn config set
kill-switch standard` without re-reading this section — it brings back all
three bugs (hang, ConnectionRefused, post-disconnect routing wedge).

## Aside — the noisy keyring tracebacks

The vpn-cli.log is full of `secretstorage.exceptions.PromptDismissedException`
and `Failed to create the collection: Prompt dismissed.` warnings. These come
from `gnome-keyring-daemon` trying to spawn `gcr-prompter` (which needs a
display) to create the default keyring collection. On a headless box this
always fails, but proton-keyring-linux falls through to its JSON file backend
(`~/.cache/Proton/VPN/keyring/`). The noise is harmless and not the cause of
connect failures — leave it alone.
