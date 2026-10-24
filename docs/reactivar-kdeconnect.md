# Reactivar KDE Connect (kdeconnectd)

KDE Connect se desactivó el 24/10/2026 para liberar RAM (~29 MB) antes de usar las VMs.

## Reactivarlo

```
~/.local/bin/kdeconnect-activar
```

Quita los bloqueos y arranca el servicio. Desde el próximo inicio de sesión arranca solo.

## Volver a desactivarlo

```
~/.local/bin/kdeconnect-desactivar
```

## Reactivarlo a mano (si los scripts no existen)

```
rm ~/.config/autostart/org.kde.kdeconnect.daemon.desktop ~/.local/share/dbus-1/services/org.kde.kdeconnect.service && dbus-send --session --type=method_call --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig && systemctl --user daemon-reload && kdeconnectd &
```

## Qué se había hecho para desactivarlo

- `~/.config/autostart/org.kde.kdeconnect.daemon.desktop` con `Hidden=true`: evita el autostart.
- `~/.local/share/dbus-1/services/org.kde.kdeconnect.service` con `Exec=/bin/false`: evita que se active por D-Bus.
