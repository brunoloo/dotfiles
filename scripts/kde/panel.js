// Panel de Plasma: una sola barra inferior a lo ancho, pegada, con los íconos
// de aplicaciones centrados (espaciadores), pager con números y fecha dd/MM/yyyy.
// Se ejecuta con: qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat panel.js)"
// Idempotente: si ya hay un solo panel así, no hace nada. Crea el panel nuevo
// primero y borra los viejos al final, así un fallo no deja el escritorio sin barra.

var wanted = [
  "org.kde.plasma.kickoff",
  "org.kde.plasma.pager",
  "org.kde.plasma.panelspacer",
  "org.kde.plasma.icontasks",
  "org.kde.plasma.panelspacer",
  "org.kde.plasma.marginsseparator",
  "org.kde.plasma.systemtray",
  "org.kde.plasma.digitalclock",
  "org.kde.plasma.showdesktop"
];

function signature(p) {
  var types = [];
  p.widgetIds.forEach(function (id) { types.push(p.widgetById(id).type); });
  return p.location + "|" + p.lengthMode + "|" + p.floating + "|" + types.join(",");
}

var target = "bottom|fill|false|" + wanted.join(",");
var current = panels();

if (current.length === 1 && signature(current[0]) === target) {
  print("ya aplicado");
} else {
  var oldIds = current.map(function (p) { return p.id; });

  var panel = new Panel();
  panel.location = "bottom";
  panel.alignment = "center";
  panel.lengthMode = "fill";
  panel.floating = false;
  panel.height = 44;
  panel.hiding = "none";

  var added = {};
  wanted.forEach(function (type) {
    var w = panel.addWidget(type);
    if (!added[type]) { added[type] = w; }
  });

  var pager = added["org.kde.plasma.pager"];
  pager.currentConfigGroup = ["General"];
  pager.writeConfig("displayedText", "Number");
  pager.reloadConfig();

  var clock = added["org.kde.plasma.digitalclock"];
  clock.currentConfigGroup = ["Appearance"];
  clock.writeConfig("showDate", true);
  clock.writeConfig("dateFormat", "custom");
  clock.writeConfig("customDateFormat", "dd/MM/yyyy");
  clock.reloadConfig();

  oldIds.forEach(function (id) { var p = panelById(id); if (p) { p.remove(); } });
  print("panel creado (" + oldIds.length + " viejo(s) reemplazado(s))");
}
