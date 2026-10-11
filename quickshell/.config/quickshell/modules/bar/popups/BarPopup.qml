import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

PopupWindow {
  id: root

  required property Item anchorItem

  default property alias content: column.data

  anchor {
    item: root.anchorItem
    rect.x: root.anchorItem.width / 2
    rect.y: root.anchorItem.height + Appearance.popupGap
    rect.width: 1
    rect.height: 1
    edges: Edges.Top
    gravity: Edges.Bottom
  }

  grabFocus: true
  color: "transparent"
  implicitWidth: Appearance.popupWidth
  implicitHeight: column.implicitHeight + 2 * Appearance.popupPadding

  Rectangle {
    anchors.fill: parent
    radius: Appearance.popupRadius
    color: Colors.popupBackground

    Behavior on color {
      ColorAnimation { duration: Appearance.animationDuration }
    }

    ColumnLayout {
      id: column

      anchors {
        fill: parent
        margins: Appearance.popupPadding
      }
      spacing: Appearance.popupSpacing
    }
  }
}
