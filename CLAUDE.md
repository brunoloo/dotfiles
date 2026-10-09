# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles (README.md in English, README.es.md in Spanish — keep both in sync) for Debian (KDE Plasma desktop, also usable on headless servers). Based on Salvador Borit's dotfiles-debian (used with permission). Manages configuration files using GNU Stow with a modular install script. GUI bits live only in the `kde/` package, which `install` stows only when Konsole is present.

## Architecture

Each top-level directory is a **stow package** that maps to `$HOME`:

- `shell/` — `.bashrc`, `.inputrc` (readline: case-insensitive completion, prefix history search on Up/Down), `.vimrc`, `.config/starship.toml`
- `tmux/` — `.config/tmux/` (config + git-status script for status bar)
- `neovim/` — `.config/nvim/` (full LazyVim IDE setup)
- `scripts-local/` — `.local/bin/` (tmux utility scripts, stowed with `--no-folding`)
- `local/` — `.local/share/wordlists/` (10k word list used by terminal-tmux-bash)
- `claude-home/` — `.claude/` (statusline script + sound hooks via PulseAudio/SSH, stowed with `--no-folding`). **`settings.json` is NOT stowed** — it's `--ignore`d by stow and instead *seeded* (copied if absent) by `install`, because Claude Code rewrites it as a real file at runtime. Symlinking it caused a stow conflict that aborted the whole package and wiped the statusline + sound links.
- `kde/` — `.local/bin/setup-init` (opens 3 Konsole windows and places them via KWin scripting over D-Bus), Konsole profile, `setup-init.desktop` menu entry (stowed with `--no-folding`). `install` also sets konsolerc DefaultProfile, copies the desktop icon and registers Meta+Alt+T via kwriteconfig6.
- `git/` — `.config/git/config` (delta pager, zdiff3; identity stays in the untracked `~/.gitconfig`) and `.config/lazygit/config.yml` (stowed with `--no-folding`).
- `opencode/` — `.config/opencode/tui.json` (keybinds: Home/End for input bar, not scroll) and `.config/opencode/plugins/sounds.js` (event plugin reusing `claude-home`'s `~/.claude/sounds/*.wav` via `paplay`, mapped to `session.created`/`permission.asked`/`session.compacted`/`session.idle`). Stowed with `--no-folding` since `~/.config/opencode/` also holds non-stow-managed `opencode.json`, `agents/`, `node_modules/`.

Install infrastructure:

- `install` — main entry point, orchestrates everything. Accepts `--ssh-port PORT` to configure sshd + UFW.
- `scripts/common.sh` — shared functions: logging, `install_packages` (apt-based), `ask_yes_no`, `configure_git`, timers
- `scripts/packages/core.sh` — apt packages (git, vim, tmux, curl, htop, btop, ufw, stow, lazygit, ripgrep, fd-find, fzf, bat, direnv, pulseaudio-utils, etc.)
- `scripts/packages/terminal.sh` — neovim >= 0.11.2 (GitHub releases), starship (curl installer), eza (gierens apt repo)
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

# Manual stow operations
stow --restow shell                          # re-deploy a single package
stow --delete shell                          # un-deploy a single package
stow --restow --no-folding scripts-local     # for packages sharing dirs with non-stow content
```

## Design Principles

- **Idempotent**: `./install` can run multiple times safely. `install_packages` checks each package before installing. Docker checks if already present and skips. SSH/UFW config checks current state before modifying.
- **Stow-based**: Each directory mirrors the home directory structure. Files are symlinked to `$HOME` at their relative path.
- **GUI only in `kde/`**: everything else stays headless-friendly. Tmux scripts use bash `select` menus instead of rofi. Copy mode uses tmux buffer instead of Wayland clipboard. Audio routed via PulseAudio over SSH (`RemoteForward 4713 localhost:4713`).
- **`--no-folding`**: Used for `scripts-local` and `claude-home` to create individual file symlinks (those `$HOME` directories contain non-stow-managed content).

## Adding a New Stow Package

1. Create directory mirroring `$HOME` path: `mkdir -p newpkg/.config/tool/`
2. Place config files at their relative path
3. Add package name to `STOW_PACKAGES` array in `install`
4. Add verification paths to `VERIFY_PATHS` in `install`

## Neovim

Uses LazyVim (lazy.nvim framework). Plugins auto-download on first `nvim` launch. `lazy-lock.json` pins plugin versions. Requires neovim >= 0.11.2 (installed from GitHub releases since Debian repos ship 0.10.x). Dependencies `build-essential`, `ripgrep`, `fd-find` are installed by core.sh for treesitter compilation and telescope search.

## scripts-local Scripts

All adapted for headless use (no rofi, no alacritty):

- `tmux-session` — interactive session picker/creator (uses bash `select`)
- `tmux-project` — creates editor+bash session pair for git repos in `~/prj/`
- `tmux-save` / `tmux-restore` — persist and restore tmux session layouts
- `terminal-tmux-bash` — creates a new session with a random wordlist name
