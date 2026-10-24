# dotfiles

🇺🇸 [English](README.md) · 🇺🇾 **Español**

Mi entorno de trabajo en Linux (Debian + KDE Plasma): terminal, shell, Neovim, atajos y un layout de escritorio que se arma con una tecla. Todo se instala con un solo comando.

> **Créditos:** la base de este repo (bash, tmux, Neovim, starship, hooks de Claude Code) es la configuración de mi compañero de trabajo [Salvador Borit](https://github.com/salvaborit) ([dotfiles-debian](https://github.com/salvaborit/dotfiles-debian)), publicada acá con su permiso. Encima le agregué mis cosas: el escritorio KDE, `setup-init`, alias, historial, fzf/bat/direnv y más.

## Instalación

En un Debian recién instalado:

```bash
git clone https://github.com/brunoloo/dotfiles.git ~/dotfiles
~/dotfiles/install
```

El instalador:

1. Instala los paquetes (apt, Neovim, starship, eza, zsh + Oh My Zsh, Docker, etc.) y las apps (Brave, VirtualBox, VS Code, Wireshark, Node.js). Pide `sudo`.
2. Crea symlinks de cada config a tu `$HOME` con [GNU stow](https://www.gnu.org/software/stow/). Si ya tenías un archivo propio, primero lo mueve a `~/.dotfiles-backup-<fecha>/`.
3. Si detecta KDE, instala la fuente JetBrainsMono Nerd Font, Krohnkite y el tema WhiteSur, y aplica todo el escritorio con `scripts/kde-apply.sh` (ver abajo). El cursor y los atajos terminan de aplicarse al volver a iniciar sesión.

Opciones:

```bash
~/dotfiles/install --skip-packages     # solo la config, sin apt ni sudo
~/dotfiles/install --skip-desktop      # sin WhiteSur/Krohnkite/fuente ni config de KDE
~/dotfiles/install --skip-apps         # sin Brave, VirtualBox, Wireshark, VS Code, Node.js
~/dotfiles/install --ssh-port 2121     # además configura sshd + firewall (servidores)
```

Se puede correr las veces que quieras: lo que ya está instalado lo saltea.

Como los archivos son symlinks, editar `~/.bashrc` es editar el repo: después `git commit` + `git push` y el cambio queda guardado para la próxima máquina.

## Qué trae

### Escritorio KDE

| | |
|---|---|
| **`setup-init`** / ícono **setup_init** / **`Meta+Alt+T`** | Abre 3 Konsole y las ubica en el monitor externo: una en cada costado (45% del ancho, toda la altura) y la tercera centrada detrás; un click en la franja del medio la trae al frente. Funciona en Wayland usando el scripting de KWin. El monitor y el ancho se cambian arriba del todo en el script (`OUTPUT`, `WIDTH_PCT`). |
| **Konsole** | Perfil y esquema `Dracula`: opacidad 0.6 con blur y un desenfoque global suave (BlurStrength=2), fuente JetBrainsMono Nerd Font, zsh, sin barra de menú ni de pestañas. Scrollbar roja: Konsole arranca con el estilo Fusion (wrapper `~/.local/bin/konsole`), porque con Breeze la scrollbar toma el color del texto de la terminal. |
| **Tema** | [WhiteSur](https://github.com/vinceliuice/WhiteSur-kde) (estilo macOS): colores, estilo de Plasma, íconos, cursor y decoración de ventanas (botones a la derecha). Se instala desde el repo oficial, fijado a un commit. |
| **Tiling** | [Krohnkite](https://github.com/anametologin/krohnkite) con `Columns` como layout por defecto. `Meta+H/J/K/L` foco, `Meta+Shift+H/J/K/L` mover, `Meta+Ctrl+H/J/K/L` redimensionar, `Meta+F` flotar, `Meta+\` siguiente layout. |
| **Panel** | Una sola barra inferior a lo ancho: menú, escritorios virtuales numerados, íconos de apps centrados, bandeja y reloj `dd/MM/yyyy`. 2 escritorios virtuales. |
| **Atajos** | `Ctrl+Alt+←/→` escritorio anterior/siguiente, `Ctrl+Alt+L` bloquear sesión, `Meta+L` foco a la derecha de Krohnkite. |
| **Efectos** | Magic Lamp (400 ms) en lugar de Squash al minimizar. |
| **Fondo** | `kde/.local/share/wallpapers/wallpaper.png`. |
| **KDE Connect** | Desactivado para ahorrar RAM. Se reactiva con `kdeconnect-activar` ([docs](docs/reactivar-kdeconnect.md)). |

KDE reescribe sus propios `*rc` en runtime, por eso no van como symlinks: `scripts/kde-apply.sh` los aplica con `kwriteconfig6` y D-Bus (el panel está en `scripts/kde/panel.js`). Es idempotente y se puede volver a correr cuando quieras, por ejemplo ya dentro de Plasma si el instalador corrió sin sesión.

El ícono del escritorio es una copia normal: se le puede cambiar el nombre o el ícono desde click derecho → Propiedades.

### Shell (zsh, con bash de respaldo)

- **zsh** con [Oh My Zsh](https://ohmyz.sh) y `zsh-syntax-highlighting` (sin autosugerencias). Paleta Dracula fija: verde comandos válidos, rosa palabras reservadas y operadores, naranja opciones, cian rutas existentes, amarillo strings, violeta variables, rojo errores.
- **Prompt** con [starship](https://starship.rs): cápsulas pastel de colores (casa, carpeta, rama de git y estado, solo cuando hay cambios), con íconos Nerd Font.
- **Historial** enorme, con fecha y compartido entre todas las terminales abiertas.
- **fzf:** `Ctrl+R` busca en el historial, `Ctrl+T` elige un archivo, `Alt+C` salta a una carpeta.
- **`.inputrc`:** autocompletado sin distinguir mayúsculas; ↑/↓ buscan en el historial lo que empezaste a escribir.
- **zoxide:** `cd` aprende tus carpetas frecuentes (`cd proy` → `~/trabajo/proyecto`).
- **bat**, **eza**, **direnv**, **bash-completion** y fechas en formato uruguayo.

Alias y funciones más usados:

| Comando | Qué hace |
|---|---|
| `ta`, `tb`, `tc`… | `ssh t-dmi-a`, `ssh t-dmi-b`… Se arman solos con cada `Host t-dmi-X` de `~/.ssh/config` y solo existen en la PC, no dentro de una sesión ssh. |
| `mkcd dir` | crea la carpeta y entra |
| `ex archivo` | descomprime cualquier formato (tar, zip, 7z, rar…) |
| `ls`, `ll`, `lt` | listados con eza (íconos, árbol, estado de git) |
| `g`, `gits`, `gitd`, `gitac "msg"`, `gg` | git y lazygit |
| `d`, `dc`, `dcu`, `dcud`, `dcd`, `dp`… | docker y docker compose |
| `n` | nvim |
| `cc`, `ccc`, `ccw` | Claude Code (normal, sin permisos, en worktree) |
| `serve [puerto]` | servidor HTTP en la carpeta actual |
| `note`, `todo`, `notes` | notas rápidas en `~/notes.md` |
| `q`, `c` | exit, clear |

`aliases` muestra la lista completa.

### Git

- **[delta](https://github.com/dandavid/delta)** como pager: `git diff`, `git log -p` y `git show` con resaltado de sintaxis y números de línea; `n`/`N` saltan entre archivos.
- **lazygit** (`gg`) muestra los diffs con delta.
- Conflictos de merge en estilo `zdiff3` (muestra también la versión original).

Esto va en `~/.config/git/config`. Tu nombre, mail y credenciales quedan en `~/.gitconfig`, que no está en el repo: el instalador te los pregunta.

### Neovim

Setup completo basado en [LazyVim](https://www.lazyvim.org). Los plugins se descargan solos la primera vez que abrís `nvim`.

### Otros

- **Claude Code:** statusline y sonidos al empezar, terminar o pedir permiso.
- **opencode:** atajos y los mismos sonidos.
- **ProtonVPN:** `vpn-up`, `vpn-down`, `vpn-status` ([docs](docs/protonvpn-debian.md)).

## Estructura

Cada carpeta es un paquete de stow que replica la estructura de `$HOME`:

```
shell/          .bashrc (respaldo), .inputrc, .vimrc, starship.toml
zsh/            .zshrc (Oh My Zsh, paleta Dracula, alias)
neovim/         ~/.config/nvim
kde/            Konsole (perfil y esquema Dracula, wrapper Fusion), esquema rojo, fondo, setup-init
scripts-local/  scripts de VPN y de KDE Connect en ~/.local/bin
claude-home/    statusline y sonidos de Claude Code
opencode/       config de opencode
git/            delta (~/.config/git/config) y lazygit
local/          lista de palabras para nombres de sesiones
scripts/        funciones del instalador y paquetes
```
