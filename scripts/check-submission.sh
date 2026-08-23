#!/bin/bash
# Pre-flight checks for publishing to omarchyplugins.com
# (HANCORE-linux/omarchy-plugin-marketplace SUBMISSION.md rules). Kept in the
# repo so the same gate runs locally and in CI:
#   - README must document install and removal
#   - README must document dependencies
#   - LICENSE must exist
#   - plugin id must be a valid non-reserved namespaced id
#   - preview image, if present, within marketplace limits (50 MB / 40 MP)

set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "check-submission: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

[[ -f manifest.json ]] || fail "missing manifest.json"
[[ -f LICENSE ]] || fail "missing LICENSE"
[[ -f README.md ]] || fail "missing README.md"

ID=$(jq -r '.id // ""' manifest.json)
[[ -n "$ID" ]] || fail "manifest 'id' is empty"
[[ "$ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || fail "invalid plugin id '$ID'"
[[ "$ID" != *".."* ]] || fail "invalid plugin id '$ID'"
[[ "$ID" != omarchy.* ]] || fail "plugin id '$ID' uses the reserved omarchy.* namespace"

grep -q 'omarchy plugin add' README.md || fail "README lacks install instructions"
grep -q 'omarchy plugin remove' README.md || fail "README lacks removal instructions"
grep -qi 'dependencies' README.md || fail "README lacks a dependencies section"

pixels() {
  python3 - "$1" <<'PY'
import struct, sys
with open(sys.argv[1], "rb") as f:
    head = f.read(33)
if head[:8] == b"\x89PNG\r\n\x1a\n" and head[12:16] == b"IHDR":
    w, h = struct.unpack(">II", head[16:24])
    print(w * h)
elif head[:3] == b"\xff\xd8\xff":
    print(-2)  # jpeg: dimension parsing not implemented, skip MP check
else:
    print(-2)
PY
}

for img in preview.png preview.jpg preview.jpeg preview.webp preview.avif; do
  [[ -f "$img" ]] || continue
  size=$(stat -c%s "$img")
  if (( size > 50 * 1024 * 1024 )); then
    fail "$img is $size bytes, over the 50 MB marketplace limit"
  fi
  mp=$(pixels "$img")
  if (( mp >= 0 )) && (( mp > 40 * 1000 * 1000 )); then
    fail "$img is $mp pixels, over the 40 megapixel marketplace limit"
  fi
done

echo "check-submission: OK (id=$ID)"
