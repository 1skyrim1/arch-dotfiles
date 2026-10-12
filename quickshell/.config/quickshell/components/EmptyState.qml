import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

ColumnLayout {
  id: root

  property string icon
  property string text

  Layout.fillWidth: true
  Layout.topMargin: Appearance.cardPadding
  Layout.bottomMargin: Appearance.cardPadding
  spacing: Appearance.popupRowPadding

  StyledText {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: root.icon
    color: Colors.foregroundMuted
    font.pixelSize: Appearance.cardIconSize
  }

  StyledText {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: root.text
    color: Colors.foregroundMuted
  }
}
