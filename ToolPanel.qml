import QtQuick
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui

// Popup for the OmaSwiss bar icon. A pure view: every piece of state and
// every action lives on the host BarWidget injected as `hostWidget`. The
// aspect chips derive their selection from the flag-file-mirrored aspectW/H,
// so the stock SUPER+CTRL+BACKSPACE toggle and CLI calls are reflected here
// too. Every user-facing string resolves through tool.tr(), which makes the
// top-right language menu re-render the whole panel. Three sections in one
// column — quick capture actions (the panel closes on fire so selection
// overlays get a clear screen), window aspect (presets plus a custom row
// that only exists while wanted), and the toggle group as single-line rows
// whose descriptions moved into hover tooltips. Release notes for a pending
// update render in a hover tooltip on the header's upgrade badge.

Panel {
  id: root
  moduleName: "glasschan.oma-swiss"

  // One line of the 切換 group: icon + name + switch, ~36px. The former
  // toggle-card description arrives as a hover tooltip. The row owns the
  // click (the switch is presentation only, like Toggle's). Deliberately
  // self-contained — everything arrives as properties, no outer ids.
  component ToggleRow: Item {
    id: toggleRow

    property string iconGlyph: ""
    property string iconFamily: ""
    property string label: ""
    property string tip: ""
    property bool checked: false

    signal toggled()

    width: parent.width
    height: Style.space(36)
    // Narrow rows clip inside the group card's rounded corners.
    clip: true

    Rectangle {
      anchors.fill: parent
      color: rowMouse.containsMouse
        ? Style.hoverFillFor(Color.foreground, Color.accent) : "transparent"
    }

    Row {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.spacing.rowPaddingX
      anchors.rightMargin: Style.spacing.rowPaddingX
      spacing: Style.spacing.controlGap

      Text {
        id: iconGlyphText
        text: toggleRow.iconGlyph
        color: Color.foreground
        font.family: toggleRow.iconFamily
        font.pixelSize: Style.font.icon
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: toggleRow.label
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
        width: parent.width - (iconGlyphText.width + parent.spacing) * 2 - track.width
        anchors.verticalCenter: parent.verticalCenter
      }

      ToggleSwitch {
        id: track
        checked: toggleRow.checked
        interactive: false
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // The row's own hover tool — PanelActionButton's pattern. Descriptions
    // must stay discoverable somewhere now that the cards are single-line.
    PanelToolTip {
      visible: rowMouse.containsMouse && toggleRow.tip !== ""
      text: toggleRow.tip
    }

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: toggleRow.toggled()
    }
  }

  // 1px rule between the group's rows (subtler than PanelSeparator).
  component GroupDivider: Rectangle {
    width: parent.width
    height: 1
    color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
  }

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property var tool: hostWidget

  // The release notes ride a hover tooltip on the upgrade badge — visible
  // only while the badge is up and there are notes to show.
  readonly property bool notesVisible: !!(root.tool && root.tool.updateAvailable
    && root.tool.updateNotes !== undefined && root.tool.updateNotes !== "")

  // View-transient UI state, not app state: whether the custom W/H/Apply row
  // exists. Opens from the 自訂… chip, closes via 關 or any preset; the
  // initial binding auto-reveals while the live ratio is a custom value
  // (no preset match), with the remembered prefill in the fields. Every
  // click assigns it and breaks the binding, so user intent sticks.
  property bool customRevealed: root.tool
    ? (root.tool.aspectOn && !root.tool.aspectIsPreset(root.tool.aspectW, root.tool.aspectH))
    : false

  // The header button shows the ACTIVE language as a compact glyph; the
  // full self-named list lives in the menu.
  readonly property string langTag: !root.tool ? "EN"
    : root.tool.uiLang === "zh" ? "中"
    : root.tool.uiLang === "ja" ? "日"
    : root.tool.uiLang === "ko" ? "한" : "EN"

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
    // No artificial cap: fittedContentHeight clamps the card against
    // availableCardHeight (the real space on the anchor edge). The card is
    // sized to the column's natural height; the clamp below is degenerate
    // containment only.
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)
        // Hard containment: nothing inside the panel may paint past the
        // card's background. Normally the clamp is a no-op (contentHeight
        // IS this column's implicit height plus insets); on a screen too
        // small for the fixed stack it pins the column's rect to the inner
        // height so the clip actually contains (a positioner's height
        // defaults to its implicitHeight, i.e. as tall as the overflow,
        // which would make clip: true alone inert). Loop-free: nothing in
        // contentHeight's dependency chain reads column.height.
        height: Math.min(implicitHeight, panel.contentHeight - panel.verticalContentInset)
        clip: true

        // Section header with the language switch parked at the panel's
        // top-right corner — panel-level setting. The button shows the
        // active language and opens the language menu.
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
          // Hovering shows the release notes as a wrapped, height-capped
          // tooltip (plain text — notes are untrusted content, never rich
          // text); without notes the built-in single-line tip stays.
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
            property bool badgeHot: false
            onHovered: function(isHovered) { badgeHot = isHovered }
            tooltipText: !root.notesVisible && root.tool && root.tool.updateAvailable
              ? root.t("upd_tip").arg(root.tool.latestVersion) : ""
            onClicked: if (root.tool) root.tool.handleUpdateClick()

            PanelToolTip {
              id: notesTip
              visible: updateButton.badgeHot && root.notesVisible
              width: Math.min(implicitWidth, Style.space(300))
              text: root.tool && root.tool.updateNotes ? root.tool.updateNotes : ""

              contentItem: Text {
                text: notesTip.text
                color: notesTip.panelForeground
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                // Untrusted content: plain text only, wrapped at panel
                // width, hard line cap so a huge body can't cover the
                // screen — the elided tail lives on GitHub.
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 16
                width: notesTip.availableWidth
                leftPadding: Border.left(notesTip.panelBorderSpec) + Style.spacing.controlPaddingX
                rightPadding: Border.right(notesTip.panelBorderSpec) + Style.spacing.controlPaddingX
                topPadding: Border.top(notesTip.panelBorderSpec) + Style.spacing.controlPaddingY
                bottomPadding: Border.bottom(notesTip.panelBorderSpec) + Style.spacing.controlPaddingY
              }
            }
          }

          PanelActionButton {
            id: langButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            iconText: root.langTag
            tooltipText: root.t("lang_tip")
            onClicked: langMenu.popup(langButton, 0, langButton.height + Style.space(4))
          }
        }

        // Eight cells in two rows of four: icon button over a caption label.
        // Stateless launchers — the tool owns the command list, this only
        // renders it.
        Grid {
          id: actionsRow
          width: parent.width
          columns: 4
          spacing: Style.spacing.controlGap
          readonly property real cellW: (width - (columns - 1) * spacing) / columns

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

        PanelSectionHeader { text: root.t("sec_aspect") }

        Flow {
          width: parent.width
          spacing: Style.spacing.controlGap

          Button {
            text: root.t("off")
            selected: root.tool && !root.tool.aspectOn
            onClicked: {
              root.customRevealed = false
              if (root.tool) root.tool.clearAspect()
            }
          }

          Repeater {
            model: root.tool ? root.tool.aspectPresets : []

            delegate: Button {
              required property var modelData
              text: modelData.label
              selected: root.tool
                && root.tool.aspectW === modelData.w
                && root.tool.aspectH === modelData.h
              onClicked: {
                root.customRevealed = false
                if (root.tool) root.tool.setAspect(modelData.w, modelData.h)
              }
            }
          }

          // Reveals the custom W/H/Apply row on demand. Selecting itself is
          // not an aspect change — nothing lands until 套用.
          Button {
            text: root.t("customChip")
            selected: root.customRevealed
            onClicked: root.customRevealed = true
          }
        }

        // Three equal columns on one line — W field, H field, Apply — each
        // filling a third of the row. The Apply cell bottom-aligns with the
        // spinboxes (it has no label above it). Exists only while revealed.
        Row {
            id: customRow
            visible: root.customRevealed
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

        PanelSeparator {}

        PanelSectionHeader { text: root.t("sec_toggles") }

        // The four toggles as one 切換 group of single-line rows — the
        // former one-card-per-toggle layout cost ~120px each. Row order:
        // gaming, swap, looks, pin. Descriptions live on row hover.
        BorderSurface {
          width: parent.width
          height: toggleRows.height
          radius: Style.cornerRadius
          color: "transparent"
          borderSpec: Border.controlSpec("normal", Color.foreground, Color.accent)
          clip: true

          Column {
            id: toggleRows
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            ToggleRow {
              iconGlyph: "\uF1F4" // tabler device-gamepad
              iconFamily: root.tool ? root.tool.iconFont : ""
              label: root.t("gaming_label")
              tip: root.t("gaming_desc")
              checked: root.tool && root.tool.gamingOn
              onToggled: if (root.tool) root.tool.setGaming(!root.tool.gamingOn)
            }

            GroupDivider {}

            ToggleRow {
              iconGlyph: "\uEB63" // tabler arrows-exchange
              iconFamily: root.tool ? root.tool.iconFont : ""
              label: root.t("swap_label")
              tip: root.t("swap_desc")
              checked: root.tool && root.tool.swapped
              onToggled: if (root.tool) root.tool.toggleSwap()
            }

            GroupDivider {}

            ToggleRow {
              iconGlyph: "\uEB01" // tabler palette
              iconFamily: root.tool ? root.tool.iconFont : ""
              label: root.t("looks_label")
              tip: root.t("looks_desc")
              checked: root.tool && root.tool.lookOn
              onToggled: if (root.tool) root.tool.setLook(!root.tool.lookOn)
            }

            GroupDivider {}

            ToggleRow {
              iconGlyph: "\uEC9C" // tabler pin
              iconFamily: root.tool ? root.tool.iconFont : ""
              label: root.t("pin_label")
              tip: root.t("pin_desc")
              checked: root.tool && root.tool.pinHotkey
              onToggled: if (root.tool) root.tool.setPin(!root.tool.pinHotkey)
            }
          }
        }

      }
    }
  }

  // Interface-language menu — QQC2, rendered in the shell overlay exactly
  // like the tooltips. Items are self-named; the active one carries the
  // checkmark. Selecting goes through the host's setLang (the pure-view
  // host-call rule: root.tool, never root) and the menu closes itself.
  QQC.Menu {
    id: langMenu
    width: Style.space(160)
    closePolicy: QQC.Popup.CloseOnEscape | QQC.Popup.CloseOnPressOutside

    background: BorderSurface {
      color: Color.tooltip.background
      radius: Style.cornerRadius
      borderSpec: Border.localOrSurfaceSpec("tooltip", "border",
        Color.tooltip.border, Color.tooltip.border, Style.normalBorderWidth)
    }

    component LangItem: QQC.MenuItem {
      id: langItem
      property string code: ""
      property string name: ""
      property bool active: false
      signal picked(string code)
      height: Style.space(30)
      leftPadding: Style.spacing.controlPaddingX
      rightPadding: Style.spacing.controlPaddingX
      checked: langItem.active
      onTriggered: langItem.picked(langItem.code)

      background: BorderSurface {
        color: langItem.hovered || langItem.highlighted
          ? Style.hoverFillFor(Color.foreground, Color.accent) : "transparent"
        radius: 0
      }

      contentItem: Row {
        spacing: Style.spacing.controlGap

        Text {
          text: "✓"
          visible: langItem.checked
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: langItem.name
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    LangItem {
      code: "en"
      name: "English"
      active: root.tool ? root.tool.uiLang === "en" : false
      onPicked: function(c) { if (root.tool) root.tool.setLang(c) }
    }

    LangItem {
      code: "zh"
      name: "中文"
      active: root.tool ? root.tool.uiLang === "zh" : false
      onPicked: function(c) { if (root.tool) root.tool.setLang(c) }
    }

    LangItem {
      code: "ja"
      name: "日本語"
      active: root.tool ? root.tool.uiLang === "ja" : false
      onPicked: function(c) { if (root.tool) root.tool.setLang(c) }
    }

    LangItem {
      code: "ko"
      name: "한국어"
      active: root.tool ? root.tool.uiLang === "ko" : false
      onPicked: function(c) { if (root.tool) root.tool.setLang(c) }
    }
  }
}
