import QtQuick
import qs.config
import qs.services

Item {
  id: root

  property real value: 0

  signal moved(real newValue)

  readonly property real clampedValue: Math.max(0, Math.min(1, value))

  implicitWidth: 200
  implicitHeight: Appearance.sliderHeight

  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    height: Appearance.sliderTrackHeight
    radius: height / 2
    color: Colors.sliderTrack

    Rectangle {
      width: parent.width * root.clampedValue
      height: parent.height
      radius: height / 2
      color: Colors.accent
    }
  }

  Rectangle {
    width: root.height
    height: width
    radius: width / 2
    anchors.verticalCenter: parent.verticalCenter
    x: (root.width - width) * root.clampedValue
    color: Colors.accent
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    function report(mouseX: real): void {
      root.moved(Math.max(0, Math.min(1, mouseX/width)));
    }

    onPressed: mouse => report(mouse.x)
    onPositionChanged: mouse => report(mouse.x)
  }
}
