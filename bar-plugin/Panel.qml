import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// The popup behind the bar button. Content is a small list of actions; each
// one opens the matching script in the user's terminal.
Panel {
  id: root
  moduleName: "topgoy333.omabloat"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property string repoDir: Qt.resolvedUrl("..").toString().replace(/^(qs|file):\/\//, "")

  function runInTerminal(script, args) {
    var cmd = "cd \"" + root.repoDir + "\" && ./" + script + " " + args
    Quickshell.execDetached(["xdg-terminal-exec", "bash", "-lc", cmd])
  }

  function runScan() { runInTerminal("find-omarchy-bloat.sh", "") }
  function runSpaceScan() { runInTerminal("find-omarchy-bloat.sh", "--space-only") }
  function runAudit() { runInTerminal("debloat-omarchy.sh", "--audit") }
  function runSteamCheck() { runInTerminal("install-steam.sh", "--check") }

  readonly property var actions: [
    { label: "Scan for bloat (read-only)", hint: "First-and-last detector", run: runScan },
    { label: "Show disk space per candidate", hint: "Adds sizes to the report", run: runSpaceScan },
    { label: "Debloat audit (read-only)", hint: "What cleanup could reclaim", run: runAudit },
    { label: "Steam status (read-only)", hint: "Check before installing", run: runSteamCheck }
  ]

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: {
        if (cursorIndex >= 0 && cursorIndex < root.actions.length) root.actions[cursorIndex].run()
      }

      property int cursorIndex: -1

      Column {
        id: column
        width: parent.width
        spacing: Style.space(8)

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
          text: "Read-only bloat tools for Omarchy. Each button opens your terminal and runs one script."
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          opacity: 0.8
        }

        Repeater {
          model: root.actions
          delegate: Item {
            width: parent.width
            height: row.implicitHeight

            Row {
              id: row
              width: parent.width
              spacing: Style.space(10)

              PanelActionButton {
                id: actionButton
                iconText: ""
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
                  text: modelData.hint
                  color: Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  opacity: 0.6
                }
              }
            }
          }
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Tip: run the scan first, then again after you finish setting up."
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
