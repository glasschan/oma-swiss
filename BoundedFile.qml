import QtQuick
import Quickshell.Io

// OmaSwiss bounded state-file reader. FileView's own load has no byte or
// file-type bound, so a FIFO planted at a predictable state path could block
// the shell and an oversized file could be buffered whole (marketplace
// security finding, 2026-08-27). FileViews therefore stay as pure change
// triggers (preload: false) and every content read rides this slot, capped
// three ways:
//   - the [ -f ] gate lets only regular files through — FIFOs and specials
//     are reported missing without ever being opened
//   - dd opens nonblocking (iflag=nonblock) and copies at most bs bytes
//   - timeout 5 is the hard deadline, same rule as every other subprocess
// The interface is one function, fire(), and one signal, read(content,
// exists). fire() while a read is in flight re-queues it (quickshell
// swallows running = true on a busy Process), so consumers always see the
// last state.
Process {
  id: root

  required property string path
  signal read(string content, bool exists)

  // Set when fire() lands during an in-flight read; onExited drains it.
  property bool redirty: false

  command: ["timeout", "5", "sh", "-c", '[ -f "$1" ] || exit 3; exec dd if="$1" iflag=nonblock bs=4096 count=1 status=none', "sh", path]

  stdout: StdioCollector {
    id: readOut
    waitForEnd: true
  }

  function fire() {
    if (running) {
      redirty = true
      return
    }
    running = true
  }

  onExited: function(exitCode) {
    read(readOut.text, exitCode === 0)
    if (redirty) {
      redirty = false
      running = true
    }
  }
}
