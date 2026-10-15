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

  //-- Roles --

  // Desktop-level surface
  readonly property color background: blend("surface")
  readonly property color pillBackground: blend("surface_container")
  readonly property color pillBackgroundHover: blend("surface_container_highest")
  readonly property color popupBackground: blend("surface_container")
  // Things that sit on a popup: fields, buttons, the selected list row.
  readonly property color surfaceRaised: blend("surface_container_highest")

  // Text and icons.
  readonly property color foreground: blend("on_surface")
  readonly property color foregroundMuted: blend("on_surface_variant")

  // The wallpaper's main color, and text/icons placed on top of it.
  readonly property color accent: blend("primary")
  readonly property color foregroundOnAccent: blend("on_primary")
  // A second, contrasting color (e.g. the upload line next to download).
  readonly property color accentSecondary: blend("tertiary")

  readonly property color warning: blend("tertiary")
  readonly property color critical: blend("error")

  // Details
  readonly property color sliderTrack: blend("outline_variant")
  readonly property color workspaceEmpty: blend("outline_variant")
  readonly property color workspaceOccupied: blend("on_surface_variant")

  //-- The Palette --
  property var palette: fallback
  property var previousPalette: fallback
  property real progress: 1

  property bool loaded: false

  readonly property string paletteFile: Config.greeterMode
    ? `${Config.sharedDir}/palette.json`
    : Quickshell.statePath("palette.json")

  function show(newPalette: var): void {
    fade.stop();
    progress = 0;
    previousPalette = palette;
    palette = newPalette;
    fade.start();
  }

  function blend(name: string): color {
    const from = previousPalette[name] ?? fallback[name];
    const to = palette[name] ?? fallback[name];
    return Qt.tint(from, Qt.alpha(to, progress))
  }

  NumberAnimation {
    id: fade

    target: root
    property: "progress"
    to: 1
    duration: Appearance.themeTransitionDuration
    easing.type: Easing.InOutCubic
  }

  readonly property var fallback: ({
    surface: "#141218",
    surface_container: "#211f24",
    surface_container_highest: "#36343a",
    on_surface: "#e6e0e9",
    on_surface_variant: "#cac4cf",
    primary: "#cfbdfe",
    on_primary: "#36275d",
    tertiary: "#efb8c8",
    error: "#ffb4ab",
    outline_variant: "#49454e",
  })

  FileView {
    path: root.paletteFile
    blockLoading: true
    printErrors: false

    onLoaded: {
      try {
        const colors = JSON.parse(text()).colors;
        root.palette = colors;
        root.previousPalette = colors;
        root.loaded = true;
      } catch (error) {
        console.warn(`Colors: ${root.paletteFile} is broken (${error}), using the fallback`);
      }
    }
  }
}
