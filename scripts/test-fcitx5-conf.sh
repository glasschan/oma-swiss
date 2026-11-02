#!/bin/sh
# Regression test for the classicui.conf merge contract (issue #14,
# 2026-09-20): the fcitx5 toggle themes the candidate window and leaves the
# user's own settings alone — above all the IME font.
#
# Runs fcitx5-theme.sh against throwaway HOMEs with hyprctl / systemctl /
# omarchy-theme-color stubbed out: no root, no compositor, no fcitx5 install,
# so it runs unchanged in CI. Only classicui.conf is asserted; the generated
# theme itself still needs the E2E in AGENTS.md.
#
# Usage: scripts/test-fcitx5-conf.sh   (exit 0 = pass)
set -u

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo/fcitx5-theme.sh"
sandboxes=""
fail=0

cleanup() {
  for dir in $sandboxes; do rm -rf -- "$dir"; done
}
trap cleanup EXIT INT TERM

# A throwaway HOME with the three external commands fcitx5-theme.sh calls.
new_home() {
  home=$(mktemp -d "${TMPDIR:-/tmp}/oma-swiss-fcitx5.XXXXXX") || exit 1
  sandboxes="$sandboxes $home"
  mkdir -p "$home/bin" "$home/.config/fcitx5/conf" "$home/.config/hypr"
  printf '#!/bin/sh\nexit 0\n' >"$home/bin/hyprctl"
  printf '#!/bin/sh\nexit 0\n' >"$home/bin/systemctl"
  # KEY FALLBACK -> echo the fallback, so generate() has a palette.
  printf '#!/bin/sh\nprintf "%%s\\n" "$2"\n' >"$home/bin/omarchy-theme-color"
  chmod +x "$home/bin/hyprctl" "$home/bin/systemctl" "$home/bin/omarchy-theme-color"
  conf="$home/.config/fcitx5/conf/classicui.conf"
  backup="$conf.pre-oma-swiss"
}

run() {
  HOME="$home" PATH="$home/bin:$PATH" timeout 120 sh "$script" "$@" >/dev/null 2>&1
}

write_conf() {
  printf '%s\n' "$1" >"$conf"
}

expect_line() { # TEXT CASE
  grep -qxF -- "$1" "$conf" || { echo "FAIL [$2]: missing line: $1"; fail=1; }
}
expect_no_line() { # PATTERN CASE
  grep -q -- "$1" "$conf" && { echo "FAIL [$2]: unexpected match: $1"; fail=1; }
}
begin() { case_start=$fail; case_name=$1; }
end() {
  if [ "$fail" -eq "$case_start" ]; then
    echo "ok - $case_name"
  else
    echo "FAILED - $case_name"
  fi
}

# --- A: merging into the user's own file keeps every key, and the backup
#        restores the file byte-for-byte on the way back out. ---------------
begin "apply merges into a user file; unapply restores it exactly"
new_home
write_conf '# my fcitx5 look
Theme=default
DarkTheme=default-dark
Font="Sarasa Term TC 12"
MenuFont="Sarasa Term TC 11"
TrayFont="Sarasa Term TC 10"
VerticalCandidateList=True'
cp "$conf" "$home/pre-toggle.conf"
if run apply; then
  expect_line 'Font="Sarasa Term TC 12"' A
  expect_line 'MenuFont="Sarasa Term TC 11"' A
  expect_line 'TrayFont="Sarasa Term TC 10"' A
  expect_line 'VerticalCandidateList=True' A
  expect_line '# my fcitx5 look' A
  expect_line 'Theme=omarchy' A
  expect_line 'DarkTheme=omarchy' A
  expect_line 'UseDarkTheme=False' A
  expect_line 'PerScreenDPI=True' A
  [ -f "$backup" ] || { echo "FAIL [A]: no backup written"; fail=1; }
  # Second apply: still no duplicated owned keys, font untouched.
  run apply || { echo "FAIL [A]: second apply failed"; fail=1; }
  [ "$(grep -c '^Theme=' "$conf")" = 1 ] ||
    { echo "FAIL [A]: apply duplicated an owned key"; fail=1; }
  run unapply || { echo "FAIL [A]: unapply failed"; fail=1; }
  cmp -s "$home/pre-toggle.conf" "$conf" ||
    { echo "FAIL [A]: unapply did not restore the pre-toggle file"; fail=1; }
  [ -f "$backup" ] && { echo "FAIL [A]: backup left behind"; fail=1; }
else
  echo "FAIL [A]: apply failed"; fail=1
fi
end

# --- B: a fresh install gets the shipped default (font included) and
#        unapply removes the file it created. ------------------------------
begin "fresh install writes the defaults; unapply removes the file"
new_home
if run apply; then
  expect_line 'Theme=omarchy' B
  expect_line 'Font="OPPO Sans 4.0 11"' B
  [ -f "$backup" ] && { echo "FAIL [B]: backup made on a fresh install"; fail=1; }
  run unapply || { echo "FAIL [B]: unapply failed"; fail=1; }
  [ -e "$conf" ] && { echo "FAIL [B]: file we created was not removed"; fail=1; }
else
  echo "FAIL [B]: apply failed"; fail=1
fi
end

# --- C: our own leftover artifact (no backup) disappears on unapply. ------
begin "unapply removes an all-ours file left without a backup"
new_home
write_conf 'Theme=omarchy
DarkTheme=omarchy
UseDarkTheme=False
PerScreenDPI=True
Font="OPPO Sans 4.0 11"'
run unapply || { echo "FAIL [C]: unapply failed"; fail=1; }
[ -e "$conf" ] && { echo "FAIL [C]: all-ours file not removed"; fail=1; }
end

# --- D: ours plus user keys and no backup: strip only what we own. ---------
begin "unapply without a backup keeps the user's font and other keys"
new_home
write_conf 'Theme=omarchy
DarkTheme=omarchy
Font="Noto Sans Mono 13"
VerticalCandidateList=True'
run unapply || { echo "FAIL [D]: unapply failed"; fail=1; }
expect_line 'Font="Noto Sans Mono 13"' D
expect_line 'VerticalCandidateList=True' D
expect_no_line '^Theme=' D
end

# --- E: a file we do not own is never touched. -----------------------------
begin "unapply leaves a foreign file untouched"
new_home
write_conf 'Font="Source Han Sans 12"'
cp "$conf" "$home/foreign.conf"
run unapply || { echo "FAIL [E]: unapply failed"; fail=1; }
cmp -s "$home/foreign.conf" "$conf" ||
  { echo "FAIL [E]: foreign file was modified"; fail=1; }
end

if [ "$fail" -ne 0 ]; then
  echo "test-fcitx5-conf: FAILED" >&2
  exit 1
fi
echo "test-fcitx5-conf: OK"