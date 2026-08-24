import QtQuick
import qs.Commons
import qs.Ui

// Popup for the OmaSwiss bar icon. A pure view: every piece of state and
// every action lives on the host BarWidget injected as `hostWidget`. The
// aspect chips derive their selection from the flag-file-mirrored aspectW/H,
// so the stock SUPER+CTRL+BACKSPACE toggle and CLI calls are reflected here
// too. Every user-facing string resolves through tool.tr(), which makes the
// top-right 中/EN button re-render the whole panel. Four sections in one
// column, quick actions first: stateless quick capture actions (the panel
// closes on fire so selection overlays get a clear screen), then keyboard
// swap, window aspect (presets, custom, pin), and opinionated looks.
Panel {
  id: root
  moduleName: "glasschan.oma-swiss"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property var tool: hostWidget

  // Narrow host contract: the view consumes ONLY the hostWidget members
  // named in this file (state, strings, actions) — nothing else is reachable
  // by contract. t() absorbs the null guard for the brief window where the
  // panel exists before hostWidget is injected, so no tr() call repeats it.
  function t(key) { return hostWidget && hostWidget.tr ? hostWidget.tr(key) : "" }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(330))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(600))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        // Section header with the language switch parked at the panel's
        // top-right corner — panel-level setting, macOS-menu-bar style. The
        // glyph shows the language you get on click.
        Item {
          width: parent.width
          height: Math.max(actionsHeader.implicitHeight, langButton.size)

          PanelSectionHeader {
            id: actionsHeader
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.t("sec_actions")
          }

          // Upgrade badge: appears left of the language switch only when a
          // newer GitHub release is known (state lives on the host widget).
          // Tabler refresh-alert, rendered through iconFont like every other
          // plugin icon (codepoints collide with Nerd Fonts' codicons).
          PanelActionButton {
            id: updateButton
            anchors.right: langButton.left
            anchors.rightMargin: Style.spacing.controlGap
            anchors.verticalCenter: parent.verticalCenter
            visible: root.tool && root.tool.updateAvailable
            iconText: "\uED57"
            fontFamily: root.tool ? root.tool.iconFont : ""
            foreground: Color.urgent
            hoverColor: Color.urgent
            tooltipText: root.tool && root.tool.updateAvailable
              ? root.t("upd_tip").arg(root.tool.latestVersion) : ""
            onClicked: if (root.tool) root.tool.handleUpdateClick()
          }

          PanelActionButton {
            id: langButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            iconText: root.tool && root.tool.uiLang === "en" ? "中" : "EN"
            tooltipText: root.t("lang_tip")
            onClicked: if (root.tool) root.tool.toggleLang()
          }
        }

        // Six equal cells: icon button over a caption label. Stateless
        // launchers — the tool owns the command list, this only renders it.
        Row {
          id: actionsRow
          width: parent.width
          spacing: Style.spacing.controlGap
          readonly property real cellW: (width - (quickActions.count - 1) * spacing) / Math.max(1, quickActions.count)

          Repeater {
            id: quickActions
            model: root.tool ? root.tool.quickActions : []

            delegate: Column {
              required property var modelData
              width: actionsRow.cellW
              spacing: Style.space(4)

              PanelActionButton {
                iconText: modelData.icon
                fontFamily: root.tool ? root.tool.iconFont : ""
                tooltipText: root.t(modelData.tip)
                size: Style.space(38)
                fontSize: Style.font.iconLarge
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: if (root.tool) root.tool.runQuickAction(modelData.id)
              }

              Text {
                text: root.t(modelData.label)
                color: Qt.darker(root.barForeground, 1.4)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

        PanelSeparator {}

        PanelSectionHeader { text: root.t("sec_keyboard") }

        Toggle {
          width: parent.width
          label: root.t("swap_label")
          description: root.t("swap_desc")
          checked: root.tool && root.tool.swapped
          onClicked: if (root.tool) root.tool.toggleSwap()
        }

        PanelSeparator {}

        PanelSectionHeader { text: root.t("sec_aspect") }

        Flow {
          width: parent.width
          spacing: Style.spacing.controlGap

          Button {
            text: root.t("off")
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
              label: root.t("width")
              from: 1
              to: 64
              fieldWidth: customRow.cellW
            }

            NumberField {
              id: customH
              label: root.t("height")
              from: 1
              to: 64
              fieldWidth: customRow.cellW
            }

            Item {
              width: customRow.cellW
              height: customH.height

              Button {
                text: root.t("apply")
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

        Text {
          color: Qt.darker(root.barForeground, 1.4)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          text: root.tool && root.tool.aspectOn
            ? root.t("active") + ": " + root.tool.aspectW + ":" + root.tool.aspectH
              + (root.tool.aspectIsPreset(root.tool.aspectW, root.tool.aspectH) ? "" : " · " + root.t("custom"))
            : root.t("active") + ": " + root.t("offState")
        }

        Toggle {
          width: parent.width
          label: root.t("pin_label")
          description: root.t("pin_desc")
          checked: root.tool && root.tool.pinHotkey
          onClicked: if (root.tool) root.tool.setPin(!root.tool.pinHotkey)
        }

        PanelSeparator {}

        PanelSectionHeader { text: root.t("sec_looks") }

        Toggle {
          width: parent.width
          label: root.t("looks_label")
          description: root.t("looks_desc")
          checked: root.tool && root.tool.lookOn
          onClicked: if (root.tool) root.tool.setLook(!root.tool.lookOn)
        }

      }
    }
  }
}
