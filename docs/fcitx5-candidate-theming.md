# Implementation Brief: Fcitx5 Candidate-Window Theming → OmaSwiss

**Status:** working standalone implementation, to be absorbed into OmaSwiss as a toggle.
**Source of truth today:** `~/omarchy-custom-scripts/setup-fcitx5-theme.sh` (approved by user 2026-09-06, "呢個版非常好").
**Purpose of this doc:** everything another agent needs to move this feature into OmaSwiss without re-deriving the hard-won facts. Read this fully before writing code.

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

## 4. Suggested OmaSwiss integration design

Follow the existing toggle contract ("one flag file owns the feature; absent = stock exactly"). Differences from the Hyprland toggles: fcitx5 theming spans **three systems** (fcitx5 files, an Omarchy hook, one Hyprland layer rule), so the flag file alone can't carry it — the toggle drives an apply/unapply routine.

### Proposed contract

- **State file:** `~/.local/state/omarchy/toggles/fcitx5-candidate-theme/ON` (new toggles subdir; the existing `toggles/hypr/` dir is Hyprland-lua-specific and is `require_all`-ed as lua, so don't put non-lua state there).
- **ON** = install: theme dir (regenerate for current palette), `classicui.conf`, `theme-set.d/fcitx5` hook, looknfeel.lua marker block (or an equivalent toggles-hypr lua if you prefer keeping the layer rule in the toggle system), restart service.
- **OFF** = unapply everything: remove theme dir, remove `classicui.conf`, remove hook, strip marker block, restart service + `hyprctl reload`. User ends up exactly on fcitx5/Hyprland stock.
- **QML:** new toggle row in `ToolPanel.qml` + handler in `BarWidget.qml`, same shape as the looks toggle (`lookFlagPath`/`lookOn`/`lookLua` pattern). Reuse `Quickshell.process`/`DesktopEntries` invocation style already in the codebase for running the generator.

### The retint question (design decision to make)

The feature must re-run the generator on every `omarchy-theme-set`. Two viable mechanisms:

- **(a) Keep the Omarchy hook** (`~/.config/omarchy/hooks/theme-set.d/fcitx5` → generator). Proven, works even if the panel isn't loaded, zero runtime cost for the plugin. Con: it's a file outside OmaSwiss's own state dir; install/uninstall must manage it cleanly and it must coexist with the `omazed` block in `hooks/theme-set.d/` (separate file, no conflict).
- **(b) Watch the palette in QML** (`Quickshell.FileView` with `watchChanges` on `~/.local/state/omarchy/current/theme/colors.toml`, then run the generator via Process). Keeps 100% of the feature inside OmaSwiss, no hook files. Con: only works while the plugin is loaded (it always is — the bar icon never sleeps), and duplicates what the Omarchy hook system already does.

Recommendation: **(a)** — the hook is the Omarchy-native extension point (that's literally what `theme-set.d/` is for), survives relogins and headless theme switches, and OmaSwiss merely owns installing/uninstalling it. The generator itself must stay a standalone executable (it is today) so the hook is one line.

### Deprecation

Once OmaSwiss owns the feature, remove/retire `setup-fcitx5-theme.sh`'s installed artifacts (`-u`) to avoid two owners of the same files, and delete the script from `omarchy-custom-scripts` (or leave a pointer). Both implementations writing the same hook/theme is the main hazard of this migration.

## 5. Verification checklist

1. Toggle ON → all four artifacts exist (`theme.conf`, `classicui.conf`, hook, marker block); `systemctl --user is-active omarchy-fcitx5.service` → active.
2. Type (real keystrokes only — see fact #5): popup shows current palette, rounded corners, translucent rim, blur, rounded highlight; highlight stays inside the rim.
3. `omarchy-theme-set <another-theme>` → popup retints automatically (PNGs re-rendered). Verified across tokyo-night → ristretto → miasma during development.
4. `stat -c '%x' ~/.local/share/fcitx5/themes/omarchy/theme.conf` — fresh atime after a popup proves classicui loaded it (fact #4).
5. Toggle OFF → all artifacts gone; popup back to fcitx5 default; no orphan hook entries; `looknfeel.lua` has no leftover marker lines.
6. Idempotency: apply twice → byte-identical artifacts (the standalone repo's `test-idempotency.sh setup-fcitx5-theme.sh` pattern).

## 6. File map

| Path | Role |
|---|---|
| `~/omarchy-custom-scripts/setup-fcitx5-theme.sh` | current source of truth (generator embedded); read first |
| `~/.local/share/fcitx5/themes/omarchy/` | generated theme (`theme.conf`, `background.png`, `highlight.png`, stock arrow/next/prev/radio.png) |
| `~/.config/fcitx5/conf/classicui.conf` | section-less addon config |
| `~/.config/omarchy/hooks/theme-set.d/fcitx5` | retint hook |
| `~/.config/hypr/looknfeel.lua` | marker block with `hl.layer_rule` blur |
| `~/.local/state/omarchy/current/theme/colors.toml` | palette single source (read via `omarchy-theme-color`) |
| OmaSwiss: `BarWidget.qml` (looks toggle pattern), `ToolPanel.qml` (toggle rows) | integration points |
