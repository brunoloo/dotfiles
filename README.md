# dotfiles

🇬🇧 **English** · 🇺🇾 [Español](README.es.md)

My Linux setup (Debian + KDE Plasma): terminal, shell, tmux, Neovim, git and a desktop layout that opens with one key. One command installs all of it.

> **Credits:** the base of this repo (bash, tmux, Neovim, starship, tmux scripts, Claude Code hooks) is the config of my coworker [Salvador Borit](https://github.com/salvaborit) ([dotfiles-debian](https://github.com/salvaborit/dotfiles-debian)), shared here with his permission. On top of it I added my own stuff: the KDE desktop, `setup-init`, aliases, history, fzf/bat/direnv, delta and more.

## Install

On a fresh Debian:

```bash
git clone https://github.com/brunoloo/dotfiles.git ~/dotfiles
~/dotfiles/install
```

The installer:

1. Installs packages (apt, Neovim, starship, eza, Node, Docker, etc.). Needs `sudo`.
2. Symlinks every config into your `$HOME` with [GNU stow](https://www.gnu.org/software/stow/). Any file of your own that's in the way gets moved first to `~/.dotfiles-backup-<date>/`.
3. If it finds KDE, it sets up Konsole (green on black), the Breeze Dark theme, the `setup_init` desktop icon and the `Meta+Alt+T` shortcut. The theme and the shortcut fully apply after logging in again.

Options:

```bash
~/dotfiles/install --skip-packages     # config only, no apt, no sudo
~/dotfiles/install --ssh-port 2121     # also configures sshd + firewall (servers)
```

You can run it as many times as you want: whatever is already installed gets skipped.

Since the files are symlinks, editing `~/.bashrc` edits the repo: then `git commit` + `git push` and the change is saved for the next machine.

## What's inside

### KDE desktop

| | |
|---|---|
| **`setup-init`** / **setup_init** icon / **`Meta+Alt+T`** | Opens 3 Konsole windows and places them on the external monitor: one on each side (45% wide, full height) and the third one centered behind them; clicking the strip in the middle brings it to the front. Works on Wayland using KWin scripting. The monitor and width are set at the top of the script (`OUTPUT`, `WIDTH_PCT`). |
| **Konsole** | `bruno-verde-pc` as default profile: GreenOnBlack color scheme with the Hack font. |
| **Theme** | Breeze Dark (colors and icons). Leaves your wallpaper, panel and virtual desktops alone. |

The desktop icon is a regular copy: rename it or change its icon from right click → Properties.

### Shell (bash)

- **Prompt** by [starship](https://starship.rs) (git branch, status, project language).
- **History:** huge, timestamped and shared across all open terminals.
- **fzf:** `Ctrl+R` searches history, `Ctrl+T` picks a file, `Alt+C` jumps to a folder.
- **`.inputrc`:** case-insensitive completion; ↑/↓ search history for what you started typing.
- **zoxide:** `cd` learns your frequent folders (`cd proj` → `~/work/project`).
- **bat**, **eza**, **direnv**, **bash-completion** and Uruguayan date format.

Most used aliases and functions:

| Command | What it does |
|---|---|
| `ta`, `tb`, `tc`… | `ssh t-dmi-a`, `ssh t-dmi-b`… Built automatically from every `Host t-dmi-X` in `~/.ssh/config`; they only exist on the PC, not inside an ssh session. |
| `mkcd dir` | creates the folder and enters it |
| `ex file` | extracts any archive (tar, zip, 7z, rar…) |
| `ls`, `ll`, `lt` | eza listings (icons, tree, git status) |
| `g`, `gits`, `gitd`, `gitac "msg"`, `gg` | git and lazygit |
| `d`, `dc`, `dcu`, `dcud`, `dcd`, `dp`… | docker and docker compose |
| `n` | nvim |
| `cc`, `ccc`, `ccw` | Claude Code (normal, skip permissions, in a worktree) |
| `serve [port]` | HTTP server for the current folder |
| `note`, `todo`, `notes` | quick notes in `~/notes.md` |
| `q`, `c` | exit, clear |

`aliases` prints the full list.

### Git

- **[delta](https://github.com/dandavid/delta)** as pager: `git diff`, `git log -p` and `git show` with syntax highlighting and line numbers; `n`/`N` jump between files.
- **lazygit** (`gg`) shows diffs through delta.
- Merge conflicts in `zdiff3` style (also shows the original version).

This lives in `~/.config/git/config`. Your name, email and credentials stay in `~/.gitconfig`, which isn't in the repo: the installer asks for them.

### tmux

Config and a status bar with git info, plus scripts:

- `tmux-session`: pick or create a session;
- `tmux-project`: editor + terminal session for a repo in `~/prj/`;
- `tmux-save` / `tmux-restore`: save and restore sessions.

### Neovim

Full setup based on [LazyVim](https://www.lazyvim.org). Plugins download on their own the first time you open `nvim`.

### Other

- **Claude Code:** statusline and sounds on start, finish or permission prompt.
- **opencode:** keybinds and the same sounds.
- **ProtonVPN:** `vpn-up`, `vpn-down`, `vpn-status` ([docs](docs/protonvpn-debian.md)).

## Layout

Each folder is a stow package mirroring `$HOME`:

```
shell/          .bashrc, .inputrc, .vimrc, starship.toml
tmux/           tmux.conf + git script for the status bar
neovim/         ~/.config/nvim
kde/            setup-init, Konsole profile, menu entry
git/            delta (~/.config/git/config) and lazygit
scripts-local/  tmux and VPN scripts in ~/.local/bin
claude-home/    Claude Code statusline and sounds
opencode/       opencode config
local/          word list for session names
scripts/        installer functions and packages
```
