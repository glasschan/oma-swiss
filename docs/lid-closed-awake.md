# Lid-closed awake

The laptop-only toggle that keeps the machine running while the lid is shut, so
the lid can be closed *before* the displays are plugged in.

## The problem it solves

Omarchy leaves lid handling to `systemd-logind`. Its shipped defaults are:

| Setting | Default | Effect |
| --- | --- | --- |
| `HandleLidSwitch` | `suspend` | Closing the lid suspends unless something exempts it |
| `HandleLidSwitchDocked` | `ignore` | Closing the lid while "docked" does nothing |

logind counts *attached external displays* as docked. That is why the
conventional workflow works: plug the displays first, then close the lid — at
lid-close time logind sees external outputs and does nothing.

It is also why the workflow is backwards for a laptop that lives on a stand. If
the lid closes first, nothing is attached yet, so the default `suspend` applies
and the machine is asleep before the cable goes in.

## What the toggle does

While it is on, the plugin holds a user-space inhibitor:

```text
systemd-inhibit --what=handle-lid-switch --mode=block \
                --who=OmaSwiss --why=oma-swiss-lid-awake sleep infinity
```

A `handle-lid-switch` block tells logind to perform **no** lid action at all —
neither suspend nor lock — whether or not a display is attached. No root, no
sudo, no `logind.conf` drop-in. Turning the toggle off stops the process, which
drops the lock.

The lock is therefore only as long-lived as the process holding it. That shapes
the rest of the design:

- **The state file is the only intent.** `setLid` writes
  `~/.local/state/glasschan.oma-swiss/lid-awake` atomically and returns; a file
  watch reconciles the system towards it. A burst of clicks converges on the
  last one, and a manual `touch` or `rm` behaves exactly like a panel click.
- **A load-time sweep removes leftovers.** A shell killed with `SIGKILL` leaves
  its inhibitor child alive, which would keep lid handling disabled forever with
  nothing visible in the UI. Each load reads logind's own JSON inhibitor list,
  keeps the entries whose `--why` carries the marker `oma-swiss-lid-awake`, and
  kills exactly those before arming its own lock.
- **A refused lock falls back to off.** If the inhibitor exits while the intent
  is still on, the state file is removed (so the switch flips back) and one
  notification is sent. The panel never claims a state the system refused.

## What it deliberately does not do

- **No lid detection.** The plugin never reads the lid switch. Reading it costs
  either a 1-second poll or an `evdev` reader (which needs the `input` group),
  and both violate the repository's resource floor.
- **No panel or monitor handling.** Turning the built-in panel off is already
  done by Omarchy's clamshell handling (`omarchy-hyprland-monitor-clamshell`
  with `internal-monitor-clamshell.lua`) and, when installed, by `hyprmoncfg`,
  which polls lid state and applies a profile. Both act once an external display
  is attached. A second implementation here would fight them for the same
  output.
- **No idle-lock inhibition.** The shell's own idle lock still fires. A closed
  laptop left alone still locks.
- **No AC gate, no timeout.** The toggle stays on until it is turned off. It is
  a deliberate manual control, not a heuristic, so it also works on battery and
  with a Type-C cable that carries video but no power.

## Known limits

- **Booting or logging in with the lid already closed still suspends.** The
  inhibitor exists only once the shell has loaded, and logind acts on the lid
  before that. Open the lid for the boot, or stay plugged into a display until
  the session is up. Making the exemption survive boot would require a
  root-owned `logind.conf` drop-in, which this plugin deliberately does not
  install.
- **The locking is not persistent across a shell that never restarts.** If the
  shell dies, the toggle is re-armed when the shell comes back — not while it is
  down.
- **Removing the plugin is safe.** The lock lives in a process started by the
  shell, so it dies with it; the only leftover is the state file under
  `~/.local/state/glasschan.oma-swiss/`, which can be deleted by hand.

## Verification

`scripts/e2e-lid-awake.sh` covers the automatable half against a live session:

```bash
scripts/e2e-lid-awake.sh                # on/off, external writer, no orphans
scripts/e2e-lid-awake.sh --destructive  # also restart and SIGKILL the shell
```

The physical half needs hands:

1. Toggle **Awake with lid closed** on, with no external display attached.
2. Close the lid. The machine must stay awake and unlocked — no suspend.
3. Plug in HDMI, DP or Type-C. The external display must come up, and the
   built-in panel must go dark (that part is Omarchy's clamshell handling, so
   `hyprctl monitors` showing the built-in output disabled is the check).
4. Open the lid. The built-in panel must return.
5. Leave the closed machine idle past the lock timeout. It must lock.
6. Turn the toggle off and close the lid. The machine must suspend again.