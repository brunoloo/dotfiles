# Zsh + Oh My Zsh. Portado de shell/.bashrc (Starship al final, después de cargar Oh My Zsh)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # el prompt lo pone Starship
plugins=(git zsh-syntax-highlighting)  # syntax-highlighting siempre último (sin autosuggestions: incomodaba)

# History - grande, con fecha, compartido en vivo entre terminales
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=200000
HISTORY_IGNORE='(ls|ll|c|clear|q|exit|pwd)'
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY

source $ZSH/oh-my-zsh.sh

# >>> paleta Dracula del resaltado de sintaxis (borrar entre marcas para revertir) >>>
# Paleta del resaltado de sintaxis (Dracula)
#   verde  = comandos válidos     rosa   = palabras reservadas / operadores
#   naranja= opciones (-x, --xx)  blanco = argumentos normales
#   cian   = rutas existentes     amarillo = strings
#   violeta= variables            gris   = comentarios      rojo = error
ZSH_HIGHLIGHT_STYLES[command]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[function]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#50fa7b,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#50fa7b'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ffb86c'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ffb86c'
ZSH_HIGHLIGHT_STYLES[default]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#f8f8f2'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#bd93f9'
ZSH_HIGHLIGHT_STYLES[path]='fg=#8be9fd,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#8be9fd,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#8be9fd'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#8be9fd'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#f1fa8c'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#ff79c6'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#bd93f9'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#bd93f9'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#bd93f9'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6272a4'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff5555,bold'
# <<< paleta Dracula <<<

export PATH="$HOME/.local/bin:$PATH"
export EDITOR='nvim'
export COLORTERM=truecolor

# File system - eza-based ls replacement
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias ll='ls -lah'
  alias lr='ls -lahsnew'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
else
  # Fallback to standard ls if eza is not installed
  alias ls='ls -lh --color=auto'
  alias lsa='ls -lah'
fi

alias update='sudo apt update -y && sudo apt upgrade -y'
alias gg='lazygit'
alias gita='git add'
alias gitc='git commit -m'
alias gitac='git add . && git commit -m'
alias gitl='git log'
alias gitd='git diff'
alias gits='git status'
alias g='git'
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcub='docker compose up --build'
alias dcudb='docker compose up -d --build'
alias dcbnc='docker compose build --no-cache'
alias dcd='docker compose down'
alias dcpa='docker compose ps -a'
alias dcp='docker compose ps'
alias dcl='docker compose logs'
alias dcs='docker compose stats'
alias dpa='docker ps -a'
alias dp='docker ps'
alias ds='docker stats'
alias q='exit'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias n='nvim'
alias dtree='tree -C -d --dirsfirst'
alias ftree='tree -C -L 5 --dirsfirst'
alias cc='claude'
alias ccw='claude --worktree'
alias ccc='claude --dangerously-skip-permissions'
alias cccw='claude --dangerously-skip-permissions --worktree'
alias cco5='claude --model claude-opus-4-5'
alias cco6='claude --model claude-opus-4-6'
alias cco7='claude --model claude-opus-4-7'
alias cco8='claude --model claude-opus-4-8'
alias ccs5='claude --model claude-sonnet-4-5'
alias ccs6='claude --model claude-sonnet-4-6'
alias ccwo5='claude --worktree --model claude-opus-4-5'
alias ccwo6='claude --worktree --model claude-opus-4-6'
alias ccwo7='claude --worktree --model claude-opus-4-7'
alias ccwo8='claude --worktree --model claude-opus-4-8'
alias ccws5='claude --worktree --model claude-sonnet-4-5'
alias ccws6='claude --worktree --model claude-sonnet-4-6'
alias ccco5='claude --dangerously-skip-permissions --model claude-opus-4-5'
alias ccco6='claude --dangerously-skip-permissions --model claude-opus-4-6'
alias ccco7='claude --dangerously-skip-permissions --model claude-opus-4-7'
alias ccco8='claude --dangerously-skip-permissions --model claude-opus-4-8'
alias cccs5='claude --dangerously-skip-permissions --model claude-sonnet-4-5'
alias cccs6='claude --dangerously-skip-permissions --model claude-sonnet-4-6'
alias cccwo5='claude --dangerously-skip-permissions --worktree --model claude-opus-4-5'
alias cccwo6='claude --dangerously-skip-permissions --worktree --model claude-opus-4-6'
alias cccwo7='claude --dangerously-skip-permissions --worktree --model claude-opus-4-7'
alias cccwo8='claude --dangerously-skip-permissions --worktree --model claude-opus-4-8'
alias cccws5='claude --dangerously-skip-permissions --worktree --model claude-sonnet-4-5'
alias cccws6='claude --dangerously-skip-permissions --worktree --model claude-sonnet-4-6'
alias oo='opencode'
alias ooo='opencode --auto'
alias ooz2='opencode -m zai/glm-5.2'
alias ooz1='opencode -m zai/glm-5.1'
alias oooz2='opencode --auto -m zai/glm-5.2'
alias oooz1='opencode --auto -m zai/glm-5.1'
alias timer='echo "Timer started. Stop with Ctrl+D." && date && time cat && date'
alias myip='curl -s ifconfig.me'
alias setgitperms='find /srv -maxdepth 2 -name ".git" -type d | xargs -I{} git -C {}/../ config core.sharedRepository group'
alias aliases='grep -E "^\s*alias " ~/.zshrc'

# ssh rápido a las VMs
if [ -z "$SSH_CONNECTION" ] && [ -f ~/.ssh/config ]; then
  for _h in $(awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) print $i }' ~/.ssh/config | grep -E '^t-dmi-[a-z]$'); do
    alias "t${_h#t-dmi-}=ssh $_h"
  done
  unset _h
fi

# notes
note() { echo "$(date +%F) $*" >>~/notes.md; }
todo() { echo "$(date +%F) [ ] $*" >>~/notes.md; }
notes() { cat ~/notes.md; }

# util fns
clone() { # clone username reponame
  git clone "git@github.com:$1/$2.git"
}
tarscp() { #  tarscp sourcedir destdir port?
  local src="${1%/}"
  local dest="$2"
  local port="${3:-2121}"
  local host="${dest%%:*}"
  local path="${dest##*:}"

  tar czf - "$src" | ssh -p "$port" "$host" "cd '$path' && tar xzf -"
}
serve() { # serve port? dir?
  python3 -m http.server "${1:-5173}" -d "${2:-.}"
}
#mkdir -p && cd
mkcd() { mkdir -p "$1" && cd "$1"; }
# extract
ex() {
  for f in "$@"; do
    case "$f" in
    *.tar.gz | *.tgz) tar xzf "$f" ;;
    *.tar.bz2) tar xjf "$f" ;;
    *.tar.xz) tar xJf "$f" ;;
    *.tar) tar xf "$f" ;;
    *.zip) unzip "$f" ;;
    *.gz) gunzip "$f" ;;
    *.7z) 7z x "$f" ;;
    *.rar) unrar x "$f" ;;
    *) echo "ex: unknown format '$f'" ;;
    esac
  done
}

# PulseAudio over SSH
if [ -n "$SSH_CONNECTION" ]; then
  export PULSE_SERVER=tcp:localhost:4713
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export PATH="$HOME/.grok/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
if command -v go &>/dev/null; then
  export PATH=$PATH:$(go env GOPATH)/bin
fi

# Auto-unlock gnome-keyring for ProtonVPN over SSH
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
  eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
  export GNOME_KEYRING_CONTROL
fi

# fecha en formato uruguayo
if [ -d "$HOME/.local/share/locale/es_UY.UTF-8" ]; then
  export LOCPATH="$HOME/.local/share/locale" LC_TIME="es_UY.UTF-8"
fi

# zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

# fzf - Ctrl+R / Ctrl+T / Alt+C
if command -v fzf &>/dev/null; then
  if command -v fdfind &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --style=numbers --line-range=:200 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"
  source <(fzf --zsh)
fi

# bat (Debian lo llama batcat)
if command -v batcat &>/dev/null; then
  alias bat='batcat'
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi

# direnv
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# starship prompt - siempre al final, después de Oh My Zsh
if command -v starship &>/dev/null; then
  export STARSHIP_CONFIG=~/.config/starship.toml
  eval "$(starship init zsh)"
fi
