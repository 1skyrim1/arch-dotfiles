pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  // Number of pending updates.
  property int count: 0

  function check(): void {
    checkProcess.running = true;
  }

  function update(): void {
    Quickshell.execDetached(Config.updateCommand);
  }

  Process {
    id: checkProcess

    command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]

    stdout: StdioCollector {
      onStreamFinished: root.count = parseInt(text) || 0
    }
  }

  Timer {
    interval: Config.updateCheckInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.check()
  }

  IpcHandler {
    target: "updates"

    function check(): void {
      root.check();
    }
  }
}
