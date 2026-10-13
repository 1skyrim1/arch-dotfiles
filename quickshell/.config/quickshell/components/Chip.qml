import QtQuick
import qs.config
import qs.services

Rectangle {
  id: root

  property string text
  property bool selected: false

  signal clicked()

  implicitWidth: label.implicitWidth + 2 * Appearance.chipPadding
  implicitHeight: Appearance.chipHeight
  radius: height / 2
  color: selected ? Colors.accent : Colors.surfaceRaised

  StyledText {
    id: label

    anchors.centerIn: parent
    text: root.text
    color: root.selected ? Colors.foregroundOnAccent : Colors.foreground
  }

  StateLayer {
    mouseArea: mouseArea
    radius: root.radius
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointinHandCursor
    onClicked: root.clicked()
  }
}
