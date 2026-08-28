# DOX framework

- DOX is highly performant AGENTS.md hierarchy installed here
- Agent must follow DOX instructions across any edits

## Core Contract

- AGENTS.md files are binding work contracts for their subtrees
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it

## Read Before Editing

1. Read the root AGENTS.md
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules
7. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX

Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.

## Update After Editing

Every meaningful change requires a DOX pass before the task is done.

Update the closest owning AGENTS.md when a change affects:

- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- AGENTS.md creation, deletion, move, rename, or index contents

Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen.

## Hierarchy

- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index
- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific and practical it must be

## Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty
- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists

Default section order:
- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

## Style

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

## Closeout

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## User Preferences

When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md

## Purpose

- Source repo of the Omarchy shell plugin `glasschan.oma-swiss` (display name OmaSwiss; GitHub repo `glasschan/oma-swiss`). One bar icon, four Hyprland tools: laptop Super⇄Alt swap, single-window aspect ratio (presets + custom), Opinionated Looks toggle, and quick capture actions (screenshots, color picker, OCR, recording). Successor of `glasschan.super-alt-swap` (that repo is deprecated); renamed from `glasschan.hypr-toolbox` on 2026-08-24 before any publication — marketplace IDs are permanent once listed.
- Target marketplace: omarchyplugins.com (registry `HANCORE-linux/omarchy-plugin-marketplace`; submission via its GitHub issue form). Rules as of 2026-08-24: no repo-name prefix required; plugin id must be globally unique and outside the reserved `omarchy.*` namespace; README must carry install and removal instructions plus a dependencies section; preview image optional. Intended submission: category `Widgets`, tags `bar`, `hyprland`, `quickshell`.
- The plugin's founding tenet: **ultra-low CPU and RAM usage**. Idle cost must stay at "one bar icon plus a few file watchers" — every feature added to this repo must preserve that. The Work Guidance resource floor is how this tenet is enforced.
- Deployed copy lives in `~/.config/omarchy/plugins/glasschan.oma-swiss/`; after editing files there, sync changes back to this repo.

## Ownership

- Root-owned files: `README.md`, `README.zh-Hant.md`, `LICENSE`, `manifest.json`, `BarWidget.qml`, `ToolPanel.qml`, `EvalQueue.qml`, `tabler-icons.ttf` (subset), `preview.png` (73:35 marketing cover), `panel.png` (raw panel screenshot), `design/cover.html` (cover source), `.github/workflows/*`, `scripts/check-submission.sh`, `scripts/check-hardening.sh`, `.gitignore`, and root-level project documentation.

## Local Contracts

- Plugin id `glasschan.oma-swiss`, kind `bar-widget`, single entry point `BarWidget.qml`.
- `BarWidget.qml` owns all state and actions; `ToolPanel.qml` is a pure view injected with `hostWidget` (consumes only the host members it names, via `t()` for strings). No state may live in the panel. The queued-eval slot lives in `EvalQueue.qml` — one module owning the single-slot queue, its eval runner and the completion notification; its interface is `enqueue(expr, notify, glyph)`.
- Flag files are the source of truth and must stay byte-compatible:
  - Swap: `~/.local/state/omarchy/toggles/hypr/super-alt-swap.lua` (same path and Lua content as the retired super-alt-swap plugin).
  - Aspect: `~/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua` — written directly with the chosen ratio; never call `omarchy-hyprland-toggle` for it (its "on" copies stock 1:1).
  - Looks: `~/.local/state/omarchy/toggles/hypr/opinionated-looks.lua` — exists = Opinionated Looks on. Content is static-only `hl.config` (rounding/borders/shadow/blur; `lookLua` in BarWidget.qml carries the user's live tuning: border 5, rounding 6, gradient rim (bright top), blur size 6 / vibrancy 0.20 / vibrancy_darkness 0.1, shadow range 20 / power 4 / `rgba(00000028)` — re-tuned 2026-08-24). Animations are deliberately NOT overridden — a former macSpring `hl.curve`/`hl.animation` set was removed on 2026-08-24 as indistinguishable from stock; do not reintroduce animation overrides without the user asking. User-facing copy must never present the look as macOS-inspired or name macOS/Apple/Liquid Glass — macOS (27 Golden Gate as of 2026-08) is an internal research direction only (user rule 2026-08-24). A `setup-looknfeel.sh`-style marker block in `~/.config/hypr/looknfeel.lua` must not coexist with this flag: with the flag absent the block would keep the look applied and break the off state. Ownership migrated to the flag file on 2026-08-24.
- Custom-ratio memory: `~/.local/state/glasschan.oma-swiss/last-aspect`, plain `"w h"` text — the LAST ratio set (preset or custom); drives panel prefill and `aspectToggle`.
- UI language: `~/.local/state/glasschan.oma-swiss/lang`, `"en"` or `"zh"`. All panel strings live in the `strings` table in BarWidget.qml and resolve through `tr()` — the panel stays a pure view; adding a string means adding it to every language block. zh copy must be standard written Chinese (書面語), never Cantonese colloquialisms (嘅／唔係／揀／成個…) — user rule since 2026-08-24.
- Update indicator: `~/.local/state/glasschan.oma-swiss/update-check`, one line `<epoch-ms> <version>` (version optional — empty = last check failed; the parser must treat it that way). The panel-header ↑ badge (left of the language switch, `Color.urgent`, click updates the plugin — git-managed installs run `omarchy plugin update --yes`; the shell hot-reloads plugin changes itself (debounced, watching the plugin dir), so no restart is issued — a forced `omarchy-restart-shell` during that reload raced the in-flight component creation and crashed the shell (issue #6); non-git dev copies fall back to opening `releasesUrl`) shows while the GitHub latest release semver-exceeds the co-located manifest version. The only network touch is one `curl --max-time 5` fired from `open()` when the cache is older than 24 h — no timers, no polling, nothing while the panel is closed (resource floor intact); monitor instances share state through the file watch. `status` reports `update=<version>|none`.
- Hotkey pin: `~/.local/state/omarchy/toggles/hypr/oma-swiss-hotkey.lua` — exists = pinned. Its static Lua does `hl.unbind("SUPER + CTRL + BACKSPACE")` + `o.bind(..., "omarchy-shell glasschan.oma-swiss aspectToggle")`; toggles load after user bindings, so the pinned bind wins while the file exists and removal restores whatever was bound before (stock or the user's own override). The write and the activating `hyprctl reload` MUST stay one shell command (FileView.setText is async — a separate reload Process would race).
- IPC surface (CLI = `omarchy-shell glasschan.oma-swiss <fn>`, exact function names, no hyphen mapping): `toggle` (swap), `aspect w h`, `aspectOff`, `aspectToggle`, `pin`, `look`, `lang`, `panel`, `open`, `close`, `status`. Quick actions have no IPC — they are panel buttons only (they close the panel on fire).
- Bar interactions: left-click opens the popup, right-click toggles the swap directly.

## Work Guidance

- Resource floor is a hard design rule: no timers (except the 100 ms configreload debounce), no polling, no background services. File watching via FileView `watchChanges` only; hyprctl work through the single queued-eval slot in `EvalQueue.qml` so rapid clicks land in order. The swap/aspect flag writes/removals ride INSIDE the eval expressions (eval Lua carries io/os, verified 2026-08-24) — the atomic flag-mutation invariant is encoded once in `flagEval()` (BarWidget.qml); file and compositor state move as one and the old setText/rm race (flag file disagreeing with live state until a reload reasserted the stale side) cannot recur; a rejected eval writes nothing.
- Security hardening (marketplace baseline findings, 2026-08-24): every QML-derived path that reaches a `sh -c` command MUST go through `shellQuote()` — never raw single-quote concatenation (a quote-bearing HOME must not change the command). Every compositor/dbus subprocess carries a deadline — `timeout` in Process argv AND inside `sh -c` strings (quickshell ignores `running=true` on a busy Process, so an unbounded one silently swallows later toggles); `curl` uses `--max-time`; the update check takes an `flock` so concurrent monitor instances never duplicate a fetch. The release job executes no network-fetched code (the unpinned upstream validator lives only in unprivileged CI, where the moving pin is intentional) and both workflows pin `actions/checkout` by full SHA. FileView has no size/FIFO bound API: reading the plugin's own user-writable state files unbounded is an accepted risk (local write access to `$XDG_STATE_HOME` already owns the session); do not add polling to "fix" it.
- Quick actions are the one sanctioned exception to the queued-eval rule: stateless one-shot launches. They MUST go through `launchDetached` (`setsid -f ... </dev/null >/dev/null 2>&1`): quickshell Process children inherit piped stdio, and tools that read stdin block forever — slurp reads preselections from stdin before mapping its overlay, which was the OCR hang that stacked every later capture tool behind a dead grab. Detached also means no tool is ever killed by an actionProc restart or a shell restart. The panel closes when an action fires (selection overlays need a clear screen). The record action chooses start vs stop with a click-time `pgrep '^gpu-screen-recorder'` — a single check, never a loop.
- All plugin icons (bar + panel) are Tabler Icons (MIT, https://tabler.io/icons) rendered from the bundled `tabler-icons.ttf` — a 7 KB subset (upstream webfont is 2.8 MB) loaded once via FontLoader; controls must set `fontFamily` to `iconFont`, because Tabler codepoints collide with Nerd Fonts' codicons range. Adding/changing an icon: look up the codepoint in @tabler/icons-webfont's `tabler-icons.css`, add it to the subset command documented in BarWidget.qml, rebuild with `fontTools.subset`, and redeploy the font. The 中/EN language button is plain text (system font fallback) and notification glyphs stay Nerd Font — the notification daemon renders with system fonts and cannot see the plugin's FontLoader. Custom SVG bar icons were tried and rejected (optical misalignment vs. font glyphs); keep the bar icon a font glyph.
- After any `rm` of a watched FileView path, call `reload()` in the Process `onExited` — FileView caches content and a later `setText()` of unchanged content silently no-ops.
- hyprctl eval prints errors on stdout and exits non-zero on Lua errors; check both streams.
- The popup panel loads lazily (`Loader.active: false` until first open); keep it that way.
- CI (`.github/workflows/ci.yml`): `validate` runs Omarchy's own `omarchy-plugin-validate`, fetched fresh from `basecamp/omarchy` branch `quattro` (`bin/omarchy-plugin-validate`) — the moving pin is intentional, so Omarchy manifest-schema drift fails CI instead of silently accepting a manifest the shell would reject. It also runs `scripts/check-submission.sh` (marketplace SUBMISSION.md rules: README install+removal+deps, LICENSE, preview ≤50 MB/40 MP) and `scripts/check-hardening.sh` (line-based tripwires for the security-baseline classes that arrived as a marketplace comment on 2026-08-24 — paths into `sh -c` must go through `shellQuote()`, hyprctl in a Process argv must sit behind coreutils `timeout`, `curl` must carry `--max-time` — plus the 書面語 rule for shipped Chinese; AGENTS.md itself is not scanned because the rule text quotes the markers). Release (`.github/workflows/release.yml`, on tag `v*`): tag must equal `manifest.json` `version`, then packages the plugin payload zip + sha256 and publishes the GitHub Release.
- Preview assets: `preview.png` is the 73:35 (2190×1050) marketing cover rendered from `design/cover.html` (Swiss style, red accent; embeds `../panel.png` on the right). `panel.png` is the raw popup capture, produced by diffing a matched screenshot pair (panel closed/open) — a plain trim bbox on the diff fails (bar clock/cursor/wallpaper noise inflates it); use connected components, keep blobs with bbox ≥25% of the largest, mask the top 26 px bar rows, crop with a ~14 px margin starting below y=26. The full validated pipeline (commands included) lives in skill `oma-swiss-preview` (`~/.agents/skills/oma-swiss-preview/SKILL.md`); re-render the cover with headless Chromium from `design/cover.html` and sync both PNGs to the deployed copy (static assets — no shell restart).

## Verification

- `omarchy plugin validate <repo root>` must pass before deploying.
- Deploy loop: sync `BarWidget.qml`, `ToolPanel.qml`, `EvalQueue.qml`, `manifest.json`, `tabler-icons.ttf`, `preview.png`, `panel.png`, and docs to `~/.config/omarchy/plugins/glasschan.oma-swiss/`, ensure `~/.config/omarchy/shell.json` bar layout has `{"id": "glasschan.oma-swiss"}` (replacing `glasschan.super-alt-swap` if migrating), then `omarchy restart shell` (hot-reload can keep serving stale compiled QML), then E2E:
  - `omarchy-shell glasschan.oma-swiss toggle` — `hyprctl -j devices` shows `altwin:swap_lalt_lwin` added/removed on `at-translated-set-2-keyboard`; swap flag file appears/disappears
  - `omarchy-shell glasschan.oma-swiss aspect 16 10` — `hyprctl getoption layout:single_window_aspect_ratio` returns `[16, 10]`; flag file content has `{ 16, 10 }`
  - `omarchy-shell glasschan.oma-swiss aspectOff` — getoption back to `[0, 0]`; flag file absent
  - `omarchy-shell glasschan.oma-swiss status` reports all three states correctly
  - rapid consecutive CLI calls converge (single queued-eval slot, last absolute intent wins) and toggle spam leaves flag file and live state consistent (swap flag exists ⇔ devices shows the option)
  - pin: `omarchy-shell glasschan.oma-swiss pin` → pin file exists, `hyprctl binds` shows "Toggle single-window aspect (oma-swiss)" and the previous BACKSPACE bind is gone; `aspectToggle` cycles off ⇄ last ratio and panel ratio changes move the target; `pin` again → pin file absent and the previous binding is back
  - `omarchy-shell glasschan.oma-swiss look` — with looks on: `hyprctl getoption decoration:rounding` returns 6 and `general:border_size` returns 5, flag file exists; off: rounding 0 / border 2 (Omarchy defaults), flag file absent; `hyprctl configerrors` stays empty both ways
  - `omarchy-shell glasschan.oma-swiss lang` — `~/.local/state/glasschan.oma-swiss/lang` flips between `en`/`zh`, `status` reports `lang=` accordingly, and the panel re-renders in the new language
  - update click (badge E2E, guards issue #6): the badge fires `handleUpdateClick()`'s exact `sh -c`; a click is only meaningful when the deployed copy's `origin` differs from its HEAD — stand up a scratch bare clone of the fixed tree plus one "release" commit (manifest version bump), `git -C <deployed> remote set-url origin <scratch>`, run the exact click command, then verify the shell survives its own debounced reload (`Local plugin changed, reloading` in the shell log, no segfault, same quickshell PID) and `status` reports `update=none`; restore with `remote set-url origin` back to GitHub + `git reset --hard` to the pre-bump commit
  - quick actions: every action spawns detached — no capture-tool children remain under the quickshell process (`pgrep -af slurp` clean after the tool exits); record button start/stop via `pgrep -f '^gpu-screen-recorder'`; `omarchy-capture-screenshot region` etc. exist in PATH (`command -v`); interactive OCR/screenshot selection needs one manual click-through test (slurp overlay must appear and be draggable — the stdin-pipe regression this guards against)
  - external writer check: run the stock `omarchy-hyprland-window-single-square-aspect-toggle` once; `status` must report `aspect=1:1` (watcher picked it up), then restore
- End of test session: leave swap off; restore the user's aspect ratio (currently 4:3) unless asked otherwise; leave Opinionated Looks as the user's current visual state (on, via the flag file).

## Agent skills

### Issue tracker

Issues and specs for this repo live as GitHub issues in `glasschan/oma-swiss`, operated via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles use the default label strings (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.

## Child DOX Index

- No child AGENTS.md files are needed for the current repository structure.
