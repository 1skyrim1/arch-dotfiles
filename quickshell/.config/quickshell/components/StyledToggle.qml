import QtQuick
import qs.config
import qs.services

Rectangle {
  id: root

  property bool checked: false

  signal toggled()

  implicitWidth: Appearance.toggleWidth
  implicitHeight: Appearance.toggleHeight
  radius: height / 2
  color: checked ? Colors.accent : Colors.surfaceRaised
  opacity: enabled ? 1 : 0.5

  Behavior on color {
    ColorAnimation { duration: Appearance.animationDuration }
  }

  // Knob slider from the left (off) to the right (on)
  Rectangle {
    width: root.height - 2 * Appearance.toggleInset
    height: width
    radius: width / 2
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - width - Appearance.toggleInset : Appearance.toggleInset
    color: root.checked ? Colors.foregroundOnAccent : Colors.foregroundMuted

    Behavior on x {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
