import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

Item {
  id: root

  property string icon
  property string name
  property real size: Appearance.launcherIconSize

  readonly property string source: icon.startsWith("/")
    ? `file://${icon}`
    : Quickshell.iconPath(icon, true)

  implicitWidth: size
  implicitHeight: size

  IconImage {
    anchors.fill: parent
    visible: root.source !== ""
    source: root.source
    asynchronous: true
  }

  Rectangle {
    anchors.fill: parent
    visible: root.source === ""
    radius: root.size / 4
    color: Qt.alpha(Colors.accent, 0.18)

    StyledText {
      anchors.centerIn: parent
      text: root.name.charAt(0).toUpperCase()
      color: Colors.accent
      font.pixelSize: root.size / 2
      font.bold: true
    }
  }
}
