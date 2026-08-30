#!/bin/bash
# Regression tripwires for the issue classes that reached this repo as
# marketplace security-baseline comments (2026-08-24 and 2026-08-27), plus
# the repo's own copy rules. Line-based heuristics, deliberately tight to
# avoid false positives — the real contract lives in AGENTS.md Work
# Guidance:
#   1. QML-derived paths may reach sh -c only through shellQuote()
#   2. Every compositor/dbus subprocess needs a deadline: hyprctl in a
#      Process argv ("timeout", N, "hyprctl", ...) AND hyprctl inside an
#      sh -c string (quickshell ignores running=true on a busy Process, so
#      an unbounded one silently swallows later toggles), and the same for
#      omarchy-notification-send. Comment lines are skipped.
#   3. curl must carry --max-time (deadline) and --max-filesize (size bound)
#   4. shipped Chinese must be 書面語 — no Cantonese markers. AGENTS.md is
#      not scanned because the rule itself quotes the markers.
# Round 2 (maintainer review of 331a883, 2026-08-27), write-side classes:
#   5. no `cat >` redirection writes — flag writes are mktemp + atomic mv
#      in the target directory (a symlink cannot redirect the write)
#   6. Lua io.open flag writes must land via os.rename (symlink-safe;
#      io.open "wx" does not exist in hyprctl's Lua)
#   7. dd reads must be bounded: timeout deadline + iflag=nonblock + bs=
#      and count= byte caps on the same line
# Follow-up finding (review of 209f221, 2026-08-27):
#   8. no `exec N>` fd-redirection opens on predictable paths — the open
#      truncates through a planted symlink; mutual-exclusion locks ride a
#      read-only fd on the state directory's own inode
# FileView content reads are an accepted-risk policy documented in
# AGENTS.md Work Guidance and intentionally not scanned here.
# Usage: scripts/check-hardening.sh [repo-dir]

set -euo pipefail

python3 - "${1:-$(dirname "$0")/..}" <<'PY'
import glob, os, re, sys

os.chdir(sys.argv[1])
files = sorted(glob.glob("*.qml")) + sorted(glob.glob("README*.md"))
if not any(f.endswith(".qml") for f in files):
    sys.exit("check-hardening: no QML files found")

fails = []

for path in files:
    lines = open(path, encoding="utf-8").read().splitlines()
    for n, line in enumerate(lines, 1):
        where = f"{path}:{n}"
        if path.endswith(".qml") and not line.lstrip().startswith("//"):
            if "'\" + root." in line or re.search(r"\+ root\.\w*Path \+ \"'", line):
                fails.append(f"{where}: quote-wrapped path concatenation — use shellQuote()")
            if re.search(r"\+\s*root\.[A-Za-z]+Path", line) and "shellQuote" not in line:
                fails.append(f"{where}: path concatenation outside shellQuote()")
            if '"hyprctl"' in line and '"timeout"' not in line:
                fails.append(f"{where}: hyprctl argv without deadline (\"timeout\", N, …)")
            if "hyprctl reload" in line and "timeout" not in line and "console." not in line:
                fails.append(f"{where}: hyprctl reload inside sh -c without deadline")
            if "omarchy-notification-send" in line and "timeout" not in line:
                fails.append(f"{where}: notification send without deadline")
            if "curl " in line and ("max-time" not in line or "max-filesize" not in line):
                fails.append(f"{where}: curl without --max-time/--max-filesize (deadline + size bound)")
            if re.search(r"\bcat\s*>", line):
                fails.append(f"{where}: cat redirection write — use mktemp + atomic mv (symlink-safe)")
            if re.search(r"exec\s+\d+>", line):
                fails.append(f"{where}: fd redirection open (exec N>) — truncates through a planted symlink; lock the state-dir fd instead")
            if "dd if=" in line and not all(m in line for m in ("timeout", "iflag=nonblock", "bs=", "count=")):
                fails.append(f"{where}: dd read must be bounded (timeout + iflag=nonblock + bs/count caps)")
            if "io.open(" in line and not any("os.rename" in lines[k] for k in range(n - 1, min(n + 1, len(lines)))):
                fails.append(f"{where}: Lua io.open write without os.rename on this or the next line — flag writes must be symlink-safe")
            if path == "ToolPanel.qml" and re.search(r"\broot\.(toggleSwap|setAspect|clearAspect|aspectToggle|setPin|setLook|toggleLang|setLang|runQuickAction|handleUpdateClick)\(", line):
                fails.append(f"{where}: host function called on the panel's root — the panel is a pure view, host calls go through root.tool (TypeError regression of v0.3.2)")
        if re.search("[嘅揀]|唔係|成個|闊", line):
            fails.append(f"{where}: Cantonese marker in shipped Chinese (must be 書面語)")

if fails:
    sys.exit("check-hardening:\n  " + "\n  ".join(fails))

print("check-hardening: OK")
PY
