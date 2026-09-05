# Implementation Brief: Fcitx5 Candidate-Window Theming → OmaSwiss

**Status:** ABSORBED into OmaSwiss as the "Fcitx5 candidate theme" toggle (repo-root `fcitx5-theme.sh` + BarWidget/ToolPanel, v0.5.0). §4 below records the two settled amendments the implementation made to the original proposal; §1–§3 stay as the historical record of the standalone source and its hard-won facts.
**Source of truth today:** the OmaSwiss implementation on this branch (`fcitx5-theme.sh`, `BarWidget.qml`). The standalone `~/omarchy-custom-scripts/setup-fcitx5-theme.sh` is deprecated — it now prints a pointer and exits 1.
**Purpose of this doc:** everything another agent needs to understand the absorbed feature without re-deriving the hard-won facts. Read this fully before writing code.

---

## 0. DOX notice

This repo uses the DOX AGENTS.md hierarchy (root `AGENTS.md`). Before editing, walk the DOX chain for every path you touch, and do a DOX pass after the feature lands (new tool = likely updates to the root child index and `docs/agents/domain.md`).

## 1. What the feature does today (live, user-approved)

The fcitx5-rime candidate window is themed to match the active Omarchy theme + the OmaSwiss "Opinionated Looks" design language:

- Colors follow the Omarchy palette (semantic tokens), retinted **automatically on every `omarchy-theme-set`**.
- Rounded corners (7px) + translucent white rim (`#ffffff1c`) baked into a 9-patch background PNG — because **neither fcitx5 nor Hyprland layer rules support corner rounding** (verified below).
- Rounded (5px) highlight box behind the selected candidate.
- Vibrancy blur on the popup via a Hyprland layer rule.
- Font: `OPPO Sans 4.0 11` (installed by `omarchy-custom-scripts/setup-fonts.sh`).

### Current architecture (standalone)

```
omarchy-theme-set <theme>
  → bakes palette into ~/.local/state/omarchy/current/theme/colors.toml
  → omarchy-hook theme-set <slug>
      → ~/.config/omarchy/hooks/theme-set.d/fcitx5        (hook, calls:)
          ~/.local/bin/omarchy-theme-set-fcitx5            (generator)
              → omarchy-theme-color <key> [fallback]       (semantic token resolver)
              → magick renders background.png / highlight.png with the palette
              → writes ~/.local/share/fcitx5/themes/omarchy/theme.conf
              → systemctl --user restart omarchy-fcitx5.service
  (once, at install time)
  ~/.config/fcitx5/conf/classicui.conf                     (Theme=omarchy, font)
  ~/.config/hypr/looknfeel.lua                             (marker block: layer rule blur)
```

Everything above is generated/installed by `setup-fcitx5-theme.sh` (`-i/-f/-u/-s/-h`; idempotent; registered in that repo's README/CLAUDE.md/test-idempotency.sh). Read that script first — the generator is embedded verbatim inside it and is the canonical implementation.

## 2. Hard-won facts — do not re-learn these the hard way

1. **`~/.config/fcitx5/conf/*.conf` files are section-less `key=value`.** A `[General]` header makes fcitx5 file every key under a section it never reads → silent fallback to defaults (cost an hour: popup looked "unthemed" through two restarts because `DarkTheme` fell back to `default-dark`).
2. **`themes/*/theme.conf` DOES use INI sections** (`[InputPanel]`, `[InputPanel/Background]`, `[Menu/…]`). Different format family, same directory tree.
3. **Reload = restart the systemd user service `omarchy-fcitx5.service`.** `fcitx5-remote -r` alone did not make classicui re-read theme/config. The service has `Restart=always`; restart is <1s.
4. **Proof of which theme is actually loaded:** `stat -c '%x'` the theme files — whichever `theme.conf` has a fresh **atime** is the one classicui read. This was the decisive debugging tool.
5. **`wtype` bypasses the IME** on Hyprland (virtual keyboard → raw text). Synthetic typing cannot summon the candidate window; only real user keystrokes. Do not try to automate visual testing of the popup.
6. **Hyprland 0.56.2 layer rules have NO `rounding`** (`hl.layer_rule({match={namespace="fcitx"}, rounding=6})` → `hl.layer_rule: unknown field 'rounding'`), and libclassicui has no native rounding key. Corner rounding is only achievable via 9-patch PNG backgrounds.
7. **Layer-surface rules that DO work:** blur, via `hl.layer_rule({ match = { namespace = "fcitx" }, blur = true })`. Rounding/shadow are not available for layer surfaces.
8. **fcitx5's Highlight Margin does DOUBLE DUTY**: 9-patch slice AND outward expansion of the highlight box. Changing the radius moves the box edges. Geometry rule that keeps the highlight off the rim: **`[InputPanel/ContentMargin]` (8) > `[InputPanel/Highlight]` Margin (6)**; the translucent rim occupies the outer 2px, so the highlight stops 2px short of the window edge and never covers it.
9. **One highlight style applies to ALL candidate rows** — per-row rounding is impossible. Uniform 5px is the approved compromise.
10. **fcitx5 silently ignores unknown INI sections/keys** (that's how bug #1 hid). Also makes shotgun-testing a section name safe: both `[InputPanel/Highlight]` and `[InputPanel/HighlightBackground]` are written; whichever is real takes effect.
11. **`omazed` is unrelated** — it's a Zed-editor theme syncer that also lives in `theme-set.d`. Don't confuse it with OmaSwiss or touch its hook block (`# >>> omazed hook - do not edit >>>`).
12. **User taste (binding):** compact padding; the inflated version (ContentMargin 14 + pill radius 12) was rejected as "一啲都唔好睇". Do not enlarge paddings/boxes. Font is exactly `OPPO Sans 4.0` (family name; "OPPO Sans" won't match), size 11.

## 3. Theme.conf reference (generated, annotated)

Location: `~/.local/share/fcitx5/themes/omarchy/theme.conf`. Full text is generated by the generator in `setup-fcitx5-theme.sh`; key points:

| Omarchy token (`omarchy-theme-color`) | fcitx5 key | Notes |
|---|---|---|
| `background` | `[InputPanel/Background] Color`, `[Menu/Background] Color` | popup base (also the PNG fill) |
| `lighter_background` | `[InputPanel/Highlight] Color`, `[InputPanel] HighlightBackgroundColor`, `[Menu/Highlight] Color` | selected-candidate fill (also PNG fill) |
| `foreground` | `[InputPanel] NormalColor` | candidate text |
| `bright_foreground` | `[InputPanel] HighlightColor` | preedit text |
| `accent` | `[InputPanel] HighlightCandidateColor` | selected candidate text |
| `muted` | `[Menu/Separator] Color` | divider only |
| *(fixed)* `#ffffff1c` | BorderColor (fallback path only) | OmaSwiss gradient midpoint |

Every token lookup passes a fallback so missing keys degrade gracefully; light themes (e.g. catppuccin-latte) work unchanged.

### The two PNGs (rendered per retint with `magick`)

```bash
# window: rounded 7px + 2px translucent rim baked (OmaSwiss rim = gradient
# rgba(ffffff30)→rgba(ffffff08); fcitx5 has no gradient border → midpoint #ffffff1c)
magick -size 96x96 xc:none -stroke "#ffffff1c" -strokewidth 2 \
  -fill "$bg" -draw "roundrectangle 1,1 94,94 7,7" "PNG32:$theme_dir/background.png"

# highlight: rounded 5px, plain fill
magick -size 64x64 xc:none -fill "$bg_light" \
  -draw "roundrectangle 0,0 63,63 5,5" "PNG32:$theme_dir/highlight.png"
```

9-patch slices: background Margin=10, highlight Margin=6. Slices are fixed 1:1 pixels (no adaptive scaling) — radii are absolute. If `magick` is absent, fall back to square `Color=` + `BorderColor=#ffffff1c BorderWidth=2`.

### classicui.conf (verbatim — note: NO section header)

```ini
Theme=omarchy
DarkTheme=omarchy
UseDarkTheme=False
PerScreenDPI=True
Font="OPPO Sans 4.0 11"
```

### Hyprland piece (marker block in `~/.config/hypr/looknfeel.lua`)

```lua
-- BEGIN fcitx5 candidate blur (setup-fcitx5-theme.sh)
hl.layer_rule({ match = { namespace = "fcitx" }, blur = true })
-- END fcitx5 candidate blur (setup-fcitx5-theme.sh)
```

Note: only `hyprland.lua`'s five `require()` modules are live in Omarchy v4 — sibling `*.conf` files are legacy and never loaded.

## 4. Settled integration design (as implemented, with two amendments)

Follow the existing toggle contract ("one flag file owns the feature; absent = stock exactly"). Differences from the Hyprland toggles: fcitx5 theming spans **three systems** (fcitx5 files, an Omarchy hook, one Hyprland layer rule), so the flag file alone can't carry the artifacts — but it DOES carry both the Hyprland piece and the plugin state. Two amendments were made to the original proposal below, both settled before implementation:

- **AMENDMENT 1 — the blur flag replaces the looknfeel.lua marker block.** The flag `~/.local/state/omarchy/toggles/hypr/oma-swiss-fcitx5.lua` holds exactly one line, `hl.layer_rule({ match = { namespace = "fcitx" }, blur = true })`. Omarchy require_all's every lua in `toggles/hypr/`, and `hl.layer_rule` is available there (verified), so the file's content IS the live Hyprland artifact while its existence doubles as the plugin's state (FileView watch + `status`). No marker block in `looknfeel.lua` is ever written by OmaSwiss; the plugin only ever STRIPS the standalone installer's legacy marker block (on every apply and unapply).
- **AMENDMENT 2 — the separate `toggles/fcitx5-candidate-theme/ON` state marker is dropped.** One boolean, one file: flag exists ⇔ feature on. The `toggles/hypr/` directory is require_all'd as lua, which is exactly why the single file can carry both roles — a non-lua state file there was the only reason the original proposal wanted a second location.

### Implemented contract

- **Flag:** `~/.local/state/omarchy/toggles/hypr/oma-swiss-fcitx5.lua` (see the two amendments above). Apply writes it LAST; unapply removes it FIRST.
- **ON** = `fcitx5-theme.sh apply`: back up the user's own `classicui.conf` once (`classicui.conf.pre-oma-swiss`, cp -p, never overwritten), install the section-less `classicui.conf`, install the `theme-set.d/fcitx5` hook, legacy cleanup, write the flag + `hyprctl reload`, generate for the current palette, restart the service (guarded — a stopped `omarchy-fcitx5.service` is never force-started). Idempotent throughout.
- **OFF** = `fcitx5-theme.sh unapply`: remove flag + reload, remove hook, restore or remove `classicui.conf` (only when it contains `Theme=omarchy` — never touch a file we don't own), `rm -rf` the theme dir, legacy cleanup, guarded service restart.
- **Retint decision (a) stands** — the Omarchy hook is kept, but its one line now invokes the plugin's own co-located script: `sh "$HOME/.config/omarchy/plugins/glasschan.oma-swiss/fcitx5-theme.sh" generate`. The generator no longer lives in `~/.local/bin`.
- **QML:** `setFcitx(on)` in `BarWidget.qml` follows the looks/pin family (optimistic flip + dedicated `fcitxProc` with a `running` reentrancy guard + flag-watcher correction) — NOT flagEval/EvalQueue (no single hyprctl eval can carry three systems) and NOT launchDetached (the toggle must stay guard-interruptible). The Process runs `["timeout", "90", "sh", fcitxScriptPath, "apply"|"unapply"]` — positional argv only, nothing QML-concatenated. The row sits between Opinionated Looks and pin in the toggle group.

### Deprecation (done)

`~/omarchy-custom-scripts/setup-fcitx5-theme.sh` now only prints a pointer (use the OmaSwiss toggle; remove the integration with `sh ~/.config/omarchy/plugins/glasschan.oma-swiss/fcitx5-theme.sh unapply`) and exits 1; that repo's README/CLAUDE.md/test-idempotency.sh mark it deprecated/skipped. The `unapply` above and the script's legacy cleanup are the two-owners escape hatch.

## 5. Verification checklist (implemented contract)

1. Toggle ON → the flag file exists (`~/.local/state/omarchy/toggles/hypr/oma-swiss-fcitx5.lua`, exactly one line: `hl.layer_rule({ match = { namespace = "fcitx" }, blur = true })` — the flag IS the Hyprland artifact per Amendment 1; no marker block is ever written) and the artifacts exist (`~/.local/share/fcitx5/themes/omarchy/theme.conf`, section-less `classicui.conf` with `Theme=omarchy`, the `theme-set.d/fcitx5` hook); `systemctl --user is-active omarchy-fcitx5.service` → active.
2. Type (real keystrokes only — see fact #5): popup shows current palette, rounded corners, translucent rim, blur, rounded highlight; highlight stays inside the rim.
3. `omarchy-theme-set <another-theme>` → popup retints automatically (PNGs re-rendered). Verified across tokyo-night → ristretto → miasma during development.
4. `stat -c '%x' ~/.local/share/fcitx5/themes/omarchy/theme.conf` — fresh atime after a popup proves classicui loaded it (fact #4).
5. Toggle OFF → the flag and all artifacts gone (classicui.conf restored/removed only when BOTH of the script's fingerprints match — `Theme=omarchy` AND `Font="OPPO Sans 4.0 11"`; a foreign file is left untouched with a warning); popup back to fcitx5 default; no orphan hook entries; `looknfeel.lua` keeps no leftover legacy marker lines (the standalone block is stripped on every apply AND unapply).
6. Idempotency: run `fcitx5-theme.sh apply` twice → byte-identical artifacts, existing backup never clobbered.

## 6. File map

| Path | Role |
|---|---|
| OmaSwiss repo: `fcitx5-theme.sh` (repo root) | **canonical generator + apply/unapply — source of truth; read first** |
| `~/omarchy-custom-scripts/setup-fcitx5-theme.sh` | deprecated pointer stub only — prints a pointer to the OmaSwiss toggle and exits 1 |
| `~/.local/share/fcitx5/themes/omarchy/` | generated theme (`theme.conf`, `background.png`, `highlight.png`, stock arrow/next/prev/radio.png) |
| `~/.config/fcitx5/conf/classicui.conf` | section-less addon config |
| `~/.config/omarchy/hooks/theme-set.d/fcitx5` | retint hook (one line invoking the repo script's `generate`) |
| `~/.local/state/omarchy/toggles/hypr/oma-swiss-fcitx5.lua` | the flag: one-line `hl.layer_rule` blur; existence = feature state (Amendment 1) |
| `~/.config/hypr/looknfeel.lua` | never written by OmaSwiss — only the standalone installer's legacy marker block is stripped from it (every apply and unapply) |
| `~/.local/state/omarchy/current/theme/colors.toml` | palette single source (read via `omarchy-theme-color`) |
| OmaSwiss: `BarWidget.qml` (toggle Process + flag watch), `ToolPanel.qml` (toggle row) | integration points |
