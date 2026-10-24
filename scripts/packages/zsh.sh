#!/usr/bin/env bash
# Zsh + Oh My Zsh + resaltado de sintaxis, y zsh como shell por defecto

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "zsh"

# Versiones fijadas (commits) para que la instalación sea reproducible
OMZ_SHA="2100c630ba4bd67bb48802c3e7da893a4fdaa1a0"
ZSH_SYNTAX_HIGHLIGHTING_SHA="e6683f20e5c38d3e5447f45845d04ddda75d0f23"

install_packages zsh git curl

clone_pinned https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" "$OMZ_SHA"
clone_pinned https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "$ZSH_SYNTAX_HIGHLIGHTING_SHA"

# zsh como shell por defecto (pide contraseña; se nota al volver a iniciar sesión)
if [ "$(getent passwd "$USER" | cut -d: -f7)" = "/usr/bin/zsh" ]; then
  log_success "zsh is already the default shell"
else
  log_info "Setting zsh as default shell..."
  sudo chsh -s /usr/bin/zsh "$USER" && log_success "Default shell: zsh (log out and in to apply)"
fi

end_timer
