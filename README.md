# OmaSwiss

[![CI](https://github.com/glasschan/oma-swiss/actions/workflows/ci.yml/badge.svg)](https://github.com/glasschan/oma-swiss/actions/workflows/ci.yml)

A minimal-resource Omarchy bar plugin combining four Hyprland tools behind one icon:

- **Super ⇄ Alt swap** — swap Left Super and Left Alt on the built-in laptop keyboard (external keyboards keep their stock mapping). Successor of `glasschan.super-alt-swap`.
- **Single-window aspect ratio** — constrain the lone window to a chosen ratio: presets (1:1, 4:3, 3:2, 16:9), any custom `W:H` up to 64, or off.
- **Opinionated Looks** — one toggle for rounded corners, hairline borders, soft shadow and vibrancy blur; off restores Omarchy defaults.
- **Quick actions** — one-click region/window/fullscreen screenshot, color picker, OCR (English + Chinese), and start/stop screen recording.
- **中／EN** — a top-right button switches the whole panel between English and 繁體中文.

## Bar usage

- **Left-click** the OmaSwiss icon: opens the tools popup.
- **Right-click**: instant Super⇄Alt toggle, the same one-click action the old plugin had.

The aspect tool writes the stock toggle flag
(`~/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua`) directly with your chosen ratio, so it survives reloads and logins, and the stock `SUPER+CTRL+BACKSPACE` binding coexists — the panel follows whatever that binding writes.

## CLI (also bindable to hotkeys)

```bash
omarchy-shell glasschan.oma-swiss toggle         # Super⇄Alt on/off
omarchy-shell glasschan.oma-swiss aspect 21 10  # custom ratio
omarchy-shell glasschan.oma-swiss aspectOff     # ratio off
omarchy-shell glasschan.oma-swiss aspectToggle  # off <-> last ratio
omarchy-shell glasschan.oma-swiss pin           # pin/unpin the hotkey
omarchy-shell glasschan.oma-swiss look          # opinionated looks on/off
omarchy-shell glasschan.oma-swiss lang          # toggle panel language EN/中
omarchy-shell glasschan.oma-swiss panel         # open/close popup
omarchy-shell glasschan.oma-swiss status        # current state
```

## Pinning the hotkey (optional)

Stock `SUPER+CTRL+BACKSPACE` always toggles its own fixed 1:1 and knows
nothing about ratios set here. The panel's **Pin to hotkey** toggle changes
that: while pinned, the hotkey toggles **your last ratio** instead — set 16:9
in the panel, and the hotkey cycles off ⇄ 16:9; pick another ratio and the
hotkey follows.

Pinning writes one user-owned toggle file
(`~/.local/state/omarchy/toggles/hypr/oma-swiss-hotkey.lua`) that
re-registers the binding on every config load. It touches nothing in
`~/.config/hypr`, survives `omarchy update` and `omarchy refresh hyprland`,
and unpinning restores the previous binding exactly. The Omarchy menu's
"1-Window Ratio" entry is not affected by pinning (it keeps its stock
meaning); this panel reflects whatever any of them does.

## Opinionated Looks

The looks toggle writes one user-owned toggle file
(`~/.local/state/omarchy/toggles/hypr/opinionated-looks.lua`) holding the
static look — `hl.config` for rounding, borders, shadow and blur. It loads
after user configs, so it overrides `looknfeel.lua` while present and
Hyprland drops back to Omarchy defaults when it is gone. Animations are
deliberately not overridden (a former spring-animation set was removed as
indistinguishable from stock). The file carries the current live tuning
(border 5, rounding 6); edit `lookLua` in `BarWidget.qml` to change what
"on" means.

## Icons

All icons come from [Tabler Icons](https://tabler.io/icons) (MIT). The full
webfont is 2.8 MB, so the plugin bundles a 7 KB subset (`tabler-icons.ttf`,
loaded via FontLoader) holding just the glyphs it uses — keeping the idle
footprint at file-watcher level.

## Resource design

The plugin runs inside the existing Omarchy shell process — no daemon, no service. Everything is event-driven: no timers, no polling, no background refresh. The popup is created lazily on first open, and its window unmaps when closed. Idle cost is one bar icon and four file watchers. Quick actions spawn fully detached (`setsid`), exactly like keybinding launches.

## Install / Remove

```bash
omarchy plugin add <this repo's git URL>    # install
omarchy plugin remove glasschan.oma-swiss   # remove
```

Turn every toggle off before removing (or delete the files afterwards): the
flag files under `~/.local/state/omarchy/toggles/hypr/` — `super-alt-swap.lua`,
`single-window-aspect-ratio.lua`, `opinionated-looks.lua`,
`oma-swiss-hotkey.lua` — are what re-apply the settings on every Hyprland
config load, and they outlive the plugin.

## Dependencies

Everything is Omarchy v4 stock: Hyprland 0.56+ (Lua config),
`omarchy-capture-screenshot` (slurp), `omarchy-capture-text` (OCR),
`omarchy-capture-screenrecording` (gpu-screen-recorder), and `hyprpicker`.
MIT.
