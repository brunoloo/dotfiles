#!/usr/bin/env bash
# Terminal tools that require non-apt installation (starship, eza)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "terminal"

# Install neovim >= 0.11.2 from GitHub releases (Debian repos ship 0.10.x)
NVIM_REQUIRED="0.11.2"
install_nvim=false

if command_exists nvim; then
  current_nvim=$(nvim --version | head -1 | grep -oP 'v\K[\d.]+')
  if [ "$(printf '%s\n' "$NVIM_REQUIRED" "$current_nvim" | sort -V | head -1)" = "$NVIM_REQUIRED" ]; then
    log_success "neovim $current_nvim is already installed (>= $NVIM_REQUIRED)"
  else
    log_info "neovim $current_nvim is too old (need >= $NVIM_REQUIRED)"
    install_nvim=true
  fi
else
  install_nvim=true
fi

if [ "$install_nvim" = true ]; then
  log_info "Installing neovim $NVIM_REQUIRED from GitHub releases..."
  curl -Lo /tmp/nvim-linux-x86_64.tar.gz "https://github.com/neovim/neovim/releases/download/v${NVIM_REQUIRED}/nvim-linux-x86_64.tar.gz"
  sudo tar -xzf /tmp/nvim-linux-x86_64.tar.gz -C /usr/local --strip-components=1
  rm /tmp/nvim-linux-x86_64.tar.gz
  if command_exists nvim; then
    log_success "neovim $(nvim --version | head -1 | grep -oP 'v\K[\d.]+') installed"
  else
    log_error "neovim installation failed"
  fi
fi

# Install starship prompt
if command_exists starship; then
  log_success "starship is already installed"
else
  log_info "Installing starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  if command_exists starship; then
    log_success "starship installed"
  else
    log_error "starship installation failed"
  fi
fi

# Ensure eza apt repository is configured (keyring + sources list)
if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
  log_info "Setting up eza apt repository..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
fi

# Install eza from gierens apt repository
if command_exists eza; then
  log_success "eza is already installed"
else
  log_info "Installing eza..."
  sudo apt update
  sudo apt install -y eza
  if command_exists eza; then
    log_success "eza installed"
  else
    log_error "eza installation failed"
  fi
fi

# Install GitHub CLI from official apt repository
if command_exists gh; then
  log_success "gh is already installed"
else
  log_info "Installing GitHub CLI..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
  if command_exists gh; then
    log_success "gh installed: $(gh --version | head -1)"
  else
    log_error "gh installation failed"
  fi
fi

# Install Node.js via nvm
if command_exists node; then
  log_success "node is already installed: $(node -v)"
else
  log_info "Installing nvm + Node.js..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  # Load nvm without restarting shell
  export NVM_DIR="$HOME/.nvm"
  \. "$NVM_DIR/nvm.sh"
  nvm install 24
  if command_exists node; then
    log_success "node $(node -v) installed (npm $(npm -v))"
  else
    log_error "node installation failed"
  fi
fi

# Install zoxide (smarter cd)
if command_exists zoxide; then
  log_success "zoxide is already installed"
else
  log_info "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  if command_exists zoxide; then
    log_success "zoxide installed"
  else
    log_error "zoxide installation failed"
  fi
fi

end_timer "success"
