#!/usr/bin/env bash
# Git status indicator for tmux status bar
# Shows current branch and clean/dirty status

# Get current pane's working directory
PANE_PATH=$(tmux display-message -p "#{pane_current_path}")

# Change to that directory
cd "$PANE_PATH" 2>/dev/null || exit 0

# Check if we're in a git repo
if ! git rev-parse --git-dir &>/dev/null; then
    exit 0
fi

# Get current branch
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    STATUS="✗"
    COLOR="red"
else
    STATUS="✓"
    COLOR="green"
fi

# Output formatted for tmux status bar
echo "#[fg=${COLOR}] ${BRANCH} ${STATUS}#[default]"
