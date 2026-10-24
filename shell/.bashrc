# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# History - large, timestamped, shared live across all open terminals
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups # no dups; a leading space skips saving
HISTTIMEFORMAT='%F %T  '
HISTIGNORE='ls:ll:c:clear:q:exit:pwd'
shopt -s histappend # append to the file instead of overwriting it
shopt -s cmdhist    # multi-line commands saved as one entry
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

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

# list all aliases defined in .bashrc
alias aliases='grep -E "^\s*alias " ~/.bashrc'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# editor
export EDITOR='nvim'
alias n='nvim'

# show file system structure trees
alias dtree='tree -C -d --dirsfirst'
alias ftree='tree -C -L 5 --dirsfirst'

# claude code
alias cc='claude'
alias ccw='claude --worktree'
alias ccc='claude --dangerously-skip-permissions'
alias cccw='claude --dangerously-skip-permissions --worktree'
# model variants: o=opus, s=sonnet, 5=4.5, 6=4.6, 7=4.7, 8=4.8
alias cco5='claude --model claude-opus-4-5'
alias cco6='claude --model claude-opus-4-6'
alias cco7='claude --model claude-opus-4-7'
alias cco8='claude --model claude-opus-4-8'
alias ccs5='claude --model claude-sonnet-4-5'
alias ccs6='claude --model claude-sonnet-4-6'
# worktree + model
alias ccwo5='claude --worktree --model claude-opus-4-5'
alias ccwo6='claude --worktree --model claude-opus-4-6'
alias ccwo7='claude --worktree --model claude-opus-4-7'
alias ccwo8='claude --worktree --model claude-opus-4-8'
alias ccws5='claude --worktree --model claude-sonnet-4-5'
alias ccws6='claude --worktree --model claude-sonnet-4-6'
# dangerously-skip-permissions + model
alias ccco5='claude --dangerously-skip-permissions --model claude-opus-4-5'
alias ccco6='claude --dangerously-skip-permissions --model claude-opus-4-6'
alias ccco7='claude --dangerously-skip-permissions --model claude-opus-4-7'
alias ccco8='claude --dangerously-skip-permissions --model claude-opus-4-8'
alias cccs5='claude --dangerously-skip-permissions --model claude-sonnet-4-5'
alias cccs6='claude --dangerously-skip-permissions --model claude-sonnet-4-6'
# dangerously-skip-permissions + worktree + model
alias cccwo5='claude --dangerously-skip-permissions --worktree --model claude-opus-4-5'
alias cccwo6='claude --dangerously-skip-permissions --worktree --model claude-opus-4-6'
alias cccwo7='claude --dangerously-skip-permissions --worktree --model claude-opus-4-7'
alias cccwo8='claude --dangerously-skip-permissions --worktree --model claude-opus-4-8'
alias cccws5='claude --dangerously-skip-permissions --worktree --model claude-sonnet-4-5'
alias cccws6='claude --dangerously-skip-permissions --worktree --model claude-sonnet-4-6'

# opencode
# base aliases: oo=opencode, ooo=opencode --auto
# model variants: z1=zai/glm-5.1, z2=zai/glm-5.2 (default)
alias oo='opencode'
alias ooo='opencode --auto'
alias ooz2='opencode -m zai/glm-5.2'
alias ooz1='opencode -m zai/glm-5.1'
alias oooz2='opencode --auto -m zai/glm-5.2'
alias oooz1='opencode --auto -m zai/glm-5.1'

alias timer='echo "Timer started. Stop with Ctrl+D." && date && time cat && date'
alias myip='curl -s ifconfig.me'

# ssh rápido a las VMs (solo en la PC, no dentro de una sesión ssh):
# por cada "Host t-dmi-X" de ~/.ssh/config crea el alias tX (ta, tb, tc…)
if [ -z "$SSH_CONNECTION" ] && [ -f ~/.ssh/config ]; then
  for _h in $(awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) print $i }' ~/.ssh/config | grep -E '^t-dmi-[a-z]$'); do
    alias "t${_h#t-dmi-}=ssh $_h"
  done
  unset _h
fi

alias setgitperms='find /srv -maxdepth 2 -name ".git" -type d | xargs -I{} git -C {}/../ config core.sharedRepository group'

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

# git prompt fallback (used if starship is not installed)
parse_git_branch() {
  git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
parse_git_dirty() {
  [[ -n "$(git status --porcelain 2>/dev/null)" ]] && echo "*"
}
export PS1='\u@\h \[\033[1;34m\]\w\[\033[0m\] \[\033[1;33m\]$(parse_git_branch)$(parse_git_dirty)\[\033[0m\] \$ '

# starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
  export STARSHIP_CONFIG=~/.config/starship.toml
fi

export PATH="$HOME/.local/bin:$PATH"

# PulseAudio over SSH (works with client-side: RemoteForward 4713 localhost:4713)
if [ -n "$SSH_CONNECTION" ]; then
  export PULSE_SERVER=tcp:localhost:4713
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# richer terminal colors
export COLORTERM=truecolor

# opencode
export PATH=/home/sborit/.opencode/bin:$PATH

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
# <<< grok installer <<<

# zoxide (smarter cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash --cmd cd)"
fi

# bash-completion (Tab completes ssh hosts, git/docker/apt subcommands)
if ! shopt -oq posix && [ -z "$BASH_COMPLETION_VERSINFO" ] && [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi

# fzf - Ctrl+R history search, Ctrl+T pick file, Alt+C jump to dir
if command -v fzf &>/dev/null; then
  if command -v fdfind &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --style=numbers --line-range=:200 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"
  # fzf >= 0.48 ships its own bash integration; older Debian packages use the example scripts
  if fzf --bash &>/dev/null; then
    eval "$(fzf --bash)"
  elif [ -r /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    . /usr/share/doc/fzf/examples/key-bindings.bash
  fi
fi

# bat (Debian ships it as batcat) - cat stays untouched
if command -v batcat &>/dev/null; then
  alias bat='batcat'
  export MANPAGER="sh -c 'col -bx | batcat -l man -p'" # colored man pages
fi

# direnv - per-project env vars from .envrc
if command -v direnv &>/dev/null; then
  eval "$(direnv hook bash)"
fi
export PATH="$HOME/.local/bin:$PATH"
# go (only if installed)
if command -v go &>/dev/null; then
  export PATH=$PATH:$(go env GOPATH)/bin
fi

# Auto-unlock gnome-keyring for ProtonVPN over SSH
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
  eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
  export GNOME_KEYRING_CONTROL
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH="/home/sba/.opencode/bin:$PATH"

# fecha en formato uruguayo (día/mes/año) — locale es_UY generado en $HOME
# (bash cachea LOCPATH al arrancar: se silencia su aviso, los programas hijos sí lo usan)
if [ -d "$HOME/.local/share/locale/es_UY.UTF-8" ]; then
  { export LOCPATH="$HOME/.local/share/locale" LC_TIME="es_UY.UTF-8"; } 2>/dev/null
fi
