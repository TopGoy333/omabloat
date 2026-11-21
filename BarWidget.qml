import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar button for omabloat. The scan is a terminal script, so the panel
// explains what it does and runs it in the user's terminal through
// xdg-terminal-exec — the same launcher Omarchy's own menu uses.
//
// This widget lives at the repo root so `omarchy plugin add <repo>` installs
// the whole repo as one plugin; the scripts sit beside these QML files.
BarWidget {
  id: root
  moduleName: "topgoy333.omabloat"

  property var panelImpl: null
  // Repo root == this plugin folder.
  readonly property string repoDir: Qt.resolvedUrl(".").toString().replace(/^(qs|file):\/\//, "")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    root.panelImpl = target
  }

  function togglePanel() {
    if (panelImpl && typeof panelImpl.toggle === "function") panelImpl.toggle()
  }

  function runInTerminal(script, args) {
    var dir = root.repoDir
    var cmd = "cd \"" + dir + "\" && ./" + script + " " + args
    Quickshell.execDetached(["xdg-terminal-exec", "bash", "-lc", cmd])
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰃟"
    tooltipText: "Omabloat — find bloat (read-only)"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        if (root.panelImpl && typeof root.panelImpl.close === "function") root.panelImpl.close()
      } else {
        root.togglePanel()
      }
    }
  }

  // Shape contract the bar uses to route shell.summon/hide/toggle.
  readonly property bool opened: panelImpl ? panelImpl.opened === true : false

  function open() {
    if (panelImpl && typeof panelImpl.open === "function") panelImpl.open()
  }

  function close() {
    if (panelImpl && typeof panelImpl.close === "function") panelImpl.close()
  }
}
