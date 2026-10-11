import QtQuick
import qs.config
import qs.services

Rectangle {
  id: root

  property real value: 0
  property color fillColor: Colors.accent

  implicitHeight: Appearance.levelBarHeight
  radius: height / 2
  color: Colors.surfaceRaised

  Rectangle {
    width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
    height: parent.height
    radius: height / 2
    color: root.fillColor

    Behavior on width {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.OutCubic
      }
    }
    Behavior on color {
      ColorAnimation { duration: Appearance.animationDuration }
    }
  }
}
