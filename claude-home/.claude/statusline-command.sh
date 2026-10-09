#!/bin/bash
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "."')
percent_raw=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
percent=${percent_raw%%.*}
percent=${percent:-0}

# Git info
cd "$cwd" 2>/dev/null
branch=$(git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* //')
dirty=$([[ -n "$(git status --porcelain 2>/dev/null)" ]] && echo "*")

# Progress bar (10 chars wide)
filled=$((percent / 10))
empty=$((10 - filled))
bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Color based on usage: green <50%, yellow 50-80%, red >80%
if [ "$percent" -lt 50 ]; then
  bar_color="\033[32m"  # green
elif [ "$percent" -lt 80 ]; then
  bar_color="\033[33m"  # yellow
else
  bar_color="\033[31m"  # red
fi

# Output: host | dir | git | context bar
printf "\033[1;35m%s\033[0m " "$(hostname)"
printf "\033[1;34m%s\033[0m" "$cwd"
[[ -n "$branch" ]] && printf " \033[1;33m %s%s\033[0m" "$branch" "$dirty"
printf " ${bar_color}[%s] %d%%\033[0m" "$bar" "$percent"
