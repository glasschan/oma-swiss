#!/bin/bash
# Regression tripwires for the issue classes that reached this repo as a
# marketplace security-baseline comment (2026-08-24), plus the repo's own
# copy rules. Line-based heuristics, deliberately tight to avoid false
# positives — the real contract lives in AGENTS.md Work Guidance:
#   1. QML-derived paths may reach sh -c only through shellQuote()
#   2. hyprctl in a Process argv must be deadline-bounded by coreutils
#      timeout ("timeout", N, "hyprctl", ...). hyprctl inside an sh -c
#      string is exempt: those are one-shot writers whose exit nothing
#      chains on — the baseline class was buffered readers (StdioCollector).
#   3. curl must carry --max-time
#   4. shipped Chinese must be 書面語 — no Cantonese markers. AGENTS.md is
#      not scanned because the rule itself quotes the markers.
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
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        where = f"{path}:{n}"
        if path.endswith(".qml"):
            if "'\" + root." in line or re.search(r"\+ root\.\w*Path \+ \"'", line):
                fails.append(f"{where}: quote-wrapped path concatenation — use shellQuote()")
            if re.search(r"\+\s*root\.[A-Za-z]+Path", line) and "shellQuote" not in line:
                fails.append(f"{where}: path concatenation outside shellQuote()")
            if '"hyprctl"' in line and '"timeout"' not in line:
                fails.append(f"{where}: hyprctl argv without deadline (\"timeout\", N, …)")
            if "curl " in line and "max-time" not in line:
                fails.append(f"{where}: curl without --max-time")
        if re.search("[嘅揀]|唔係|成個|闊", line):
            fails.append(f"{where}: Cantonese marker in shipped Chinese (must be 書面語)")

if fails:
    sys.exit("check-hardening:\n  " + "\n  ".join(fails))

print("check-hardening: OK")
PY
