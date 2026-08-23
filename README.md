# Hypr Toolbox

A minimal-resource Omarchy bar plugin combining two Hyprland toggles behind one icon:

- **Super ⇄ Alt swap** — swap Left Super and Left Alt on the built-in laptop keyboard (external keyboards keep their stock mapping). Successor of `glasschan.super-alt-swap`.
- **Single-window aspect ratio** — constrain the lone window to a chosen ratio: presets (1:1, 4:3, 3:2, 16:9), any custom `W:H` up to 64, or off.

## Bar usage

- **Left-click** the 󱕉 icon: opens the toolbox popup.
- **Right-click**: instant Super⇄Alt toggle, the same one-click action the old plugin had.

The aspect tool writes the stock toggle flag
(`~/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua`) directly with your chosen ratio, so it survives reloads and logins, and the stock `SUPER+CTRL+BACKSPACE` binding coexists — the panel follows whatever that binding writes.

## CLI (also bindable to hotkeys)

```bash
omarchy-shell glasschan.hypr-toolbox toggle        # Super⇄Alt on/off
omarchy-shell glasschan.hypr-toolbox aspect 21 10  # custom ratio
omarchy-shell glasschan.hypr-toolbox aspectOff     # ratio off
omarchy-shell glasschan.hypr-toolbox panel         # open/close popup
omarchy-shell glasschan.hypr-toolbox status        # current state
```

## Resource design

The plugin runs inside the existing Omarchy shell process — no daemon, no service. Everything is event-driven: no timers, no polling, no background refresh. The popup is created lazily on first open, and its window unmaps when closed. Idle cost is one bar icon and two file watchers.

## Install

```bash
omarchy plugin add <this repo's git URL>
```

Requires Hyprland 0.56+ (Lua config); Omarchy ships it. MIT.
