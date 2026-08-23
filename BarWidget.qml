import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui

// Hypr Toolbox: the state engine and bar icon. Every piece of state and every
// action lives here; ToolPanel.qml is a pure view injected with this widget as
// hostWidget. Both tools are flag-file driven so they survive reloads and
// logins without the widget running, and everything is event driven — no
// timers, no polling.
BarWidget {
  id: root
  moduleName: "glasschan.hypr-toolbox"

  // ---- Tool 1: laptop Super/Alt swap --------------------------------------

  // The internal AT keyboard laptops expose; external keyboards never match
  // this name, so a docked or wireless keyboard keeps its stock mapping.
  readonly property string keyboardName: "at-translated-set-2-keyboard"
  readonly property string swapOption: "altwin:swap_lalt_lwin"
  readonly property string swapFlagPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/hypr/super-alt-swap.lua"

  // The keyboard's live options minus the swap: what the device must carry
  // whenever the swap is off. Recovered from each reading so user edits in
  // hypr/input.lua are never shadowed by a stale copy.
  property string baseOptions: ""
  property bool swapped: false

  // The swap toggle file re-applies the swap on every Hyprland config load,
  // so the swap survives reloads and logins without the widget running. It
  // merges whatever input.kb_options holds at load time, keeping options set
  // in hypr/input.lua (e.g. compose:caps) intact. Path and content match the
  // retired glasschan.super-alt-swap plugin: an existing flag keeps working
  // untouched.
  readonly property string swapToggleLua:
    'local base = select(1, hl.get_config("input.kb_options")) or ""\n' +
    'if not string.find(base, "altwin:swap_lalt_lwin", 1, true) then\n' +
    '  if base == "" then base = "altwin:swap_lalt_lwin" else base = base .. ",altwin:swap_lalt_lwin" end\n' +
    'end\n' +
    'hl.device({ name = "at-translated-set-2-keyboard", kb_options = base })\n'

  // ---- Tool 2: single-window aspect ratio ----------------------------------

  // The stock toggle's flag, written directly with the chosen ratio. Never
  // call omarchy-hyprland-toggle for this: its "on" path copies the stock 1:1
  // default over whatever the user picked. The file content (not existence)
  // is the state, so the stock SUPER+CTRL+BACKSPACE binding coexists: if it
  // rewrites the flag to 1:1, the watcher below picks the new value up.
  readonly property string aspectFlagPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua"

  // The last ratio the user set (preset or custom): the panel prefills from
  // it and the pinned hotkey toggles it. Plain "w h" text; "0 0" = never set.
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/glasschan.hypr-toolbox"
  readonly property string lastPath: stateDir + "/last-aspect"
  property int lastW: 0
  property int lastH: 0

  // Pin: while the pin toggle file exists, SUPER+CTRL+BACKSPACE toggles the
  // toolbox's last ratio instead of the stock 1:1. The file registers the
  // binding on every config load (toggles load last, after user bindings),
  // so it survives omarchy updates and refreshes and needs no edits to
  // ~/.config/hypr. File exists = pinned; content is static.
  readonly property string pinPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/hypr/hypr-toolbox-hotkey.lua"
  property bool pinHotkey: false

  readonly property string pinLua:
    "-- glasschan.hypr-toolbox: pin the single-window aspect hotkey.\n" +
    "-- While this file exists, SUPER+CTRL+BACKSPACE toggles the toolbox's\n" +
    "-- last ratio instead of the stock 1:1. Remove the file and reload to\n" +
    "-- restore the previous binding.\n" +
    "hl.unbind(\"SUPER + CTRL + BACKSPACE\")\n" +
    "o.bind(\"SUPER + CTRL + BACKSPACE\", \"Toggle single-window aspect (hypr-toolbox)\", \"omarchy-shell glasschan.hypr-toolbox aspectToggle\")\n"

  // 0 0 = off. Mirrors the flag file — the single source of truth.
  property int aspectW: 0
  property int aspectH: 0
  readonly property bool aspectOn: aspectW > 0 && aspectH > 0

  readonly property var aspectPresets: [
    { label: "1:1", w: 1, h: 1 },
    { label: "4:3", w: 4, h: 3 },
    { label: "3:2", w: 3, h: 2 },
    { label: "16:9", w: 16, h: 9 }
  ]

  function aspectIsPreset(w, h) {
    for (var i = 0; i < aspectPresets.length; i++)
      if (aspectPresets[i].w === w && aspectPresets[i].h === h) return true
    return false
  }

  function aspectFlagLua(w, h) {
    return "-- glasschan.hypr-toolbox: single-window aspect ratio.\n" +
      "hl.config({\n  layout = {\n    single_window_aspect_ratio = { " + w + ", " + h + " },\n  },\n})\n"
  }

  // ---- shared queued hyprctl eval -------------------------------------------

  // One Process, one slot: rapid clicks queue instead of dropping, so every
  // action lands in order. An eval may carry a notification (message +
  // glyph) that is sent only if the eval lands.
  property string pendingExpr: ""
  property bool evalPending: false
  property string evalNotify: ""
  property string evalNotifyGlyph: ""
  property string queuedNotify: ""
  property string queuedNotifyGlyph: ""

  function queueEval(expr, notify, glyph) {
    if (evalProc.running) {
      pendingExpr = expr
      evalPending = true
      queuedNotify = notify || ""
      queuedNotifyGlyph = glyph || ""
      return
    }
    evalPending = false
    evalNotify = notify || ""
    evalNotifyGlyph = glyph || ""
    evalProc.command = ["hyprctl", "eval", expr]
    evalProc.running = true
  }

  function evalSwap(options) {
    return 'hl.device({ name = "' + keyboardName + '", kb_options = "' + options + '" })'
  }

  function evalAspect(w, h) {
    return "hl.config({ layout = { single_window_aspect_ratio = { " + w + ", " + h + " } } })"
  }

  // ---- actions ----------------------------------------------------------------

  function toggleSwap() {
    console.log("hypr-toolbox: swap toggle, swapped =", swapped)
    // Flip the icon right away; evalProc's exit re-reads the live state and
    // corrects it if the eval did not land.
    swapped = !swapped
    if (swapped) {
      swapFlagFile.setText(swapToggleLua)
      queueEval(evalSwap(baseOptions === "" ? swapOption : baseOptions + "," + swapOption))
    } else {
      removeSwapFlag.running = true
      queueEval(evalSwap(baseOptions))
    }
  }

  function setAspect(w, h) {
    var wi = parseInt(w), hi = parseInt(h)
    if (!(wi > 0 && hi > 0)) {
      console.warn("hypr-toolbox: aspect needs two positive integers, got", w, h)
      return
    }
    wi = Math.min(wi, 64)
    hi = Math.min(hi, 64)
    console.log("hypr-toolbox: aspect set", wi + ":" + hi)
    aspectW = wi
    aspectH = hi
    aspectFlagFile.setText(aspectFlagLua(wi, hi))
    queueEval(evalAspect(wi, hi), "Single-window aspect: " + wi + ":" + hi, "󰘮")
    saveLast(wi, hi)
  }

  // The pinned hotkey flips between off and the last ratio set here; the
  // same function serves anyone binding it manually.
  function aspectToggle() {
    if (aspectOn) clearAspect()
    else if (lastW > 0 && lastH > 0) setAspect(lastW, lastH)
    else console.warn("hypr-toolbox: aspectToggle with no last ratio")
  }

  function setPin(on) {
    console.log("hypr-toolbox: pin hotkey", on ? "on" : "off")
    pinHotkey = on
    if (on) writePinProc.running = true
    else removePinProc.running = true
  }

  function clearAspect() {
    console.log("hypr-toolbox: aspect off")
    aspectW = 0
    aspectH = 0
    removeAspectFlag.running = true
    queueEval(evalAspect(0, 0), "Single-window aspect: off", "󰘮")
  }

  function saveLast(w, h) {
    lastW = w
    lastH = h
    lastFile.setText(w + " " + h)
  }

  // ---- state refresh -------------------------------------------------------------

  function refresh() {
    if (!queryProc.running) queryProc.running = true
    aspectFlagFile.reload()
  }

  function parseAspectFlag(text) {
    var m = /single_window_aspect_ratio\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*\}/.exec(text || "")
    if (m) {
      aspectW = parseInt(m[1]) || 0
      aspectH = parseInt(m[2]) || 0
    } else {
      aspectW = 0
      aspectH = 0
    }
  }

  Component.onCompleted: {
    ensureStateDir.running = true
    refresh()
  }

  // ---- popup panel ----------------------------------------------------------------

  // Panel shape contract the bar routes summon/popout switching through. The
  // panel is created lazily on first open and stays loaded afterwards; closed,
  // its layer-shell window unmaps, so the idle cost is the QML tree only.
  property bool panelWanted: false
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    panelWanted = true
    panelLoader.active = true
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() {
    panelWanted = false
    if (panelLoader.item) panelLoader.item.close()
  }
  function togglePanel() { opened ? close() : open() }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: panelLoader
    active: false
    source: Qt.resolvedUrl("ToolPanel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
      if (root.panelWanted) panelLoader.item.open()
    }
  }

  // CLI access — the same paths a bar click drives:
  //   omarchy-shell glasschan.hypr-toolbox toggle         swap on/off
  //   omarchy-shell glasschan.hypr-toolbox aspect 21 10   set ratio
  //   omarchy-shell glasschan.hypr-toolbox aspectOff      ratio off
  //   omarchy-shell glasschan.hypr-toolbox aspectToggle   off <-> last ratio
  //   omarchy-shell glasschan.hypr-toolbox pin            pin/unpin the hotkey
  //   omarchy-shell glasschan.hypr-toolbox panel          open/close popup
  IpcHandler {
    target: "glasschan.hypr-toolbox"
    function toggle(): void { root.toggleSwap() }
    function aspect(w: string, h: string): void { root.setAspect(w, h) }
    function aspectOff(): void { root.clearAspect() }
    function aspectToggle(): void { root.aspectToggle() }
    function pin(): void { root.setPin(!root.pinHotkey) }
    function panel(): void { root.togglePanel() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function status(): string {
      return "swap=" + (root.swapped ? "on" : "off")
        + " aspect=" + (root.aspectOn ? root.aspectW + ":" + root.aspectH : "off")
        + " last=" + (root.lastW > 0 ? root.lastW + ":" + root.lastH : "none")
        + " pin=" + (root.pinHotkey ? "on" : "off")
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰘮"
    active: root.swapped
    dimmed: !root.swapped
    tooltipText: root.swapped
      ? "Hypr Toolbox · Super⇄Alt swapped (right-click restore, left-click tools)"
      : "Hypr Toolbox · left-click tools, right-click toggles Super⇄Alt"
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.togglePanel()
      else if (b === Qt.RightButton) root.toggleSwap()
    }
  }

  // A config reload reapplies or drops both tools depending on the flag
  // files, and the UI must follow either way. Debounced: reloads can fire
  // several events back to back.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "configreloaded") reloadDebounce.restart()
    }
  }

  Timer {
    id: reloadDebounce
    interval: 100
    onTriggered: root.refresh()
  }

  // The live reading is the only source of truth for the swap icon: the eval
  // that toggles is async, so state is queried again after it lands.
  Process {
    id: queryProc
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        let keyboards
        try {
          keyboards = JSON.parse(text || "{}").keyboards
        } catch (e) {
          return
        }
        if (!Array.isArray(keyboards)) return

        for (var i = 0; i < keyboards.length; i++) {
          if (String(keyboards[i].name || "") !== root.keyboardName) continue
          var options = String(keyboards[i].options || "").split(",")
            .filter(function(o) { return o !== "" })
          root.baseOptions = options
            .filter(function(o) { return o !== root.swapOption })
            .join(",")
          root.swapped = options.indexOf(root.swapOption) !== -1
          break
        }
      }
    }
  }

  // Applies one queued eval (swap device options or aspect ratio). The exit
  // handler chains any action queued while busy, then broadcasts to every
  // monitor's instance, so the optimistic UI is always corrected by the truth
  // and no screen keeps stale state.
  Process {
    id: evalProc
    stdout: StdioCollector {
      id: evalOut
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: evalErr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        // hyprctl prints errors on stdout, so both streams are shown.
        console.warn("hypr-toolbox: hyprctl eval failed (" + exitCode + "):",
          (evalOut.text.trim() || evalErr.text.trim()))
      } else if (root.evalNotify !== "") {
        notifyProc.command = ["omarchy-notification-send", "-g",
          root.evalNotifyGlyph, root.evalNotify]
        notifyProc.running = true
      }
      root.evalNotify = ""
      root.evalNotifyGlyph = ""
      if (root.evalPending) {
        var expr = root.pendingExpr
        root.evalPending = false
        root.pendingExpr = ""
        root.evalNotify = root.queuedNotify
        root.evalNotifyGlyph = root.queuedNotifyGlyph
        root.queuedNotify = ""
        root.queuedNotifyGlyph = ""
        evalProc.command = ["hyprctl", "eval", expr]
        evalProc.running = true
      } else {
        root.broadcast("refresh")
      }
    }
  }

  // Fires the completion notification for an eval that landed.
  Process {
    id: notifyProc
  }

  FileView {
    id: swapFlagFile
    path: root.swapFlagPath
    atomicWrites: true
    printErrors: false
  }

  Process {
    id: removeSwapFlag
    command: ["rm", "-f", root.swapFlagPath]
    onExited: {
      // FileView caches content and skips no-change writes. After rm the
      // cache is stale, so re-sync it or the next setText() silently no-ops
      // and the swap would not survive the next reload.
      swapFlagFile.reload()
    }
  }

  // Aspect flag: watched so external writers (the stock
  // SUPER+CTRL+BACKSPACE toggle writes 1:1 here) are reflected without
  // polling. Parse on load completion only — reload() transiently clears
  // the text property, so onTextChanged would parse an empty string mid-way
  // and clobber good state.
  FileView {
    id: aspectFlagFile
    path: root.aspectFlagPath
    atomicWrites: true
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.parseAspectFlag(text())
    onLoadFailed: root.parseAspectFlag("")
  }

  Process {
    id: removeAspectFlag
    command: ["rm", "-f", root.aspectFlagPath]
    onExited: { aspectFlagFile.reload() }
  }

  FileView {
    id: lastFile
    path: root.lastPath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      var m = /^(\d+)\s+(\d+)$/.exec(text() || "")
      if (m) {
        root.lastW = parseInt(m[1]) || 0
        root.lastH = parseInt(m[2]) || 0
      }
    }
  }

  // Pin state mirrors the toggle file's existence; watching covers our own
  // writes and any manual removal alike.
  FileView {
    id: pinFile
    path: root.pinPath
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.pinHotkey = true
    onLoadFailed: root.pinHotkey = false
  }

  // The pin file write and the reload that activates its binding must not
  // race (FileView.setText is async), so one shell command does both in
  // order. Toggles load after user bindings, so the pinned bind always wins
  // while the file exists, and vanishing restores whatever was there before.
  Process {
    id: writePinProc
    command: ["sh", "-c",
      "cat > '" + root.pinPath + "' <<'HYPRTOOLBOX_PIN_EOF'\n"
      + root.pinLua
      + "HYPRTOOLBOX_PIN_EOF\nhyprctl reload"]
  }

  Process {
    id: removePinProc
    command: ["sh", "-c", "rm -f '" + root.pinPath + "' && hyprctl reload"]
  }

  Process {
    id: ensureStateDir
    command: ["mkdir", "-p", root.stateDir]
  }
}
