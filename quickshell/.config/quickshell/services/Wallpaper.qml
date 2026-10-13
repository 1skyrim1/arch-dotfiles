pragma Singleton

// Which wallpaper is on screen, and which ones you can choose from.
//
// Changing it goes through Theme.apply(), which switches the wallpaper and
// the colors made from it together, by calling show() here.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  //-- Public state --

  readonly property string current: Config.greeterMode ? sharedCopy : state.path

  property var available: []

  property bool scanned: false

  // The wallpaper chosen in the switcher right now, or "". The
  // background loads it at full size ahead of time, so the sweep can
  // start the moment you press Enter.
  property string upcoming: ""

  readonly property string sharedCopy: `${Config.sharedDir}/wallpaper`

  //-- Functions --

  function show(path: string): void {
    if (path === state.path)
      return;
    state.path = path;
    Quickshell.execDetached(["cp", "--", path, sharedCopy]);
  }

  // Reads the wallpaper folder again. Runs at startup and each time the
  // switcher opens, so images you add or remove show up there. Takes a
  // few milliseconds.
  function rescan(): void {
    scanner.running = true;
  }

  //-- Internals --

  // Turns find's output (see below) into `available`.
  function updateAvailable(output: string): void {
    const wallpapers = output.split("\n")
      .filter(line => line !== "")
      .map(line => {
        const space = line.indexOf(" ");
        return {
          path: line.slice(space + 1),
          modified: Math.round(parseFloat(line.slice(0, space)) * 1000),
        };
      })
      .sort((a, b) => a.path.localeCompare(b.path));

    // `scanned` first: Theme reacts to the change of `available`, and
    // must already see the folder as read at that moment.
    scanned = true;
    // Only when something changed: a new list would make Theme and the
    // switcher check everything again for nothing.
    if (JSON.stringify(wallpapers) !== JSON.stringify(available))
      available = wallpapers;
  }

  Process {
    id: scanner

    running: true
    command: ["find", "-L", Config.wallpaperDir, "-maxdepth", "1", "-type", "f",
              "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
              "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")",
              "-printf", "%T@ %p\n"]

    stdout: StdioCollector {
      id: scanOutput
    }

    onExited: exitCode => {
      if (exitCode !== 0)
        console.warn(`Wallpaper: couldn't read ${Config.wallpaperDir}`);
      root.updateAvailable(scanOutput.text);
    }
  }

  // ~/.local/state/myshell/wallpaper.json: { "path": "/home/…/forest.jpg" }
  FileView {
    path: Quickshell.statePath("wallpaper.json")
    printErrors: false
    blockLoading: true
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: state

      property string path: ""
    }
  }

  // For scripts and keybinds:
  //   qs ipc call wallpaper toggle          open/close the switcher
  //   qs ipc call wallpaper set <file>      apply a wallpaper directly
  //   qs ipc call wallpaper get
  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      Overlays.toggle("wallpaper");
    }

    function set(path: string): void {
      Theme.apply(path);
    }

    function get(): string {
      return root.current;
    }
  }
}
