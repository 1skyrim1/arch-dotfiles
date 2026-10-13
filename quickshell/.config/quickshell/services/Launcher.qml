pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  //-- Public state --

  readonly property string overlayName: "launcher"

  readonly property bool open: Overlays.current === overlayName

  property string query: ""

  readonly property string mode: query.startsWith("=") ? "calculator"
                               : query.startsWith(":") ? "emoji"
                               : "apps"

  readonly property string searchText: (mode === "apps" ? query : query.slice(1)).trim()

  readonly property var results: {
    switch (mode) {
    case "calculator":
      return calculatorResults();
    case "emoji":
      return Emojis.search(searchText).slice(0, maxResults);
    default:
      return searchApps(searchText).slice(0, maxResults);
    }
  }
  readonly property int maxResults: 100

  readonly property string emptyText: {
    switch (mode) {
    case "calculator":
      return searchText === "" ? "Type a calculation, e.g. =2*21 or =5 ft to cm"
                               : "Calculating...";
    case "emoji":
      return "No matching emoji";
    default:
      return "No matching apps";
    }
  }
  readonly property string emptyIcon: mode === "calculator" ? Icons.calculator
                                    : mode === "emoji" ? Icons.emoji
                                    : Icons.search

  //-- Functions --

  function toggle(): void {
    Overlays.toggle(overlayName);
  }

  function close(): void {
    if (open)
      Overlays.close();
  }

  function activate(result: var): void {
    if (result.kind === "app")
      launch(result.app);
    else
      copy(result.text);
    close();
  }

  //-- Apps --

  readonly property var appResults: Array.from(DesktopEntries.applications.values)
      .filter(app => !app.noDisplay)
      .sort((a, b) => a.name.localeCompare(b.name))
      .map(app => ({
        kind: "app",
        title: app.name,
        subtitle: app.genericName || app.comment,
        icon: app.icon,
        glyph: "",
        app: app,
      }))

  function searchApps(text: string): var {
    if (text === "") {
      return Array.from(appResults).sort((a, b) => launchCount(b.app) - launchCount(a.app)
        || a.title.localeCompare(b.title));
    }

    return appResults
      .map(result => ({ result: result, score: appScore(result.app, text) }))
      .filter(scored => scored.score > 0)
      .sort((a, b) => b.score - a.score || a.result.title.localeCompare(b.result.title))
      .map(scored => scored.result);
  }

  function appScore(app: DesktopEntry, text: string): int {
    const extras = [app.genericName, app.id, ...Array.from(app.keywords)];
    const score = TextSearch.score(text, app.name, extras);
    return score === 0 ? 0 : score + Math.min(launchCount(app), 19);
  }

  function launch(app: DesktopEntry): void {
    if (app.runInTerminal) {
      Quickshell.execDetached({
        command: Config.inTerminal(Array.from(app.command)),
        workingDirectory: app.workingDirectory,
      });
    } else {
      app.execute();
    }
    countLaunch(app);
  }

  // usage count
  function launchCount(app: DesktopEntry): int {
    return usage.counts[app.id] ?? 0;
  }

  function countLaunch(app: DesktopEntry): void {
    const counts = Object.assign({}, usage.counts);
    counts[app.id] = launchCount(app) + 1
    usage.counts = counts;
  }

  FileView {
    path: Quickshell.statePath("launcher.json")
    printErrors: false
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: usage

      property var counts: ({})
    }
  }

  //-- Calculator --

  property var calculation: null

  function calculatorResults(): var {
    if (searchText === "" || calculation === null)
      return [];
    return [{
      kind: "calculation",
      title: calculation.result,
      subtitle: `${calculation.expression}  ·  Enter to copy`,
      icon: "",
      glyph: "=",
      text: calculation.result,
    }];
  }

  onOpenChanged: {
    if (open)
      calculation = null;
  }

  onQueryChanged: {
    if (mode === "calculator" && searchText !== "")
      calculateDelay.restart();
  }

  Timer {
    id: calculateDelay

    interval: 120
    onTriggered: {
      calculator.expression = root.searchText;
      calculator.exec(["qalc", "-t", root.searchText]);
    }
  }

  Process {
    id: calculator

    property string expression

    stdout: StdioCollector {
      id: calculatorOutput
    }

    onExited: (exitCode, exitStatus) => {
      if (exitStatus === 0 && exitCode === 0)
        root.calculation = { expression: calculator.expression, result: calculatorOutput.text.trim() };
    }
  }

  //-- Clipboard --

  function copy(text: string): void {
    Quickshell.execDetached(["wl-copy", "--", text]);
  }

  IpcHandler {
    target: root.overlayName

    function toggle(): void {
      root.toggle();
    }

    function close(): void {
      root.close();
    }
  }
}
