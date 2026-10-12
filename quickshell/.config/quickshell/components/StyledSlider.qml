import QtQuick
import qs.config
import qs.services

Item {
  id: root

  property real value: 0

  readonly property alias pressed: mouseArea.pressed

  signal moved(real newValue)
  signal released(real newValue)

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
    id: mouseArea

    function valueAt(mouseX: real): real {
      return Math.max(0, Math.min(1, mouseX / width));
    }

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    onPressed: mouse => root.moved(valueAt(mouse.x))
    onPositionChanged: mouse => root.moved(valueAt(mouse.x))
    onReleased: mouse => root.released(valueAt(mouse.x))
  }
}
