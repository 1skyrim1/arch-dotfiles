import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
  id: root

  default property alias content: column.data

  implicitWidth: column.implicitWidth + 2 * Appearance.overlayPadding
  implicitHeight: column.implicitHeight + 2 * Appearance.overlayPadding
  radius: Appearance.overlayRadius
  color: Colors.popupBackground
  clip: true

  Behavior on implicitHeight {
    NumberAnimation {
      duration: Appearance.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  MouseArea {
    anchors.fill: parent
  }

  ColumnLayout {
    id: column

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: Appearance.overlayPadding
    }
    spacing: Appearance.popupSpacing
  }
}
