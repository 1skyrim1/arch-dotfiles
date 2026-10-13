// Shared frame for every overlay

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
  id: root

  required property string name

  // "dim": a dark layer you still see your windows through (launcher)
  // "blur": the blurred wallpaper, hiding your windows (session menu)
  // "none": nothing: windows stay fully visible (wallpaper switcher)
  property string backdrop: "dim"
  default property alias content: contentArea.data

  readonly property bool open: Overlays.current === name

  // Animation: 0 = closed, 1 = fully open
  property real progress: 0

  property bool replaced: false

  signal opened()

  screen: Overlays.screen
  visible: open || progress > 0

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: `myshell-${name}`
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  color: "transparent"

  onOpenChanged: {
    if (open) {
      replaced = false;
      closeAnimation.stop();
      openAnimation.restart();
      opened();
    } else {
      replaced = Overlays.current !== "";
      openAnimation.stop();
      closeAnimation.restart();
    }
  }

  NumberAnimation {
    id: openAnimation

    target: root
    property: "progress"
    to: 1
    duration: Appearance.animationDurationLong
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.curveEnter
  }

  NumberAnimation {
    id: closeAnimation

    target: root
    property: "progress"
    to: 0
    duration: Appearance.animationDuration
    easing.type: Easing.InCubic
  }

  FocusScope {
    anchors.fill: parent
    focus: true
    opacity: root.progress

    Keys.onEscapePressed: Overlays.close()

    Loader {
      anchors.fill: parent
      active: root.backdrop === "blur"
      sourceComponent: BlurredWallpaper {}
    }

    Rectangle {
      anchors.fill: parent
      visible: root.backdrop === "dim"
      color: Colors.background
      opacity: Appearance.overlayDim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: Overlays.close()
    }

    Item {
      id: contentArea

      anchors.fill: parent
      visible: !root.replaced
      scale: Appearance.overlayStartScale + (1 - Appearance.overlayStartScale) * root.progress
    }
  }
}
