import QtQuick
import qs.config
import qs.services

Rectangle {
  id: root

  property string text
  property string icon
  property bool primary: false

  signal clicked()

  implicitHeight: Appearance.buttonHeight
  implicitWidth: label.implicitWidth + 2 * Appearance.buttonPadding
  radius: height / 2
  color: primary ? Colors.accent : Colors.surfaceRaised
  opacity: enabled ? 1 : 0.5

  Behavior on color {
    ColorAnimation { duration: Appearance.animationDuration}
  }

  IconLabel {
    id: label

    anchors.centerIn: parent
    icon: root.icon
    text: root.text
    iconColor: root.primary ? Colors.foregroundOnAccent : Colors.foreground
    textColor: root.primary ? Colors.foregroundOnAccent : Colors.foreground
  }

  StateLayer {
    mouseArea: mouseArea
    radius: root.radius
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
