import QtQuick
import qs.services

Rectangle {
  required property MouseArea mouseArea

  anchors.fill: parent
  color: Colors.foreground
  opacity: mouseArea.pressed ? 0.12 : mouseArea.containsMouse ? 0.08 : 0

  Behavior on opacity {
    NumberAnimation { duration: 120 }
  }
}
