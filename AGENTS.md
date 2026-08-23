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

- Source repo of the Omarchy shell plugin `glasschan.hypr-toolbox` (marketplace repo name: `omarchy-hypr-toolbox`). One bar icon, two Hyprland tools: laptop Super⇄Alt swap and single-window aspect ratio (presets + custom). Successor of `glasschan.super-alt-swap` (that repo is deprecated).
- Deployed copy lives in `~/.config/omarchy/plugins/glasschan.hypr-toolbox/`; after editing files there, sync changes back to this repo.

## Ownership

- Root-owned files: `README.md`, `LICENSE`, `manifest.json`, `BarWidget.qml`, `ToolPanel.qml`, `preview.png`, and root-level project documentation.

## Local Contracts

- Plugin id `glasschan.hypr-toolbox`, kind `bar-widget`, single entry point `BarWidget.qml`.
- `BarWidget.qml` owns all state and actions; `ToolPanel.qml` is a pure view injected with `hostWidget`. No state may live in the panel.
- Flag files are the source of truth and must stay byte-compatible:
  - Swap: `~/.local/state/omarchy/toggles/hypr/super-alt-swap.lua` (same path and Lua content as the retired super-alt-swap plugin).
  - Aspect: `~/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua` — written directly with the chosen ratio; never call `omarchy-hyprland-toggle` for it (its "on" copies stock 1:1).
- Custom-ratio memory: `~/.local/state/glasschan.hypr-toolbox/last-aspect`, plain `"w h"` text — the LAST ratio set (preset or custom); drives panel prefill and `aspectToggle`.
- Hotkey pin: `~/.local/state/omarchy/toggles/hypr/hypr-toolbox-hotkey.lua` — exists = pinned. Its static Lua does `hl.unbind("SUPER + CTRL + BACKSPACE")` + `o.bind(..., "omarchy-shell glasschan.hypr-toolbox aspectToggle")`; toggles load after user bindings, so the pinned bind wins while the file exists and removal restores whatever was bound before (stock or the user's own override). The write and the activating `hyprctl reload` MUST stay one shell command (FileView.setText is async — a separate reload Process would race).
- IPC surface (CLI = `omarchy-shell glasschan.hypr-toolbox <fn>`, exact function names, no hyphen mapping): `toggle` (swap), `aspect w h`, `aspectOff`, `aspectToggle`, `pin`, `panel`, `open`, `close`, `status`.
- Bar interactions: left-click opens the popup, right-click toggles the swap directly.

## Work Guidance

- Resource floor is a hard design rule: no timers (except the 100 ms configreload debounce), no polling, no background services. File watching via FileView `watchChanges` only; hyprctl work through the single queued-eval Process so rapid clicks land in order.
- After any `rm` of a watched FileView path, call `reload()` in the Process `onExited` — FileView caches content and a later `setText()` of unchanged content silently no-ops.
- hyprctl eval prints errors on stdout and exits non-zero on Lua errors; check both streams.
- The popup panel loads lazily (`Loader.active: false` until first open); keep it that way.

## Verification

- `omarchy plugin validate <repo root>` must pass before deploying.
- Deploy loop: sync `BarWidget.qml`, `ToolPanel.qml`, `manifest.json`, `preview.png`, and docs to `~/.config/omarchy/plugins/glasschan.hypr-toolbox/`, ensure `~/.config/omarchy/shell.json` bar layout has `{"id": "glasschan.hypr-toolbox"}` (replacing `glasschan.super-alt-swap` if migrating), then `omarchy restart shell` (hot-reload can keep serving stale compiled QML), then E2E:
  - `omarchy-shell glasschan.hypr-toolbox toggle` — `hyprctl -j devices` shows `altwin:swap_lalt_lwin` added/removed on `at-translated-set-2-keyboard`; swap flag file appears/disappears
  - `omarchy-shell glasschan.hypr-toolbox aspect 16 10` — `hyprctl getoption layout:single_window_aspect_ratio` returns `[16, 10]`; flag file content has `{ 16, 10 }`
  - `omarchy-shell glasschan.hypr-toolbox aspectOff` — getoption back to `[0, 0]`; flag file absent
  - `omarchy-shell glasschan.hypr-toolbox status` reports all three states correctly
  - rapid consecutive CLI calls land in order (queued eval)
  - pin: `omarchy-shell glasschan.hypr-toolbox pin` → pin file exists, `hyprctl binds` shows "Toggle single-window aspect (hypr-toolbox)" and the previous BACKSPACE bind is gone; `aspectToggle` cycles off ⇄ last ratio and panel ratio changes move the target; `pin` again → pin file absent and the previous binding is back
  - external writer check: run the stock `omarchy-hyprland-window-single-square-aspect-toggle` once; `status` must report `aspect=1:1` (watcher picked it up), then restore
- End of test session: leave swap off; restore the user's aspect ratio (currently 4:3) unless asked otherwise.

## Child DOX Index

- No child AGENTS.md files are needed for the current repository structure.
