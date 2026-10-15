// The region selector for screenshots (Print): the frozen screen, dimmed
// except for the rectangle you drag.
//
//   ┌──────────────────────────────────────────┐
//   │░░░░░░░ Drag to select · Esc to cancel ░░░│
//   │░░░░░░░░░┏━━━━━━━━━━━━━━━┓░░░░░░░░░░░░░░░░│
//   │░░░░░░░░░┃  (bright)     ┃░░░░░░░░░░░░░░░░│
//   │░░░░░░░░░┗━━━━━━━━━━━━━━━┛░░░░░░░░░░░░░░░░│
//   │░░░░░░░░░ 640 × 360 ░░░░░░░░░░░░░░░░░░░░░░│
//   └──────────────────────────────────────────┘
//
// Drag with the left button and let go to take it. Esc or the right button
// cancels. The logic (freezing, saving) is in services/Screenshot.qml.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
  id: root

  property point start: Qt.point(0, 0)
  property point end: Qt.point(0, 0)
  property bool hasSelection: false

  readonly property rect area: Qt.rect(Math.min(start.x, end.x), Math.min(start.y, end.y),
                                       Math.abs(end.x - start.x), Math.abs(end.y - start.y))

  readonly property int minimumSize: 4

  screen: Screenshot.screen
  visible: Screenshot.selecting

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "myshell-screenshot"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  color: "black"

  // Each opening starts without a selection.
  onVisibleChanged: hasSelection = false;

  // The frozen screen. Not asynchronous: it has to be there in the very
  // first frame, or the real screen would flash through. The source is
  // emptied while hidden: the file has the same name every time, and
  // setting the same name again wouldn't load the new picture.
  Image {
    anchors.fill: parent
    source: Screenshot.selecting ? `file://${Screenshot.frozenPath}` : ""
    cache: false
    asynchronous: true
  }

  // everything drawn on top of the frozen screen. Hidden while capturing,
  // so the screenshot shows only the frozen picture.
  Item {
    anchors.fill: parent
    visible: !Screenshot.capturing

    // The dimming: four rectangles around the selection. Without a
    // selection, the bottom one covers the whole screen.
    Dim { x: 0; y: 0; width: root.width; height: root.area.y }
    Dim { x: 0; y: root.area.y + root.area.height; width: root.width; height: root.height - y }
    Dim { x: 0; y: root.area.y; width: root.area.x; height: root.area.height }
    Dim {
      x: root.area.x + root.area.width
      y: root.area.y
      width: root.width - x
      height: root.area.height
    }

    // The border, just outside the selection so it doesn't cover any
    // of the selected pixels.
    Rectangle {
      visible: root.hasSelection
      x: root.area.x - border.width
      y: root.area.y - border.width
      width: root.area.width + 2 * border.width
      height: root.area.height + 2 * border.width
      color: "transparent"
      border.width: 2
      border.color: Colors.accent
    }

    // The size in real pixels (the screenshot's size), below the
    // selection, or above it when there's no room below.
    Label {
      visible: root.hasSelection
      x: Math.min(root.area.x, root.width - width)
      y: root.area.y + root.area.height + height + 8 <= root.height
        ? root.area.y + root.area.height + 8
        : root.area.y - height - 8
      text: {
        const scale = root.screen?.devicePixelRatio ?? 1;
        return `${Math.round(root.area.width * scale)} × ${Math.round(root.area.height * scale)}`;
      }
    }

    Label {
      visible: !root.hasSelection
      anchors {
        top: parent.top
        topMargin: Appearance.osdMargin
        horizontalCenter: parent.horizontalCenter
      }
      text: "Drag to select · Esc to cancel"
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.CrossCursor

    onPressed: mouse => {
      if (mouse.button === Qt.RightButton) {
        Screenshot.cancel();
        return;
      }
      root.start = Qt.point(mouse.x, mouse.y);
      root.end = root.start;
      root.hasSelection = true;
    }

    onPositionChanged: mouse => {
      if (pressedButtons & Qt.LeftButton)
        root.end = Qt.point(Math.max(0, Math.min(root.width, mouse.x)),
                            Math.max(0, Math.min(root.height, mouse.y)));
    }

    onReleased: mouse => {
      if (mouse.button !== Qt.LeftButton)
        return;
      if (root.area.width < root.minimumSize || root.area.height < root.minimumSize)
        root.hasSelection = false;
      else
        Screenshot.captureArea(root.area);
    }
  }

  // Receives Esc.
  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: Screenshot.cancel()
  }

  //-- Inline components --

  component Dim: Rectangle {
    color: "black"
    opacity: 0.45
  }

  component Label: Rectangle {
    property alias text: labelText.text

    width: labelText.implicitWidth + 2 * Appearance.popupRowPadding
    height: labelText.implicitHeight + 2 * Appearance.popupRowPadding
    radius: height / 2
    color: Colors.popupBackground

    StyledText {
      id: labelText

      anchors.centerIn: parent
    }
  }
}
