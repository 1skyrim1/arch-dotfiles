import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services

ClippingRectangle {
  id: root

  property string source
  property string name
  property real size: Appearance.lockAvatarSize

  implicitWidth: size
  implicitHeight: size
  radius: size / 2
  color: Colors.surfaceRaised

  StyledText {
    anchors.centerIn: parent
    visible: picture.status !== Image.Ready
    text: root.name.charAt(0).toUpperCase()
    font.pixelSize: root.size * 0.4
    font.bold: true
  }

  Image {
    id: picture

    anchors.fill: parent
    source: root.source
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    sourceSize.width: root.size * 2
    sourceSize.height: root.size * 2
  }
}
