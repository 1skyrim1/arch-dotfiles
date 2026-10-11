import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
  id: root

  default property alias content: row.data

  property alias spacing: row.spacing
  property int horizontalPadding: Appearance.pillPadding
  property bool interactive: false

  signal clicked(MouseEvent mouse)
  signal scrolled(WheelEvent wheel)

  implicitHeight: Appearance.pillHeight
  implicitWidth: Math.max(implicitHeight, row.implicitWidth + 2 * horizontalPadding)
  radius: height / 2

  color: interactive && mouseArea.containsMouse ? Colors.pillBackgroundHover : Colors.pillBackground

  Behavior on color {
    ColorAnimation { duration: Appearance.animationDuration }
  }

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: Appearance.pillContentSpacing
  }

  // Declared after the row on purpose: later siblings are drawn on top,
  // so this receives the clicks.
  MouseArea {
    id: mouseArea

    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: mouse => root.clicked(mouse)
    onWheel: wheel => root.scrolled(wheel)
  }
}
