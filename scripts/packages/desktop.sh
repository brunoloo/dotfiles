#!/usr/bin/env bash
# Piezas del escritorio KDE que no vienen en apt: fuente Nerd Font,
# Krohnkite (tiling) y el tema WhiteSur (colores, íconos, cursor, Plasma/KWin)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

start_timer "desktop"

# Versiones fijadas para que la instalación sea reproducible
NERD_FONTS_VERSION="v3.5.1"
KROHNKITE_VERSION="0.9.9.2"
WHITESUR_KDE_SHA="cf4df59ce91004f7ea39358b1b8ff917d5c329f7"
WHITESUR_ICONS_SHA="73d8040da51a9ed74e47c7366e7e9ff437601a5c"
WHITESUR_CURSORS_SHA="e190baf618ed95ee217d2fd45589bd309b37672b"

if ! command_exists kpackagetool6; then
  log_warning "KDE Plasma 6 not detected (no kpackagetool6): skipping desktop pieces"
  end_timer "skipped"
  exit 0
fi

install_packages curl unzip git fontconfig

# JetBrainsMono Nerd Font (solo los .ttf que usa Konsole)
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNF"
if ls "$FONT_DIR"/JetBrainsMonoNerdFont-*.ttf &>/dev/null; then
  log_success "JetBrainsMono Nerd Font is already installed"
else
  log_info "Installing JetBrainsMono Nerd Font $NERD_FONTS_VERSION..."
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/JetBrainsMono.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_VERSION/JetBrainsMono.zip"; then
    mkdir -p "$FONT_DIR"
    unzip -oq "$tmp/JetBrainsMono.zip" 'JetBrainsMonoNerdFont-*.ttf' -d "$FONT_DIR"
    fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
    log_success "JetBrainsMono Nerd Font installed"
  else
    log_error "could not download JetBrainsMono Nerd Font"
  fi
  rm -rf "$tmp"
fi

# Krohnkite (tiling para KWin 6, sucesor de Bismuth)
if kpackagetool6 --type=KWin/Script --show krohnkite &>/dev/null; then
  log_success "Krohnkite is already installed"
else
  log_info "Installing Krohnkite $KROHNKITE_VERSION..."
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/krohnkite.kwinscript" \
    "https://github.com/anametologin/krohnkite/releases/download/$KROHNKITE_VERSION/krohnkite.kwinscript" &&
    kpackagetool6 --type=KWin/Script --install "$tmp/krohnkite.kwinscript"; then
    log_success "Krohnkite installed"
  else
    log_error "Krohnkite installation failed"
  fi
  rm -rf "$tmp"
fi

# WhiteSur (macOS): se instala en ~/.local/share y se aplica en scripts/kde-apply.sh
if [ -d "$HOME/.local/share/icons/WhiteSur-dark" ] &&
  [ -d "$HOME/.local/share/icons/WhiteSur-cursors" ] &&
  [ -f "$HOME/.local/share/color-schemes/WhiteSurDark.colors" ]; then
  log_success "WhiteSur theme is already installed"
else
  log_info "Installing WhiteSur theme (colors, icons, cursors)..."
  tmp="$(mktemp -d)"
  clone_pinned https://github.com/vinceliuice/WhiteSur-kde.git "$tmp/WhiteSur-kde" "$WHITESUR_KDE_SHA"
  clone_pinned https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp/WhiteSur-icon-theme" "$WHITESUR_ICONS_SHA"
  clone_pinned https://github.com/vinceliuice/WhiteSur-cursors.git "$tmp/WhiteSur-cursors" "$WHITESUR_CURSORS_SHA"
  (cd "$tmp/WhiteSur-kde" && ./install.sh -c dark)
  (cd "$tmp/WhiteSur-icon-theme" && ./install.sh -t default)
  (cd "$tmp/WhiteSur-cursors" && ./install.sh)
  rm -rf "$tmp"
  log_success "WhiteSur installed"
fi

end_timer
