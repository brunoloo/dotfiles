# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles (README.md in English, README.es.md in Spanish — keep both in sync) for Debian (KDE Plasma desktop, also usable on headless servers). Based on Salvador Borit's dotfiles-debian (used with permission). Manages configuration files using GNU Stow with a modular install script. GUI bits live only in the `kde/` package, which `install` stows only when Konsole is present.

## Architecture

Each top-level directory is a **stow package** that maps to `$HOME`:

- `shell/` — `.bashrc` (kept as a fallback), `.inputrc` (readline: case-insensitive completion, prefix history search on Up/Down), `.vimrc`, `.config/starship.toml` (pastel "capsule" theme; icons are written as `\uXXXX` escapes so they survive copy/paste — keep them that way)
- `zsh/` — `.zshrc`: Oh My Zsh (plugins `git` + `zsh-syntax-highlighting`, **no** autosuggestions), a fixed Dracula palette via `ZSH_HIGHLIGHT_STYLES`, the aliases/functions ported from `.bashrc`, Starship initialized last (after Oh My Zsh)
- `neovim/` — `.config/nvim/` (full LazyVim IDE setup)
- `scripts-local/` — `.local/bin/` (VPN and KDE Connect scripts, stowed with `--no-folding`)
- `local/` — `.local/share/wordlists/` (10k word list)
- `claude-home/` — `.claude/` (statusline script + sound hooks via PulseAudio/SSH, stowed with `--no-folding`). **`settings.json` is NOT stowed** — it's `--ignore`d by stow and instead *seeded* (copied if absent) by `install`, because Claude Code rewrites it as a real file at runtime. Symlinking it caused a stow conflict that aborted the whole package and wiped the statusline + sound links.
- `kde/` — `.local/bin/setup-init` (opens 3 Konsole windows and places them via KWin scripting over D-Bus), `setup-init.desktop` menu entry, the Konsole `Dracula` profile and color scheme (opacity 0.6 + blur), `WhiteSurDarkRed.colors` (UI color scheme for Konsole only), `.local/bin/konsole` (wrapper that starts Konsole with `QT_STYLE_OVERRIDE=Fusion`, the only way to get a red scrollbar at rest) and the wallpaper (stowed with `--no-folding`). `install` also copies the desktop icon and registers Meta+Alt+T via kwriteconfig6.
- **KDE `*rc` files are NOT stowed** (`kwinrc`, `kglobalshortcutsrc`, `plasma-*-appletsrc`, ...): KDE rewrites them at runtime and the global-shortcut service overwrites `kglobalshortcutsrc` from memory. They are applied by `scripts/kde-apply.sh` with `kwriteconfig6` and D-Bus (shortcuts via `org.kde.KGlobalAccel.setShortcut`, panel via `scripts/kde/panel.js`). It is idempotent.
- `git/` — `.config/git/config` (delta pager, zdiff3; identity stays in the untracked `~/.gitconfig`) and `.config/lazygit/config.yml` (stowed with `--no-folding`).
- `opencode/` — `.config/opencode/tui.json` (keybinds: Home/End for input bar, not scroll) and `.config/opencode/plugins/sounds.js` (event plugin reusing `claude-home`'s `~/.claude/sounds/*.wav` via `paplay`, mapped to `session.created`/`permission.asked`/`session.compacted`/`session.idle`). Stowed with `--no-folding` since `~/.config/opencode/` also holds non-stow-managed `opencode.json`, `agents/`, `node_modules/`.

Install infrastructure:

- `install` — main entry point, orchestrates everything. Accepts `--ssh-port PORT` (sshd + UFW), `--skip-packages`, `--skip-desktop` and `--skip-apps`.
- `scripts/common.sh` — shared functions: logging, `install_packages` (apt-based), `clone_pinned` (clone a repo at an exact commit), `ask_yes_no`, `configure_git`, timers
- `scripts/packages/core.sh` — apt packages (git, vim, curl, htop, btop, ufw, stow, lazygit, ripgrep, fd-find, fzf, bat, direnv, pulseaudio-utils, etc.)
- `scripts/packages/terminal.sh` — neovim >= 0.11.2 (GitHub releases), starship (curl installer), eza (gierens apt repo)
- `scripts/packages/zsh.sh` — zsh, Oh My Zsh and `zsh-syntax-highlighting` (both pinned to a commit), `chsh` to zsh
- `scripts/packages/apps.sh` — Brave (official repo), VirtualBox and VS Code (extrepo; enables its `contrib`/`non-free` policies), Wireshark (non-root capture), Node.js from Debian, adds the user to `wireshark` and `vboxusers`
- `scripts/packages/desktop.sh` — JetBrainsMono Nerd Font, Krohnkite, WhiteSur (kde, icons, cursors); versions/commits are pinned at the top of the file
- `scripts/kde-apply.sh` — applies the KDE config (see the `kde/` note above)
- `scripts/packages/earlyoom.sh` — earlyoom OOM guard + tuned `/etc/default/earlyoom` (prevents memory-exhaustion hard freezes on low-RAM shared boxes)
- `scripts/packages/docker.sh` — Docker CE from upstream apt repo (removes conflicting packages first)

## Key Commands

```bash
# Full install (no SSH/UFW changes)
./install

# Install with SSH port configuration
./install --ssh-port 2121

# Only deploy config (no apt/sudo)
./install --skip-packages

# Skip the desktop pieces (WhiteSur/Krohnkite/font + KDE config) or the apps
./install --skip-desktop
./install --skip-apps

# Re-apply only the KDE config (needs a running Plasma session for D-Bus parts)
./scripts/kde-apply.sh

# Manual stow operations
stow --restow shell                          # re-deploy a single package
stow --delete shell                          # un-deploy a single package
stow --restow --no-folding scripts-local     # for packages sharing dirs with non-stow content
```

## Design Principles

- **Idempotent**: `./install` can run multiple times safely. `install_packages` checks each package before installing. Docker checks if already present and skips. SSH/UFW config checks current state before modifying.
- **Stow-based**: Each directory mirrors the home directory structure. Files are symlinked to `$HOME` at their relative path.
- **GUI only in `kde/`** (and `scripts/kde-apply.sh`, `scripts/packages/desktop.sh`): everything else stays headless-friendly. Audio routed via PulseAudio over SSH (`RemoteForward 4713 localhost:4713`).
- **Reproducible**: external downloads are pinned (Oh My Zsh, plugin, WhiteSur and Nerd Fonts/Krohnkite versions). Bump the pins in the scripts when updating.
- **Public repo**: never commit secrets, tokens, SSH config or personal notes.
- **`--no-folding`**: Used for `scripts-local` and `claude-home` to create individual file symlinks (those `$HOME` directories contain non-stow-managed content).

## Adding a New Stow Package

1. Create directory mirroring `$HOME` path: `mkdir -p newpkg/.config/tool/`
2. Place config files at their relative path
3. Add package name to `STOW_PACKAGES` array in `install`
4. Add verification paths to `VERIFY_PATHS` in `install`

## Neovim

Uses LazyVim (lazy.nvim framework). Plugins auto-download on first `nvim` launch. `lazy-lock.json` pins plugin versions. Requires neovim >= 0.11.2 (installed from GitHub releases since Debian repos ship 0.10.x). Dependencies `build-essential`, `ripgrep`, `fd-find` are installed by core.sh for treesitter compilation and telescope search.

## scripts-local Scripts

- `vpn-up` / `vpn-down` / `vpn-status` / `vpn-cleanup` — ProtonVPN helpers (see `docs/protonvpn-debian.md`)
- `kdeconnect-desactivar` / `kdeconnect-activar` — turn KDE Connect off (no autostart, D-Bus activation blocked) or back on; `kde-apply.sh` runs the first one (see `docs/reactivar-kdeconnect.md`)
