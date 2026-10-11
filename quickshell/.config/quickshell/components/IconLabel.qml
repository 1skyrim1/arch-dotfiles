import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
  id: root

  property string icon
  property string text
  property color iconColor: Colors.foreground
  property color textColor: Colors.foreground

  property real maximumTextWidth: Number.POSITIVE_INFINITY

  spacing: Appearance.pillContentSpacing

  StyledText {
    visible: root.icon !== ""
    text: root.icon
    color: root.textColor
    font.pixelSize: Appearance.iconSize
  }

  StyledText {
    visible: root.text !== ""
    text: root.text
    color: root.textColor
    elide: Text.ElideRight

    Layout.maximumWidth: root.maximumTextWidth
  }
}
