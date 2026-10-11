// Draws the wallpaper on every monitor.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

Scope {
  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      required property ShellScreen modelData

      screen: modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.namespace: "myshell-background"

      exclusionMode: ExclusionMode.Ignore

      color: Colors.background

      Image {
        anchors.fill: parent
        source: Wallpaper.current

        fillMode: Image.PreserveAspectCrop

        asynchronous: true
      }
    }
  }
}
