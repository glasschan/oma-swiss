import QtQuick
import qs.Commons
import qs.Ui

// Popup for the Hypr Toolbox bar icon. A pure view: every piece of state and
// every action lives on the host BarWidget injected as `hostWidget`. The
// aspect chips derive their selection from the flag-file-mirrored aspectW/H,
// so the stock SUPER+CTRL+BACKSPACE toggle and CLI calls are reflected here
// too.
Panel {
  id: root
  moduleName: "glasschan.hypr-toolbox"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property var tool: hostWidget

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(330))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(440))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        PanelSectionHeader { text: "SUPER ⇄ ALT · LAPTOP KEYBOARD" }

        Toggle {
          width: parent.width
          label: "Swap Left Super / Left Alt"
          description: "Built-in keyboard only. External keyboards keep their stock mapping."
          checked: root.tool && root.tool.swapped
          onClicked: if (root.tool) root.tool.toggleSwap()
        }

        PanelSeparator {}

        PanelSectionHeader { text: "SINGLE-WINDOW ASPECT" }

        Flow {
          width: parent.width
          spacing: Style.spacing.controlGap

          Button {
            text: "Off"
            selected: root.tool && !root.tool.aspectOn
            onClicked: if (root.tool) root.tool.clearAspect()
          }

          Repeater {
            model: root.tool ? root.tool.aspectPresets : []

            delegate: Button {
              required property var modelData
              text: modelData.label
              selected: root.tool
                && root.tool.aspectW === modelData.w
                && root.tool.aspectH === modelData.h
              onClicked: if (root.tool) root.tool.setAspect(modelData.w, modelData.h)
            }
          }
        }

        Text {
          color: Qt.darker(root.barForeground, 1.4)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          text: root.tool && root.tool.aspectOn
            ? "Active: " + root.tool.aspectW + ":" + root.tool.aspectH
              + (root.tool.aspectIsPreset(root.tool.aspectW, root.tool.aspectH) ? "" : " · custom")
            : "Active: off"
        }

        PanelSeparator {}

        PanelSectionHeader { text: "CUSTOM RATIO" }

        // Three equal columns on one line — W field, H field, Apply — each
        // filling a third of the row. The Apply cell bottom-aligns with the
        // spinboxes (it has no label above it).
        Row {
            id: customRow
            width: parent.width
            spacing: Style.spacing.controlGap
            readonly property real cellW: (width - 2 * spacing) / 3

            NumberField {
              id: customW
              label: "Width"
              from: 1
              to: 64
              fieldWidth: customRow.cellW
            }

            NumberField {
              id: customH
              label: "Height"
              from: 1
              to: 64
              fieldWidth: customRow.cellW
            }

            Item {
              width: customRow.cellW
              height: customH.height

              Button {
                text: "Apply"
                width: parent.width
                anchors.bottom: parent.bottom
                onClicked: if (root.tool)
                  root.tool.setAspect(customW.field.value, customH.field.value)
              }
            }

            Component.onCompleted: {
              var t = root.tool
              if (!t) return
              if (t.aspectOn && !t.aspectIsPreset(t.aspectW, t.aspectH)) {
                customW.field.value = t.aspectW
                customH.field.value = t.aspectH
              } else if (t.lastW > 0 && t.lastH > 0) {
                customW.field.value = t.lastW
                customH.field.value = t.lastH
              } else {
                customW.field.value = 21
                customH.field.value = 9
              }
            }
        }

        PanelSeparator {}

        Toggle {
          width: parent.width
          label: "Pin to hotkey"
          description: "SUPER+CTRL+BACKSPACE toggles your last ratio instead of the stock 1:1. Reversible any time."
          checked: root.tool && root.tool.pinHotkey
          onClicked: if (root.tool) root.tool.setPin(!root.tool.pinHotkey)
        }
      }
    }
  }
}
