#!/bin/bash
# End-to-end check for the lid-awake toggle (issue #18 / #20).
#
# Drives ONLY the plugin's public surface — the IPC command, the `status`
# string, the state file and systemd's own inhibitor listing — so a regression
# anywhere inside the QML shows up here. It needs a live graphical session with
# the plugin loaded, so CI never runs it.
#
# Every phase restores the pre-run state, including on failure. The
# `--destructive` phases restart the shell and SIGKILL it; both refuse to run
# into a locked session.
#
# Usage: scripts/e2e-lid-awake.sh [--destructive]
#
# Exit codes: 0 all assertions passed (or skipped), 1 assertion failed,
#             2 environment problem (no shell / no lid / locked session).

set -uo pipefail

MARKER="oma-swiss-lid-awake"
PLUGIN="glasschan.oma-swiss"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/glasschan.oma-swiss/lid-awake"
DESTRUCTIVE=0
[[ ${1:-} == "--destructive" ]] && DESTRUCTIVE=1

PASS=0
BASELINE=""
SHELL_KILLED=0

say() { printf '%s\n' "$*"; }
pass() { PASS=$((PASS + 1)); say "ok   - $*"; }
fail() { say "FAIL - $1"; exit 1; }

ipc() { timeout 20 omarchy-shell "$PLUGIN" "$@" 2>&1; }

lid_state() {
  ipc status | tr ' ' '\n' | sed -n 's/^lid=//p' | head -1
}

inhibitor_pids() {
  # pgrep's own command line carries the pattern; pgrep skips itself, and this
  # script's own argv does not contain the marker, so nothing else matches.
  pgrep -f -- "--why=$MARKER" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'
}

wait_for() {
  local want="$1"
  for _ in $(seq 1 100); do
    [[ "$(lid_state)" == "$want" ]] && return 0
    sleep 0.1
  done
  return 1
}

# Invoked indirectly by the EXIT trap below.
# shellcheck disable=SC2329
restore() {
  if [[ -n $BASELINE ]]; then
    if [[ $BASELINE == on ]]; then
      [[ "$(lid_state)" == on ]] || ipc lid >/dev/null
    else
      [[ "$(lid_state)" == off ]] || ipc lid >/dev/null
    fi
  fi
  if (( SHELL_KILLED )); then
    timeout 60 omarchy restart shell >/dev/null 2>&1
  fi
}
trap restore EXIT

# ---- environment --------------------------------------------------------------

command -v omarchy-shell >/dev/null 2>&1 || { say "no omarchy-shell"; exit 2; }
compgen -G "/proc/acpi/button/lid/*/state" >/dev/null || { say "skip - no ACPI lid on this machine"; exit 0; }

if ! ipc status | grep -q "lid="; then
  say "skip - deployed plugin does not report lid= (older build?)"
  exit 2
fi
BASELINE=$(lid_state)
say "baseline lid=$BASELINE"

# The toggle must have nothing to arm when it is off, whatever the baseline.
if [[ $BASELINE == on ]]; then ipc lid >/dev/null; wait_for off || fail "could not reach off from baseline"; fi

# ---- on: one inhibitor, reported on ------------------------------------------

ipc lid >/dev/null
wait_for on || fail "status did not report lid=on after toggling on"
pids=$(inhibitor_pids)
[[ -n $pids ]] || fail "no inhibitor carrying the marker while on"
# One bar instance exists per monitor, and each holds its own identical lock, so
# the count is per-instance (1 on a single-bar setup, N on N bars).
pass "on holds the lid switch (pids: $pids)"

systemd-inhibit --list | grep -F "$MARKER" | grep -q handle-lid-switch \
  || fail "the held inhibitor is not a handle-lid-switch block"
pass "the inhibitor blocks the lid switch"

# ---- off: lock released, no orphan -------------------------------------------

ipc lid >/dev/null
wait_for off || fail "status did not report lid=off after toggling off"
sleep 0.5
[[ -z $(inhibitor_pids) ]] || fail "inhibitor survived the off toggle: $(inhibitor_pids)"
[[ -e $STATE ]] && fail "state file survived the off toggle"
pass "off releases the lock and removes the state file"

# ---- external writer: the file is the truth ----------------------------------

printf 'on\n' >"$STATE"
wait_for on || fail "an externally written state file was not followed"
sleep 0.5
[[ -n $(inhibitor_pids) ]] || fail "external write reported on but no inhibitor was armed"
pass "external write arms the lock without a reload"

rm -f "$STATE"
wait_for off || fail "an externally removed state file was not followed"
sleep 0.5
[[ -z $(inhibitor_pids) ]] || fail "external removal reported off but the lock survived"
pass "external removal releases the lock without a reload"

# ---- destructive phases: restart and SIGKILL ---------------------------------

if (( DESTRUCTIVE )); then
  if [[ $(timeout 10 omarchy-shell lock isLocked 2>/dev/null) == true ]]; then
    say "skip - destructive phases need an unlocked session"
  else
    ipc lid >/dev/null
    wait_for on || fail "could not reach on before the restart phase"
    timeout 60 omarchy restart shell >/dev/null 2>&1 || fail "omarchy restart shell failed"
    for _ in $(seq 1 100); do
      ipc status >/dev/null 2>&1 && break
      sleep 0.2
    done
    wait_for on || fail "the toggle did not survive a shell restart"
    sleep 0.5
    [[ -n $(inhibitor_pids) ]] || fail "the lock was not re-armed after a shell restart"
    pass "a shell restart re-arms the lock from the stored state"

    stale_before=$(inhibitor_pids)
    [[ -n $stale_before ]] || fail "no inhibitor to leave behind before the SIGKILL phase"
    pkill -9 -f '^quickshell ' || fail "could not SIGKILL the shell"
    SHELL_KILLED=1
    timeout 90 omarchy restart shell >/dev/null 2>&1 || fail "shell did not restart after SIGKILL"
    for _ in $(seq 1 150); do
      ipc status >/dev/null 2>&1 && break
      sleep 0.2
    done
    SHELL_KILLED=0
    sleep 1
    [[ "$(lid_state)" == on ]] || fail "the toggle lost its state across the SIGKILL restart"
    pids_after=$(inhibitor_pids)
    [[ -n $pids_after ]] || fail "the lock was not re-armed after the SIGKILL restart"
    [[ $pids_after != "$stale_before" ]] || fail "the leftover inhibitor ($stale_before) was not swept"
    pass "a killed shell's leftover inhibitor is swept and exactly one is re-armed"
  fi
fi

say "PASS - $PASS assertions"
exit 0