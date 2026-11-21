import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// The popup behind the bar button. Each row runs one script in the user's
// terminal through xdg-terminal-exec — the same launcher Omarchy's menu uses.
//
// The scripts live in the same folder as this file (the repo root).
Panel {
  id: root
  moduleName: "topgoy333.omabloat"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property string repoDir: Qt.resolvedUrl(".").toString().replace(/^(qs|file):\/\//, "")

  function runInTerminal(script, args) {
    var cmd = "cd \"" + root.repoDir + "\" && ./" + script + " " + args
    // --hold keeps the window open after the script finishes, so the report
    // stays on screen instead of vanishing with the shell.
    Quickshell.execDetached([
      "xdg-terminal-exec", "--hold", "--title", "Omabloat",
      "bash", "-lc", cmd
    ])
  }

  function runScan() { runInTerminal("find-omarchy-bloat.sh", "") }
  function runInstallSteam() { runInTerminal("install-steam.sh", "") }
  function runSpaceScan() { runInTerminal("find-omarchy-bloat.sh", "--space-only") }
  function runAudit() { runInTerminal("debloat-omarchy.sh", "--audit") }
  function runEssentials() { runInTerminal("omarchy-essentials.sh", "") }

  // Icons come from the Nerd Fonts set the bar already uses
  // (JetBrainsMono Nerd Font), so they render like every other Omarchy widget.
  //
  // "omababy" is the name the project started under; the two scripts in that
  // group were its headline tools, so they keep the label.
  readonly property var groups: [
    {
      title: "omababy",
      actions: [
        { label: "Find bloat", desc: "Read-only scan: installed bloat candidates, web-app launchers, orphaned packages and your biggest folders. Changes nothing.", icon: "\uf0349", run: runScan },
        { label: "Install Steam", desc: "Guided Steam install with ProtonPlus guidance. Asks before it changes anything.", icon: "\uf1b6", run: runInstallSteam }
      ]
    },
    {
      title: "More tools",
      actions: [
        { label: "Disk space report", desc: "The same scan, plus how much disk each candidate uses.", icon: "\uf02ca", run: runSpaceScan },
        { label: "Debloat audit", desc: "Read-only list of what cleanup could reclaim, with a guard list for apps you rely on.", icon: "\uf0a38", run: runAudit },
        { label: "Essentials catalog", desc: "Useful apps and plugins Omarchy does not advertise. Lists only unless you ask it to install.", icon: "\uf003b", run: runEssentials }
      ]
    }
  ]

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Text {
          textFormat: Text.PlainText
          text: "Omabloat"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Bloat tools for Omarchy. Each row opens your terminal and runs one script."
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          opacity: 0.8
        }

        Repeater {
          model: root.groups
          delegate: Column {
            width: parent.width
            spacing: Style.space(6)

            Text {
              textFormat: Text.PlainText
              text: modelData.title
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              opacity: 0.55
            }

            Repeater {
              model: modelData.actions
              delegate: Item {
                width: parent.width
                height: row.implicitHeight

                Row {
                  id: row
                  width: parent.width
                  spacing: Style.space(10)

                  PanelActionButton {
                    id: actionButton
                    iconText: modelData.icon
                    tooltipText: modelData.label
                    onClicked: modelData.run()
                  }

                  Column {
                    width: parent.width - actionButton.width - Style.space(10)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                      width: parent.width
                      textFormat: Text.PlainText
                      text: modelData.label
                      color: Color.foreground
                      font.family: Style.font.family
                      font.pixelSize: Style.font.body
                      elide: Text.ElideRight
                    }

                    Text {
                      width: parent.width
                      textFormat: Text.PlainText
                      text: modelData.desc
                      color: Color.foreground
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                      opacity: 0.6
                    }
                  }
                }
              }
            }
          }
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Tip: run Find bloat first, then again after you finish setting up."
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
          opacity: 0.6
        }
      }
    }
  }
}
