# dotfiles

🇬🇧 [English](README.md) · 🇺🇾 **Español**

Mi entorno de trabajo en Linux (Debian + KDE Plasma): terminal, shell, tmux, Neovim, atajos y un layout de escritorio que se arma con una tecla. Todo se instala con un solo comando.

> **Créditos:** la base de este repo (bash, tmux, Neovim, starship, scripts de tmux, hooks de Claude Code) es la configuración de mi compañero de trabajo [Salvador Borit](https://github.com/salvaborit) ([dotfiles-debian](https://github.com/salvaborit/dotfiles-debian)), publicada acá con su permiso. Encima le agregué mis cosas: el escritorio KDE, `setup-init`, alias, historial, fzf/bat/direnv y más.

## Instalación

En un Debian recién instalado:

```bash
git clone https://github.com/brunoloo/dotfiles.git ~/dotfiles
~/dotfiles/install
```

El instalador:

1. Instala los paquetes (apt, Neovim, starship, eza, Node, Docker, etc.). Pide `sudo`.
2. Crea symlinks de cada config a tu `$HOME` con [GNU stow](https://www.gnu.org/software/stow/). Si ya tenías un archivo propio, primero lo mueve a `~/.dotfiles-backup-<fecha>/`.
3. Si detecta KDE, configura Konsole (verde sobre negro), el tema Breeze Dark, el ícono `setup_init` del escritorio y el atajo `Meta+Alt+T`. El tema y el atajo terminan de aplicarse al volver a iniciar sesión.

Opciones:

```bash
~/dotfiles/install --skip-packages     # solo la config, sin apt ni sudo
~/dotfiles/install --ssh-port 2121     # además configura sshd + firewall (servidores)
```

Se puede correr las veces que quieras: lo que ya está instalado lo saltea.

Como los archivos son symlinks, editar `~/.bashrc` es editar el repo: después `git commit` + `git push` y el cambio queda guardado para la próxima máquina.

## Qué trae

### Escritorio KDE

| | |
|---|---|
| **`setup-init`** / ícono **setup_init** / **`Meta+Alt+T`** | Abre 3 Konsole y las ubica en el monitor externo: una en cada costado (45% del ancho, toda la altura) y la tercera centrada detrás; un click en la franja del medio la trae al frente. Funciona en Wayland usando el scripting de KWin. El monitor y el ancho se cambian arriba del todo en el script (`OUTPUT`, `WIDTH_PCT`). |
| **Konsole** | Perfil `bruno-verde-pc` por defecto: esquema GreenOnBlack (verde sobre negro) con la fuente Hack. |
| **Tema** | Breeze Dark (colores e íconos). No toca el fondo de pantalla, el panel ni los escritorios virtuales. |

El ícono del escritorio es una copia normal: se le puede cambiar el nombre o el ícono desde click derecho → Propiedades.

### Shell (bash)

- **Prompt** con [starship](https://starship.rs) (rama de git, estado, lenguaje del proyecto).
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

### tmux

Configuración y barra de estado con git, más scripts:

- `tmux-session`: elegir o crear una sesión;
- `tmux-project`: sesión editor + terminal para un repo de `~/prj/`;
- `tmux-save` / `tmux-restore`: guardar y restaurar sesiones.

### Neovim

Setup completo basado en [LazyVim](https://www.lazyvim.org). Los plugins se descargan solos la primera vez que abrís `nvim`.

### Otros

- **Claude Code:** statusline y sonidos al empezar, terminar o pedir permiso.
- **opencode:** atajos y los mismos sonidos.
- **ProtonVPN:** `vpn-up`, `vpn-down`, `vpn-status` ([docs](docs/protonvpn-debian.md)).

## Estructura

Cada carpeta es un paquete de stow que replica la estructura de `$HOME`:

```
shell/          .bashrc, .inputrc, .vimrc, starship.toml
tmux/           tmux.conf + script de git para la barra
neovim/         ~/.config/nvim
kde/            setup-init, perfil de Konsole, entrada del menú
scripts-local/  scripts de tmux y VPN en ~/.local/bin
claude-home/    statusline y sonidos de Claude Code
opencode/       config de opencode
git/            delta (~/.config/git/config) y lazygit
local/          lista de palabras para nombres de sesiones
scripts/        funciones del instalador y paquetes
```
