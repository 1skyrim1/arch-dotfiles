pragma Singleton

// Turns the wallpaper into the shell's colors, in three steps:
//  1. Load:      read colors.json (written by matugen) into 'scheme'.
//  2. Generate:  run matugen whenever the wallpaper changes.
//  3. Roles:     map the raw Material colors to semantic roles.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  // 3. Semantic Rols: the only colors other files may use.

  readonly property color background: scheme.m3surface

  readonly property color pillBackground: Qt.rgba(scheme.m3surfaceContainer.r,
                                                  scheme.m3surfaceContainer.g,
                                                  scheme.m3surfaceContainer.b, 0.9)
  readonly property color pillBackgroundHover: scheme.m3surfaceContainerHigh

  readonly property color foreground: scheme.m3onSurface
  readonly property color foregroundMuted: scheme.m3onSurfaceVariant

  readonly property color accent: scheme.m3primary
  readonly property color foregroundOnAccent: scheme.m3onPrimary

  readonly property color warning: scheme.m3tertiary
  readonly property color critical: scheme.m3error

  readonly property color workspaceEmpty: scheme.m3outlineVariant
  readonly property color workspaceOccupied: scheme.m3outline

  readonly property color popupBackground: scheme.m3surfaceContainer
  readonly property color sliderTrack: scheme.m3surfaceContainerHigh

  readonly property color surfaceRaised: scheme.m3surfaceContainerHigh
  readonly property color accentSecondary: scheme.m3tertiary

  // 2. Generate: run matugen when the wallpaper changes
  property bool regeneratePending: false

  function regenerate(): void {
    if (Config.greeterMode || Wallpaper.current === "")
      return;
    if (generator.running) {
      regeneratePending = true;
      return;
    }
    generator.running = true;
  }

  Connections {
    target: Wallpaper

    function onCurrentChanged() {
      root.regenerate();
    }
  }

  Process {
    id: generator

    command: ["matugen", "image", Wallpaper.current,
              "--mode", Config.colorMode]

    stderr: StdioCollector {
      onStreamFinished: {
        if (text !== "")
          console.warn("matugen:", text);
      }
    }

    onExited: {
      if (root.regeneratePending) {
        root.regeneratePending = false;
        root.regenerate();
      }
    }
  }

  // 1. Load: read colors.json into `scheme`

  FileView {
    path: Config.greeterMode ? `${Config.sharedDir}/colors.json` : Quickshell.statePath("colors.json")
    watchChanges: true
    onFileChanged: reload()
    printErrors: false

    adapter: JsonAdapter {
      id: scheme

      property color m3surface: "#303446"
      property color m3surfaceContainer: "#232634"
      property color m3surfaceContainerHigh: "#414559"
      property color m3onSurface: "#c6d0f5"
      property color m3onSurfaceVariant: "#a5adce"
      property color m3outline: "#737994"
      property color m3outlineVariant: "#51576d"
      property color m3primary: "#8caaee"
      property color m3onPrimary: "#232634"
      property color m3tertiary: "#ef9f76"
      property color m3error: "#e78284"
    }
  }
}
