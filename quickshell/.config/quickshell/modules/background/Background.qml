// The wallpaper, on every monitor, behind all windows.
//
// A new wallpaper is revealed by a straight, slanted edge that sweeps from
// the top-right corner to the bottom-left one:
//
//   ┌────────────┐    ┌───────╱▓▓▓▓┐    ┌──╱▓▓▓▓▓▓▓▓▓┐
//   │    old     │ →  │     ╱▓▓▓▓▓▓│ →  │╱▓▓▓▓ new ▓▓│ → …
//   │            │    │   ╱▓▓▓▓▓▓▓▓│    │▓▓▓▓▓▓▓▓▓▓▓▓│
//   └────────────┘    └────────────┘    └────────────┘
//
// The edge is at a right angle to the line between those two corners, so
// it touches the top-right corner first and the bottom-left corner last.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property ShellScreen modelData

      screen: modelData
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.namespace: "myshell-background"
      // Shows only before the first wallpaper is chosen.
      color: Colors.background

      Item {
        id: wallpaper

        // How far the new wallpaper is revealed: 0 → 1.
        property real progress: 0

        // The screen's diagonal, and the direction of the sweep
        // (from the top-right toward the bottom-left corner) as an
        // angle in degrees, clockwise from "pointing right".
        readonly property real diagonal: Math.hypot(width, height)
        readonly property real sweepAngle: Math.atan2(height, -width) * 180 / Math.PI

        anchors.fill: parent

        // The wallpaper shown before the sweep. Set once at startup,
        // then takes over the new one from `incoming` after each sweep.
        WallpaperImage {
          id: base

          Component.onCompleted: path = Wallpaper.current

          // After a sweep, this one switched to the new wallpaper
          // too. Once that's loaded, it looks exactly like the
          // revealed one, and the reveal can be put away unseen.
          onStatusChanged: {
            if (status === Image.Ready && path === incoming.path)
              wallpaper.progress = 0;
          }
        }

        // The reveal: an item that only shows what's inside its own
        // rectangle (clip), tilted along the sweep direction. Its
        // left edge is the slanted line, starting at the top-right
        // corner; it grows by `progress`, which moves the line
        // across the screen. It's twice the diagonal tall, so it
        // reaches past the screen's edges on both sides of the line.
        Item {
          x: wallpaper.width
          y: -wallpaper.diagonal
          width: wallpaper.progress * wallpaper.diagonal
          height: 2 * wallpaper.diagonal
          clip: true
          transform:  Rotation {
            origin.x: 0
            origin.y: wallpaper.diagonal  // top-right corner
            angle: wallpaper.sweepAngle
          }

          // Tilted back by the same angle, around the same corner,
          // so the image itself sits straight and exactly in
          // place on screen. Only the edge of the reveal moves.
          WallpaperImage {
            id: incoming

            x: -wallpaper.width
            y: wallpaper.diagonal
            width: wallpaper.width
            height: wallpaper.height
            anchors.fill: undefined
            transform: Rotation {
              origin.x: wallpaper.width
              origin.y: 0
              angle: -wallpaper.sweepAngle
            }

            onStatusChanged: {
              if (status === Image.Ready && path === Wallpaper.current)
                sweep.restart();
            }
          }
        }

        NumberAnimation {
          id: sweep

          target: wallpaper
          property: "progress"
          from: 0
          to: 1
          duration: Appearance.themeTransitionDuration
          easing.type: Easing.InOutCubic

          // The new wallpaper now covers the screen. Hand it to
          // `base` (see its onStatusChanged).
          onFinished: base.path = incoming.path
        }

        Connections {
          target: Wallpaper

          function onCurrentChanged(): void {
            if (Wallpaper.current === base.path && !sweep.running)
              return;           // already showing
            if (incoming.path === Wallpaper.current && incoming.status === Image.Ready)
              sweep.restart();  // loaded ahead of time: go right away
            else
              incoming.path = Wallpaper.current;
          }

          // The wallpaper chosen in the switcher: load it now,
          // still hidden, so it's ready if Enter is pressed. Only
          // while the reveal is put away (progress 0): during or
          // right after a sweep, `incoming` is on screen.
          function onUpcomingChanged(): void {
            const wanted = Wallpaper.upcoming;
            if (wanted !== "" && wanted !== base.path && wallpaper.progress === 0)
              incoming.path = wanted;
          }
        }
      }
    }
  }

  // One full-screen wallpaper image.
  component WallpaperImage: Image {
    // The file to show. The image's own `source` is a URL ("file:///…"),
    // so this plain path is kept for comparing with Wallpaper.current.
    property string path

    anchors.fill: parent
    source: path
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    // Decoded at screen size, not at the file's full size: a 6K image
    // would otherwise take several times the memory, for no visible
    // difference. (With PreserveAspectCrop, it's decoded just large
    // enough to cover the screen.)
    sourceSize: Qt.size(width, height)
    // Each wallpaper is loaded once; caching it would only keep an
    // extra copy in memory.
    cache: false
  }
}
