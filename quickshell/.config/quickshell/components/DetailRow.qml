import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
  id: root

  property string label
  property string value

  Layout.fillWidth: true
  visible: value !== ""

  StyledText {
    Layout.fillWidth: true
    text: root.label
    color: Colors.foregroundMuted
  }

  StyledText {
    text: root.value
  }
}
