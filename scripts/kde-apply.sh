#!/usr/bin/env bash
# Aplica la config de KDE Plasma 6 (Konsole, tema WhiteSur, KWin, Krohnkite,
# escritorios, atajos, panel, fondo y KDE Connect).
#
# KDE reescribe sus *rc en runtime, así que no se copian con stow: se aplican con
# kwriteconfig6 y D-Bus. Es idempotente: se puede volver a correr cuando quieras.
# Lo que necesita una sesión de Plasma abierta (D-Bus) se avisa al final.
#
# Requiere haber corrido antes scripts/packages/desktop.sh (WhiteSur, Krohnkite,
# fuente) y desplegado el paquete stow "kde" (perfil de Konsole, fondo).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command_exists kwriteconfig6; then
  log_warning "kwriteconfig6 not found (KDE Plasma 6 not installed): nothing to apply"
  exit 0
fi

PENDING=()
in_session() { qdbus6 org.kde.KWin >/dev/null 2>&1; }
kw() { kwriteconfig6 "$@"; }

# ----------------------------------------------------------------------------
# Konsole: perfil Dracula por defecto, interfaz limpia y scrollbar roja (Fusion)
# ----------------------------------------------------------------------------
apply_konsole() {
  log_info "Konsole..."
  kw --file konsolerc --group "Desktop Entry" --key DefaultProfile Dracula.profile
  kw --file konsolerc --group UiSettings --key ColorScheme WhiteSurDarkRed
  kw --file konsolerc --group KonsoleWindow --key ShowMenuBarByDefault false
  kw --file konsolerc --group TabBar --key TabBarVisibility AlwaysHideTabBar

  # El atajo del sistema y el menú lanzan "konsole": el wrapper ~/.local/bin/konsole
  # (paquete kde) le pone Fusion. Este .desktop hace lo mismo para el lanzador del menú.
  local src=/usr/share/applications/org.kde.konsole.desktop
  local dst="$HOME/.local/share/applications/org.kde.konsole.desktop"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    sed 's|^Exec=konsole\( --new-tab\)\?$|Exec=env QT_STYLE_OVERRIDE=Fusion konsole\1|' "$src" >"$dst"
    command_exists kbuildsycoca6 && kbuildsycoca6 >/dev/null 2>&1 || true
  fi
  log_success "Konsole: Dracula (opacidad 0.6 + blur), scrollbar roja"
}

# ----------------------------------------------------------------------------
# Tema WhiteSur: colores, estilo de Plasma, íconos, cursor y decoración de ventanas
# ----------------------------------------------------------------------------
apply_theme() {
  log_info "Tema WhiteSur..."
  if [ ! -f "$HOME/.local/share/color-schemes/WhiteSurDark.colors" ]; then
    log_warning "WhiteSur is not installed (run scripts/packages/desktop.sh first): theme skipped"
    return 0
  fi

  command_exists plasma-apply-colorscheme && plasma-apply-colorscheme WhiteSurDark >/dev/null 2>&1 || true
  command_exists plasma-apply-desktoptheme && plasma-apply-desktoptheme WhiteSur-dark >/dev/null 2>&1 || true
  kw --file kdeglobals --group Icons --key Theme WhiteSur-dark
  # plasma-apply-cursortheme no reconoce este tema: se escribe directo (se ve al reiniciar sesión)
  kw --file kcminputrc --group Mouse --key cursorTheme WhiteSur-cursors
  kw --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
  kw --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__WhiteSur-dark
  kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
  kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX

  # Avisar del cambio de íconos a las apps abiertas
  dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:4 int32:0 2>/dev/null || true
  log_success "WhiteSur: colores, Plasma, íconos, decoración (botones a la derecha), cursor"
}

# ----------------------------------------------------------------------------
# KWin: Krohnkite (layout Columns por defecto) y efectos
# ----------------------------------------------------------------------------
apply_kwin() {
  log_info "KWin..."
  kw --file kwinrc --group Plugins --key krohnkiteEnabled true
  kw --file kwinrc --group Plugins --key magiclampEnabled true
  kw --file kwinrc --group Plugins --key squashEnabled false
  kw --file kwinrc --group Effect-magiclamp --key AnimationDuration 400
  kw --file kwinrc --group Tiling --key padding 4
  # Intensidad del blur: es global de KWin (afecta a todo lo translúcido), no de Konsole
  kw --file kwinrc --group Effect-blur --key BlurStrength 2

  # El layout con el orden más bajo es el que usa Krohnkite por defecto: Columns primero
  local order=(columns tile threeColumn monocle spiral quarter stacked spread floating stair binaryTree cascade)
  local i=1 name
  for name in "${order[@]}"; do
    kw --file kwinrc --group Script-krohnkite --key "${name}LayoutOrder" "$i"
    i=$((i + 1))
  done
  kw --file kwinrc --group Script-krohnkite --key enableColumnsLayout true

  if in_session; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect magiclamp >/dev/null 2>&1
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect squash >/dev/null 2>&1
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect blur >/dev/null 2>&1
    log_success "KWin: Krohnkite (Columns), Magic Lamp 400 ms, sin Squash, blur suave"
  else
    PENDING+=("KWin: efectos y Krohnkite (la config quedó escrita; se carga al iniciar sesión)")
  fi
}

# ----------------------------------------------------------------------------
# Escritorios virtuales: 2
# ----------------------------------------------------------------------------
apply_desktops() {
  log_info "Escritorios virtuales..."
  if ! in_session; then
    PENDING+=("Escritorios virtuales: necesitan una sesión de Plasma abierta")
    return 0
  fi
  local vdm="org.kde.KWin.VirtualDesktopManager" count
  count=$(qdbus6 org.kde.KWin /VirtualDesktopManager "$vdm.count")
  while [ "$count" -lt 2 ]; do
    qdbus6 org.kde.KWin /VirtualDesktopManager "$vdm.createDesktop" "$count" "Desktop $((count + 1))" >/dev/null
    count=$((count + 1))
  done
  log_success "Escritorios virtuales: $count (nunca se borran los que ya hay)"
}

# ----------------------------------------------------------------------------
# Atajos globales. Se asignan por D-Bus al servicio en vivo: editar
# kglobalshortcutsrc a mano no sirve, el servicio lo reescribe desde su memoria.
#   Qt: Ctrl=0x04000000 Alt=0x08000000 Meta=0x10000000 | Left=0x01000012 Right=0x01000014
# ----------------------------------------------------------------------------
set_shortcut() { # set_shortcut componente acción nombre-componente nombre-acción "[teclas]"
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setShortcut "['$1','$2','$3','$4']" "$5" 6 >/dev/null 2>&1
}

apply_shortcuts() {
  log_info "Atajos..."
  if ! in_session || ! command_exists gdbus; then
    PENDING+=("Atajos: necesitan una sesión de Plasma abierta (volvé a correr scripts/kde-apply.sh)")
    return 0
  fi
  # Escritorio anterior/siguiente: Meta+Ctrl+flecha (original) y Ctrl+Alt+flecha
  set_shortcut kwin "Switch One Desktop to the Left" KWin "Switch One Desktop to the Left" "[352321554, 218103826]"
  set_shortcut kwin "Switch One Desktop to the Right" KWin "Switch One Desktop to the Right" "[352321556, 218103828]"
  # Bloquear sesión pasa a Ctrl+Alt+L (más la tecla de bloqueo); libera Meta+L para Krohnkite
  set_shortcut ksmserver "Lock Session" ksmserver "Lock Session" "[201326668, 16777402]"
  # Krohnkite: foco a la derecha en Meta+L (el resto de sus atajos son los de fábrica)
  set_shortcut kwin KrohnkiteFocusRight KWin "Krohnkite: Focus Right" "[268435532]"
  log_success "Atajos: Ctrl+Alt+←/→ (escritorios), Ctrl+Alt+L (bloqueo), Meta+L (foco derecha)"
}

# ----------------------------------------------------------------------------
# Panel (barra inferior) y fondo de pantalla
# ----------------------------------------------------------------------------
apply_panel() {
  log_info "Panel..."
  if ! in_session; then
    PENDING+=("Panel: necesita una sesión de Plasma abierta")
    return 0
  fi
  local out
  out=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    "$(cat "$SCRIPT_DIR/kde/panel.js")" 2>&1 | grep -v QThread)
  log_success "Panel: $out"
}

apply_wallpaper() {
  log_info "Fondo de pantalla..."
  local img="$HOME/.local/share/wallpapers/wallpaper.png"
  if [ ! -f "$img" ]; then
    log_warning "wallpaper not found at $img (deploy the stow package 'kde' first)"
  elif command_exists plasma-apply-wallpaperimage && in_session; then
    plasma-apply-wallpaperimage "$img" >/dev/null 2>&1
    log_success "Fondo de pantalla: $img"
  else
    PENDING+=("Fondo de pantalla: necesita una sesión de Plasma abierta")
  fi
}

# ----------------------------------------------------------------------------
# KDE Connect: desactivado (ahorra RAM; se reactiva con kdeconnect-activar)
# ----------------------------------------------------------------------------
apply_kdeconnect() {
  if [ -x "$HOME/.local/bin/kdeconnect-desactivar" ] && [ -x /usr/bin/kdeconnectd ]; then
    log_info "KDE Connect..."
    "$HOME/.local/bin/kdeconnect-desactivar" >/dev/null 2>&1
    log_success "KDE Connect desactivado (reactivar: ~/.local/bin/kdeconnect-activar)"
  fi
}

apply_konsole
apply_theme
apply_kwin
apply_desktops
apply_shortcuts
apply_panel
apply_wallpaper
apply_kdeconnect

echo ""
if [ ${#PENDING[@]} -gt 0 ]; then
  log_warning "Pendiente (necesita sesión de Plasma o reiniciar sesión):"
  printf '    - %s\n' "${PENDING[@]}"
fi
log_info "Para ver el cursor WhiteSur y el cambio completo de tema: cerrá sesión y volvé a entrar."
