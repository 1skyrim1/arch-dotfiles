pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  //-- Functions --

  function apply(path: string): void {
    const palette = paletteFor(path);
    if (palette !== null) {
      show(path, palette);
      return;
    }
    waitingToApply = path;
    queue = [path, ...queue.filter(queued => queued !== path)];
    calculateNext();
  }

  //-- Internals - switching --

  property string waitingToApply: ""

  function show(path: string, palette: var): void {
    // Wallpaper and colors in the same moment.
    Wallpaper.show(path);
    Colors.show(palette);

    const saved = JSON.stringify({ wallpaper: path, colors: palette }, null, 2);
    paletteFile.setText(saved);       // for the next start
    sharedPaletteFile.setText(saved); // for the login screen

    templates.exec(matugenCommand(path, false));
  }

  function matugenCommand(path: string, dryRun: bool): var {
    const command = ["matugen", "image", path, "-m", Config.wallpaperMode, "-t", Config.wallpaperScheme,
                     "--source-color-index", "0", "-j", "hex"];
    return dryRun ? [...command, "--dry-run"] : command;
  }

  Process {
    id: templates
  }

  function reportFailure(path: string, errors: string): void {
    const message = errors.replace(/\x1b\[[0-9;]*m/g, "")
      .split("\n")
      .map(line => line.trim())
      .find(line => line !== "" && line !== "Error:") ?? "matugen failed";
    Quickshell.execDetached(["notify-send", "-a", "Theme", `Couldn't use ${path.split("/").pop()}`, message]);
  }

  //-- Internals - palette cache --

  // Wallpapers whose palette still needs calculating, in order.
  property var queue: []

  // Returns the cached palette for "path"
  function paletteFor(path: string): var {
    const cached = cache.palettes[path];
    const wallpaper = Wallpaper.available.find(entry => entry.path === path);
    if (!cached || (wallpaper && wallpaper.modified !== cached.modified))
      return null;
    return cached.colors;
  }

  function syncWithFolder(): void {
    // not read wallpapers yet
    if (!Wallpaper.scanned)
      return;

    const present = new Set(Wallpaper.available.map(entry => entry.path));
    const kept = {};
    for (const path in cache.palettes) {
      if (present.has(path))
        kept[path] = cache.palettes[path];
    }
    if (Object.keys(kept).length !== Object.keys(cache.palettes).length)
      cache.palettes = kept;

    queue = Wallpaper.available
      .filter(entry => paletteFor(entry.path) === null)
      .map(entry => entry.path);
    calculateNext();
  }

  // Starts on the next queued wallpaper. One at a time, so a folder full
  // of new wallpapers doesn't start dozens of processes at once.
  function calculateNext(): void {
    if (calculator.running || queue.length === 0)
      return;
    const path = queue[0];
    calculator.path = path;
    calculator.modified = Wallpaper.available.find(entry => entry.path === path)?.modified ?? 0;
    calculator.exec(matugenCommand(path, true));
  }

  function parsePalette(output: string): var {
    const colors = JSON.parse(output).colors;
    const palette = {};
    for (const name in colors)
      palette[name] = colors[name].default.color;
    return palette;
  }

  Process {
    id: calculator

    property string path
    property real modified

    stdout: StdioCollector {
      id: calculatorOutput
    }
    stderr: StdioCollector {
      id: calculatorErrors
    }

    onExited: (exitCode, exitStatus) => {
      const path = calculator.path;
      root.queue = root.queue.filter(queued => queued !== path);

      if (exitStatus === 0 && exitCode === 0) {
        const entry = { modified: calculator.modified, colors: root.parsePalette(calculatorOutput.text) };
        cache.palettes = Object.assign({}, cache.palettes, { [path]: entry });
        if (root.waitingToApply === path) {
          root.waitingToApply = "";
          root.show(path, entry.colors);
        }
      } else if (root.waitingToApply === path) {
        root.waitingToApply = "";
        root.reportFailure(path, calculatorErrors.text);
      }

      root.calculateNext();
    }
  }

  FileView {
    path: Quickshell.cachePath("palettes.json")
    printErrors: false
    blockLoading: true
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: cache

      property var palettes: ({})
    }
  }

  FileView {
    id: paletteFile

    path: Colors.paletteFile
    printErrors: false
  }

  FileView {
    id: sharedPaletteFile

    path: `${Config.sharedDir}/palette.json`
    printErrors: false
  }

  Connections {
    target: Wallpaper

    function onAvailableChanged(): void {
      root.syncWithFolder();
    }
  }

  IpcHandler {
    target: "theme"

    function status(): string {
      if (!Wallpaper.scanned)
        return `Wallpaper folder not read yet (${Config.wallpaperDir})`;
      const total = Wallpaper.available.length;
      const ready = Wallpaper.available.filter(entry => root.paletteFor(entry.path) !== null).length;
      const waiting = total - ready;
      return waiting === 0 ? `All ${total} palettes ready`
                           : `${ready} of ${total} palettes ready, ${waiting} calculating`;
    }
  }

  Component.onCompleted: {
    syncWithFolder();
    if (!Colors.loaded && Wallpaper.current !== "")
      apply(Wallpaper.current);
  }
}
