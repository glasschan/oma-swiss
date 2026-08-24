import QtQuick
import Quickshell.Io

// OmaSwiss eval queue: one slot, last absolute intent wins. Every hyprctl
// eval in the plugin rides this single queued Process, so rapid clicks queue
// instead of dropping and every action lands in order. A landed eval may
// carry a completion notification (glyph + message); on idle the queue
// signals broadcastRequested so every monitor's instance refreshes from the
// live state. The interface is one function — enqueue(expr, notify, glyph) —
// and all queue/chain state lives here, not scattered across the host widget.
Item {
  id: root

  // ---- queue state (private to this module) -------------------------------
  property string pendingExpr: ""
  property bool evalPending: false
  property string queuedNotify: ""
  property string queuedNotifyGlyph: ""
  property string evalNotify: ""
  property string evalNotifyGlyph: ""

  // Emitted when the slot goes idle with nothing queued: the host re-reads
  // live state so the optimistic UI is corrected by the truth.
  signal broadcastRequested()

  // Single entry point. notify/glyph fire only if the eval actually lands —
  // a rejected eval writes nothing and notifies nothing.
  function enqueue(expr, notify, glyph) {
    if (evalProc.running) {
      pendingExpr = expr
      evalPending = true
      queuedNotify = notify || ""
      queuedNotifyGlyph = glyph || ""
      return
    }
    evalPending = false
    evalNotify = notify || ""
    evalNotifyGlyph = glyph || ""
    evalProc.command = ["timeout", "10", "hyprctl", "eval", expr]
    evalProc.running = true
  }

  // Applies one queued eval. The exit handler chains any action queued while
  // busy (last absolute intent wins), fires the completion notification only
  // on success, and otherwise signals broadcastRequested.
  Process {
    id: evalProc
    stdout: StdioCollector {
      id: evalOut
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: evalErr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        // hyprctl prints errors on stdout, so both streams are shown.
        console.warn("oma-swiss: hyprctl eval failed (" + exitCode + "):",
          (evalOut.text.trim() || evalErr.text.trim()))
      } else if (root.evalNotify !== "") {
        notifyProc.command = ["timeout", "10", "omarchy-notification-send", "-g",
          root.evalNotifyGlyph, root.evalNotify]
        notifyProc.running = true
      }
      root.evalNotify = ""
      root.evalNotifyGlyph = ""
      if (root.evalPending) {
        var expr = root.pendingExpr
        root.evalPending = false
        root.pendingExpr = ""
        root.evalNotify = root.queuedNotify
        root.evalNotifyGlyph = root.queuedNotifyGlyph
        root.queuedNotify = ""
        root.queuedNotifyGlyph = ""
        evalProc.command = ["timeout", "10", "hyprctl", "eval", expr]
        evalProc.running = true
      } else {
        root.broadcastRequested()
      }
    }
  }

  // Fires the completion notification for an eval that landed.
  Process {
    id: notifyProc
  }
}
