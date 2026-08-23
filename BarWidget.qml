import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// OmaSwiss: the state engine and bar icon. Every piece of state and every
// action lives here; ToolPanel.qml is a pure view injected with this widget as
// hostWidget. The toggles (swap, aspect, opinionated looks) are flag-file
// driven so they survive reloads and logins without the widget running, and
// everything is event driven — no timers, no polling. Quick actions are
// stateless one-shot launchers.
BarWidget {
  id: root
  moduleName: "glasschan.oma-swiss"

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
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/glasschan.oma-swiss"
  readonly property string lastPath: stateDir + "/last-aspect"
  property int lastW: 0
  property int lastH: 0

  // Pin: while the pin toggle file exists, SUPER+CTRL+BACKSPACE toggles the
  // plugin's last ratio instead of the stock 1:1. The file registers the
  // binding on every config load (toggles load last, after user bindings),
  // so it survives omarchy updates and refreshes and needs no edits to
  // ~/.config/hypr. File exists = pinned; content is static.
  readonly property string pinPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/hypr/oma-swiss-hotkey.lua"
  property bool pinHotkey: false

  readonly property string pinLua:
    "-- glasschan.oma-swiss: pin the single-window aspect hotkey.\n" +
    "-- While this file exists, SUPER+CTRL+BACKSPACE toggles the plugin's\n" +
    "-- last ratio instead of the stock 1:1. Remove the file and reload to\n" +
    "-- restore the previous binding.\n" +
    "hl.unbind(\"SUPER + CTRL + BACKSPACE\")\n" +
    "o.bind(\"SUPER + CTRL + BACKSPACE\", \"Toggle single-window aspect (oma-swiss)\", \"omarchy-shell glasschan.oma-swiss aspectToggle\")\n"

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
    return "-- glasschan.oma-swiss: single-window aspect ratio.\n" +
      "hl.config({\n  layout = {\n    single_window_aspect_ratio = { " + w + ", " + h + " },\n  },\n})\n"
  }

  // ---- Tool 3: opinionated looks --------------------------------------------

  // One flag file owns the whole opinionated look: exists = the block below
  // runs on every config load (toggles load after user configs, so it
  // overrides looknfeel.lua); absent = Omarchy defaults. Static looks only —
  // no animation overrides: the former macSpring set was removed because it
  // was indistinguishable from stock Omarchy animations. Values are the
  // user's live tuning (border 5, rounding 6, gradient rim bright-on-top,
  // blur size 6 / vibrancy 0.20, shadow 20/4/rgba(00000028)).
  readonly property string lookFlagPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/hypr/opinionated-looks.lua"
  property bool lookOn: false

  readonly property string lookLua: [
    "-- glasschan.oma-swiss: opinionated looks.",
    "-- Exists = this look applies on every Hyprland config load; remove the",
    "-- file and reload to restore Omarchy defaults. Static look only —",
    "-- animations stay whatever the rest of the config defines.",
    "hl.config({",
    "  general = {",
    "    border_size = 5,",
    "    col = {",
    '      active_border = { colors = { "rgba(ffffff30)", "rgba(ffffff08)" }, angle = 90 },',
    '      inactive_border = { colors = { "rgba(ffffff18)", "rgba(ffffff06)" }, angle = 90 },',
    "    },",
    "    resize_on_border = true,",
    "  },",
    "})",
    "hl.config({",
    "  decoration = {",
    "    rounding = 6,",
    "    shadow = {",
    "      enabled = true,",
    "      range = 20,",
    "      render_power = 4,",
    '      color = "rgba(00000028)",',
    "    },",
    "    blur = {",
    "      enabled = true,",
    "      size = 6,",
    "      passes = 3,",
    "      special = true,",
    "      brightness = 0.90,",
    "      contrast = 0.85,",
    "      vibrancy = 0.20,",
    "      vibrancy_darkness = 0.1,",
    "      noise = 0.0,",
    "    },",
    "    dim_inactive = false,",
    "    dim_strength = 0.0,",
    "    active_opacity = 1.0,",
    "    inactive_opacity = 1.0,",
    "  },",
    "})",
    "hl.config({",
    "  group = {",
    "    col = {",
    '      border_active = { colors = { "rgba(ffffff30)", "rgba(ffffff08)" }, angle = 90 },',
    '      border_inactive = { colors = { "rgba(ffffff18)", "rgba(ffffff06)" }, angle = 90 },',
    "    },",
    "  },",
    "})"
  ].join("\n") + "\n"

  // ---- quick actions -----------------------------------------------------------

  // Tabler Icons (https://tabler.io/icons, MIT) — the whole webfont is 2.8 MB,
  // so the bundled tabler-icons.ttf is a subset holding only the 8 codepoints
  // this plugin uses (4 KB). Rebuild it from the upstream webfont when an icon
  // changes:
  //   python -m fontTools.subset tabler-icons.ttf \
  //     --unicodes=U+F201,U+EFE6,U+EA89,U+EBE6,U+FCC3,U+F452,U+F2FE,U+ED57 \
  //     --name-IDs='*' --output-file=<plugin dir>/tabler-icons.ttf
  // Codepoints come from @tabler/icons-webfont's tabler-icons.css. They
  // collide with Nerd Fonts' codicons range, so icons must render through
  // iconFont (the FontLoader below), never the default family.
  FontLoader {
    id: tablerFont
    source: Qt.resolvedUrl("tabler-icons.ttf")
    onStatusChanged: if (status === FontLoader.Error)
      console.warn("oma-swiss: failed to load tabler-icons.ttf")
  }
  readonly property string iconFont: tablerFont.name

  // Stateless one-shot capture launchers. Labels/tips are keys into the
  // strings table (rendered through tr()) so the UI language switch covers
  // them too. The record entry checks for a live recording at click time
  // (one pgrep, no polling) so the same button starts and stops. Binaries
  // are Omarchy v4 stock.
  readonly property var quickActions: [
    { id: "region", icon: "\uF201", label: "qa_region_l", tip: "qa_region_t",
      command: ["omarchy-capture-screenshot", "region"] },
    { id: "window", icon: "\uEFE6", label: "qa_window_l", tip: "qa_window_t",
      command: ["omarchy-capture-screenshot", "windows"] },
    { id: "full", icon: "\uEA89", label: "qa_full_l", tip: "qa_full_t",
      command: ["omarchy-capture-screenshot", "fullscreen"] },
    { id: "pick", icon: "\uEBE6", label: "qa_pick_l", tip: "qa_pick_t",
      command: ["sh", "-c", "pkill hyprpicker || hyprpicker -a"] },
    { id: "ocr", icon: "\uFCC3", label: "qa_ocr_l", tip: "qa_ocr_t",
      command: ["env", "OMARCHY_OCR_LANGS=eng+chi_tra", "omarchy-capture-text"] },
    { id: "record", icon: "\uF452", label: "qa_record_l", tip: "qa_record_t",
      command: ["sh", "-c",
        "pgrep -f '^gpu-screen-recorder' >/dev/null && omarchy-capture-screenrecording --stop-recording || omarchy-capture-screenrecording"] }
  ]

  function shellQuote(arg) {
    return "'" + String(arg).replace(/'/g, "'\\''") + "'"
  }

  // Quick actions must launch the way Hyprland keybindings do: detached,
  // with stdio pointed at /dev/null. A quickshell Process hands its child
  // piped stdio, and slurp reads preselections from stdin before it ever
  // maps its overlay — with a never-EOF pipe it blocks forever (the OCR
  // hang, which also stacked every later capture tool behind a dead grab).
  // setsid -f forks the tool into its own session, so it also survives
  // actionProc restarts and shell restarts cleanly.
  function launchDetached(argv) {
    actionProc.command = ["sh", "-c",
      "setsid -f " + argv.map(shellQuote).join(" ") + " </dev/null >/dev/null 2>&1"]
    actionProc.running = true
  }

  function runQuickAction(id) {
    for (var i = 0; i < quickActions.length; i++) {
      if (quickActions[i].id !== id) continue
      console.log("oma-swiss: quick action", id)
      launchDetached(quickActions[i].command)
      // Selection overlays need a clear screen — the panel gets out of the
      // way the moment an action fires.
      close()
      return
    }
    console.warn("oma-swiss: unknown quick action", id)
  }

  // ---- UI language --------------------------------------------------------------

  // Panel language: "en" or "zh" (Traditional Chinese). Every panel string
  // resolves through tr(), so flipping uiLang re-renders the whole view.
  // Persisted next to last-aspect so the choice survives reloads and every
  // monitor's instance stays in sync via the file watch.
  readonly property string langPath: stateDir + "/lang"
  property string uiLang: "en"

  // Parenthesized: a multiline object literal in a QML binding needs the
  // parens, or the leading `{` parses as a binding block.
  readonly property var strings: ({
    en: {
      sec_keyboard: "KEYBOARD",
      sec_aspect: "WINDOW ASPECT",
      sec_looks: "LOOK & FEEL",
      sec_actions: "QUICK ACTIONS",
      swap_label: "Swap Left Super / Left Alt",
      swap_desc: "Built-in keyboard only. External keyboards keep their stock mapping.",
      off: "Off",
      width: "Width", height: "Height", apply: "Apply",
      active: "Active", custom: "custom", offState: "off",
      pin_label: "Pin to hotkey",
      pin_desc: "SUPER+CTRL+BACKSPACE toggles your last ratio instead of the stock 1:1. Reversible any time.",
      looks_label: "Opinionated Looks",
      looks_desc: "Rounded corners, a translucent 5px border, soft shadow, vibrancy blur. Off = Omarchy defaults.",
      lang_tip: "切換介面語言 · Switch UI language",
      upd_tip: "v%1 is out — click to update",
      qa_region_l: "Region", qa_region_t: "Screenshot — select a region",
      qa_window_l: "Window", qa_window_t: "Screenshot — pick a window",
      qa_full_l: "Full", qa_full_t: "Screenshot — whole screen",
      qa_pick_l: "Picker", qa_pick_t: "Color picker",
      qa_ocr_l: "OCR", qa_ocr_t: "Extract text (English + Chinese)",
      qa_record_l: "Record", qa_record_t: "Start / stop screen recording"
    },
    zh: {
      sec_keyboard: "鍵盤",
      sec_aspect: "視窗比例",
      sec_looks: "外觀",
      sec_actions: "快捷動作",
      swap_label: "左 Super／左 Alt 互換",
      swap_desc: "只影響內置鍵盤；外接鍵盤保持原本設定。",
      off: "關",
      width: "寬", height: "高", apply: "套用",
      active: "目前", custom: "自訂", offState: "關閉",
      pin_label: "固定快捷鍵",
      pin_desc: "SUPER+CTRL+BACKSPACE 會改為切換你上次設定的比例（而非預設 1:1），可隨時還原。",
      looks_label: "Opinionated Looks",
      looks_desc: "圓角、5px 半透明邊框、柔和陰影、毛玻璃。關閉即還原 Omarchy 預設。",
      lang_tip: "切換介面語言 · Switch UI language",
      upd_tip: "新版本 v%1 可用，點擊更新",
      qa_region_l: "區域", qa_region_t: "截圖 — 選取區域",
      qa_window_l: "視窗", qa_window_t: "截圖 — 選取視窗",
      qa_full_l: "全螢幕", qa_full_t: "截圖 — 整個螢幕",
      qa_pick_l: "取色", qa_pick_t: "螢幕取色器",
      qa_ocr_l: "OCR", qa_ocr_t: "OCR 文字辨識（中英）",
      qa_record_l: "錄影", qa_record_t: "開始／停止螢幕錄影"
    }
  })

  function tr(key) {
    var table = strings[uiLang] || strings.en
    return table[key] !== undefined ? table[key] : strings.en[key]
  }

  function toggleLang() {
    setLang(uiLang === "en" ? "zh" : "en")
  }

  function setLang(lang) {
    if (lang !== "en" && lang !== "zh") return
    console.log("oma-swiss: ui lang", lang)
    uiLang = lang
    langFile.setText(lang)
  }

  // ---- update indicator --------------------------------------------------------

  // Upgrade badge in the panel header. Fully event-driven: the only network
  // touch is one GitHub-API call when the panel opens with a cache older than
  // 24 h — no timers, no polling, and nothing at all while the panel stays
  // closed (the badge lives in the lazily-loaded panel). Cache line:
  // "<epoch-ms> <version>"; empty version = last check failed.
  readonly property string releasesUrl: "https://github.com/glasschan/oma-swiss/releases"
  readonly property string updateCachePath: stateDir + "/update-check"
  property string localVersion: ""
  property string latestVersion: ""
  property real updateCheckedAt: 0

  readonly property bool updateAvailable: semverGreater(latestVersion, localVersion)

  function semverGreater(a, b) {
    var pa = String(a).replace(/^v/, "").split(".")
    var pb = String(b).replace(/^v/, "").split(".")
    for (var i = 0; i < 3; i++) {
      var va = parseInt(pa[i]) || 0
      var vb = parseInt(pb[i]) || 0
      if (va !== vb) return va > vb
    }
    return false
  }

  function maybeCheckUpdate() {
    if (updateProc.running) return
    if (Date.now() - updateCheckedAt < 24 * 3600 * 1000) return
    updateProc.running = true
  }

  // Badge click. Git-managed installs (marketplace / `omarchy plugin add
  // <git-url>`) self-update in place: `omarchy plugin update`, then a shell
  // restart — quickshell never re-executes the QML of a loaded plugin, so
  // without the restart the old code keeps running (pattern borrowed from
  // crmne.hyprmoncfg). Non-git installs (dev copies) fall back to the
  // releases page. launchDetached already setsid's the script, so the update
  // and restart survive their own shell being killed mid-flight.
  function handleUpdateClick() {
    launchDetached(["sh", "-c",
      'd="$HOME/.config/omarchy/plugins/glasschan.oma-swiss"; '
      + 'if [ -d "$d/.git" ]; then '
      + 'out=$(omarchy plugin update glasschan.oma-swiss --yes 2>&1) || true; '
      + 'printf %s "$out" | grep -q "^Updated" && omarchy-restart-shell; '
      + 'else xdg-open ' + releasesUrl + '; fi'])
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
    evalProc.command = ["timeout", "10", "hyprctl", "eval", expr]
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
    console.log("oma-swiss: swap toggle, swapped =", swapped)
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
      console.warn("oma-swiss: aspect needs two positive integers, got", w, h)
      return
    }
    wi = Math.min(wi, 64)
    hi = Math.min(hi, 64)
    console.log("oma-swiss: aspect set", wi + ":" + hi)
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
    else console.warn("oma-swiss: aspectToggle with no last ratio")
  }

  function setPin(on) {
    console.log("oma-swiss: pin hotkey", on ? "on" : "off")
    pinHotkey = on
    if (on) writePinProc.running = true
    else removePinProc.running = true
  }

  function setLook(on) {
    console.log("oma-swiss: opinionated looks", on ? "on" : "off")
    lookOn = on
    if (on) writeLookProc.running = true
    else removeLookProc.running = true
  }

  function clearAspect() {
    console.log("oma-swiss: aspect off")
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
    maybeCheckUpdate()
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
  //   omarchy-shell glasschan.oma-swiss toggle         swap on/off
  //   omarchy-shell glasschan.oma-swiss aspect 21 10   set ratio
  //   omarchy-shell glasschan.oma-swiss aspectOff      ratio off
  //   omarchy-shell glasschan.oma-swiss aspectToggle   off <-> last ratio
  //   omarchy-shell glasschan.oma-swiss pin            pin/unpin the hotkey
  //   omarchy-shell glasschan.oma-swiss look           opinionated looks on/off
  //   omarchy-shell glasschan.oma-swiss lang           toggle panel language EN/中
  //   omarchy-shell glasschan.oma-swiss panel          open/close popup
  IpcHandler {
    target: "glasschan.oma-swiss"
    function toggle(): void { root.toggleSwap() }
    function aspect(w: string, h: string): void { root.setAspect(w, h) }
    function aspectOff(): void { root.clearAspect() }
    function aspectToggle(): void { root.aspectToggle() }
    function pin(): void { root.setPin(!root.pinHotkey) }
    function look(): void { root.setLook(!root.lookOn) }
    function lang(): void { root.toggleLang() }
    function panel(): void { root.togglePanel() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function status(): string {
      return "swap=" + (root.swapped ? "on" : "off")
        + " aspect=" + (root.aspectOn ? root.aspectW + ":" + root.aspectH : "off")
        + " last=" + (root.lastW > 0 ? root.lastW + ":" + root.lastH : "none")
        + " pin=" + (root.pinHotkey ? "on" : "off")
        + " look=" + (root.lookOn ? "on" : "off")
        + " lang=" + root.uiLang
        + " update=" + (root.updateAvailable ? root.latestVersion : "none")
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Wash-dry-dip glyph, painted one step larger than the bar font so its
    // thin laundry-symbol strokes read solid at bar scale.
    text: "\uF2FE"
    fontFamily: tablerFont.name
    fontSize: Style.bar.iconCanvas
    // Full-opacity at rest like every other bar icon; `active` still paints
    // the urgent color while the swap is on. (The old dimmed-at-rest look
    // came from the retired super-alt-swap plugin.)
    active: root.swapped
    tooltipText: root.swapped
      ? "OmaSwiss · Super⇄Alt swapped (right-click restore, left-click tools)"
      : "OmaSwiss · left-click tools, right-click toggles Super⇄Alt"
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.togglePanel()
      else if (b === Qt.RightButton) root.toggleSwap()
    }
  }

  // A config reload reapplies or drops the toggles depending on the flag
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
  // that toggles is async, so state is queried again after it lands. The
  // coreutils `timeout` bounds a hung hyprctl without a QML timer (same
  // deadline hardening as evalProc; security-baseline finding, 2026-08-24).
  Process {
    id: queryProc
    command: ["timeout", "10", "hyprctl", "-j", "devices"]
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
        console.warn("oma-swiss: hyprctl eval failed (" + exitCode + "):",
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
        evalProc.command = ["timeout", "10", "hyprctl", "eval", expr]
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
  // Paths reach the shell only through shellQuote — a quote-bearing HOME
  // must not change the command (security-baseline finding, 2026-08-24).
  Process {
    id: writePinProc
    command: ["sh", "-c",
      "cat > " + shellQuote(root.pinPath) + " <<'OMASWISS_PIN_EOF'\n"
      + root.pinLua
      + "OMASWISS_PIN_EOF\nhyprctl reload"]
  }

  Process {
    id: removePinProc
    command: ["sh", "-c",
      "rm -f " + shellQuote(root.pinPath) + " && hyprctl reload"]
  }

  // Look state mirrors the toggle file's existence, same as the pin file:
  // watching covers our own shell writes and manual edits alike.
  FileView {
    id: lookFlagFile
    path: root.lookFlagPath
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.lookOn = true
    onLoadFailed: root.lookOn = false
  }

  // Same write-then-reload-in-one-command pattern as the pin file: the flag
  // write and the reload that applies it must not race. shellQuote on the
  // path for the same reason as writePinProc.
  Process {
    id: writeLookProc
    command: ["sh", "-c",
      "cat > " + shellQuote(root.lookFlagPath) + " <<'OMASWISS_LOOK_EOF'\n"
      + root.lookLua
      + "OMASWISS_LOOK_EOF\nhyprctl reload"]
  }

  Process {
    id: removeLookProc
    command: ["sh", "-c",
      "rm -f " + shellQuote(root.lookFlagPath) + " && hyprctl reload"]
  }

  // One-shot spawner for the quick actions. The actual tool runs detached
  // (see launchDetached); this Process only fires the setsid launch line and
  // exits immediately, so it is never busy and never kills a live tool.
  Process {
    id: actionProc
  }

  FileView {
    id: langFile
    path: root.langPath
    atomicWrites: true
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var v = (text() || "").trim()
      root.uiLang = v === "zh" ? "zh" : "en"
    }
    onLoadFailed: root.uiLang = "en"
  }

  // Local version from the co-located manifest — one static read, no watch.
  FileView {
    id: manifestFile
    path: Qt.resolvedUrl("manifest.json").toString().replace("file://", "")
    printErrors: false
    onLoaded: {
      var m = /"version"\s*:\s*"([^"]+)"/.exec(text() || "")
      if (m) root.localVersion = m[1]
    }
  }

  // Update cache, watched so every monitor's badge agrees (same pattern as
  // the lang file). A stale entry still shows its cached version; staleness
  // only gates the next network check.
  FileView {
    id: updateCacheFile
    path: root.updateCachePath
    atomicWrites: true
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var m = /^(\d+)(?:\s+(\S*))?/.exec((text() || "").trim())
      if (!m) return
      root.updateCheckedAt = parseInt(m[1]) || 0
      root.latestVersion = m[2] || ""
    }
  }

  // One-shot release check, fired only by maybeCheckUpdate (panel open +
  // stale cache). The result — success or failure — restamps the cache, so
  // the worst case is one bounded (--max-time) request per day.
  Process {
    id: updateProc
    command: ["sh", "-c",
      "curl -fsS --max-time 5 https://api.github.com/repos/glasschan/oma-swiss/releases/latest"]
    stdout: StdioCollector {
      id: updateOut
      waitForEnd: true
    }
    stderr: StdioCollector { waitForEnd: true }
    onExited: {
      var m = /"tag_name"\s*:\s*"v?([^"]+)"/.exec(updateOut.text || "")
      updateCacheFile.setText(Date.now() + " " + (m ? m[1] : ""))
    }
  }

  Process {
    id: ensureStateDir
    command: ["mkdir", "-p", root.stateDir]
  }
}
