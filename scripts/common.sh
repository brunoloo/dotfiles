#!/usr/bin/env bash
# Common functions for installation scripts
# Source this file from other scripts: source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

# color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# logging
log_info() {
  echo -e "${BLUE}→${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

# check if dpkg package is installed
is_installed() {
  dpkg -s "$1" &>/dev/null
}

# check if command exists in PATH
command_exists() {
  command -v "$1" &>/dev/null
}

# install apt packages with checking
install_packages() {
  local packages=("$@")
  local to_install=()

  for pkg in "${packages[@]}"; do
    if is_installed "$pkg"; then
      log_success "$pkg is already installed"
    else
      log_info "$pkg will be installed"
      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    echo ""
    log_info "Installing ${#to_install[@]} package(s)..."
    if sudo apt install -y "${to_install[@]}"; then
      log_success "Package installation complete!"
    else
      log_error "Package installation failed"
      return 1
    fi
  else
    log_success "All packages already installed"
  fi

  return 0
}

# yes/no qs — default is No (just press Enter)
ask_yes_no() {
  local prompt="$1"
  local response

  while true; do
    read -p "$prompt (y/N): " response
    case "$response" in
    [Yy]*) return 0 ;;
    [Nn]*|"") return 1 ;;
    *) echo "Please answer y or n." ;;
    esac
  done
}

# configure git identity
configure_git() {
  log_info "Git identity configuration"
  echo ""

  #check for existing config
  local current_name=$(git config --global user.name 2>/dev/null)
  local current_email=$(git config --global user.email 2>/dev/null)

  if [[ -n $current_name ]] && [[ -n $current_email ]]; then
    log_success "Git is already configured:"
    echo "  Name:  $current_name"
    echo "  Email: $current_email"
    echo ""
    if ! ask_yes_no "Reconfigure git identity?"; then
      return 0
    fi
    echo ""
  fi

  #prompt name
  local git_name
  while true; do
    read -p "Enter your git user.name: " git_name
    if [[ -n $git_name ]]; then
      break
    else
      log_warning "Name cannot be empty"
    fi
  done

  #prompt email
  local git_email
  while true; do
    read -p "Enter your git user.email: " git_email
    if [[ -n $git_email ]]; then
      break
    else
      log_warning "Email cannot be empty"
    fi
  done

  # set
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"

  log_success "Git identity configured:"
  echo "  Name:  $git_name"
  echo "  Email: $git_email"
  echo ""
}

# timer functions for tracking
TIMER_START_TIME=""
TIMER_SCRIPT_NAME=""
TIMER_LOG_FILE="$HOME/.dotfiles-install.log"

# start timing an installation script
start_timer() {
  TIMER_SCRIPT_NAME="$1"
  TIMER_START_TIME=$(date +%s)

  # create log file with header if it not exists
  if [[ ! -f "$TIMER_LOG_FILE" ]]; then
    echo "Script,Start,End,Duration_Seconds,Status" >"$TIMER_LOG_FILE"
  fi
}

# end timing and log results to csv
end_timer() {
  local status="${1:-success}"
  local end_time=$(date +%s)
  local duration=$((end_time - TIMER_START_TIME))

  local start_timestamp=$(date -d "@$TIMER_START_TIME" '+%Y-%m-%d %H:%M:%S')
  local end_timestamp=$(date -d "@$end_time" '+%Y-%m-%d %H:%M:%S')

  # append csv row
  echo "$TIMER_SCRIPT_NAME,$start_timestamp,$end_timestamp,$duration,$status" >>"$TIMER_LOG_FILE"

  log_success "Timing: $TIMER_SCRIPT_NAME completed in ${duration}s (logged to ~/.dotfiles-install.log)"
}
