pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  //-- Public state --

  property bool selecting: false
  property bool capturing: false
  property ShellScreen screen: null
  readonly property string frozenPath: Quickshell.cachePath("screenshot.frozen.png")

  //-- Functions --

  // Print: freeze the screen and let youuser select a region.
  function region(): void {
    if (busy || !Hypr.focusedScreen)
      return;
    screen = Hypr.focusedScreen;
    freezer.exec(["grim", "-o", screen.name, frozenPath]);
  }

  function wholeScreen(): void {
    if (busy || !Hypr.focusedScreen)
      return;
    screen = Hypr.focusedScreen;
    save(["-o", screen.name]);
  }

  // Called by the selector when you let go. `area` is in the selctor's
  // own coordinates (logical pixels, 0,0 = the screen's top-left).
  function captureArea(area: rect): void {
    const x = Math.round(screen.x + area.x);
    const y = Math.round(screen.y + area.y);
    const geometry = `${x},${y} ${Math.round(area.width)}x${Math.round(area.height)}`;
    capturing = true;
    pendingGeometry = geometry;
    // Wait until the selector has actually drawn itself withouts its
    // marks; 100 ms is several frames, even at 60 Hz;
    captureDelay.restart();
  }

  function cancel(): void {
    selecting = false;
    capturing = false;
  }

  //-- Internals --

  readonly property bool busy: selecting || freezer.running || saver.running

  property string pendingGeometry: ""

  property string savedPath: ""

  function newPath(): string {
    const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    return `${Config.screenshotDir}/Screenshot_${stamp}.png`;
  }

  function save(grimArguments: var): void {
    savedPath = newPath();
    // A small shell script, because three programs run in a row. The
    // file name and grim's arguments are passed as "$1", "$2", "$3",
    // never pasted into the script text: a file name with spaces or quotes can't break it.
    //  wl-copy: the clipboard;
    saver.exec(["sh", "-c",
                'mkdir -p "$(dirname "$1")" && grim "$2" "$3" "$1" && wl-copy --type image/png < "$1"',
                "sh", savedPath, ...grimArguments]);
  }

  function announce(path: string): void {
    const fileName = path.split("/").pop();
    Quickshell.execDetached(["sh", "-c",
      'action=$(notify-send --app-name=Screenshot --hint="string:image-path:file://$1" '
      + '--action=default=Open "Screenshot saved" "$2 · copied to the clipboard"); '
      + '[ "$action" = default ] && xdg-open "$1"',
      "sh", path, fileName]);
  }

  function reportFailure(what: string): void {
    Quickshell.execDetached(["notify-send", "--app-name=Screenshot", "--urgency=critical",
      "Screenshot failed", what]);
  }

  Process {
    id: freezer

    onExited: exitCode => {
      if (exitCode === 0)
        root.selecting = true;
      else
        root.reportFailure("grim couldn't capture the screen.");
    }
  }

  Timer {
    id: captureDelay

    interval: 100
    onTriggered: root.save(["-g", root.pendingGeometry])
  }

  Process {
    id: saver

    onExited: exitCode => {
      root.cancel();
      if (exitCode === 0)
        root.announce(root.savedPath);
      else
        root.reportFailure(`Couldn't save to ${Config.screenshotDir}.`);
    }
  }

  IpcHandler {
    target: "screenshot"

    function region(): void {
      root.region();
    }

    function screen(): void {
      root.wholeScreen();
    }
  }
}
