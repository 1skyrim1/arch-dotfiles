import QtQuick
import qs.config
import qs.services

Rectangle {
  id: root

  property alias text: input.text
  property alias echoMode: input.echoMode
  property string placeholderText

  signal accepted()
  signal cancelled()

  function focusInput(): void {
    input.forceActiveFocus();
  }

  implicitHeight: Appearance.fieldHeight
  radius: Appearance.popupRowRadius
  color: Colors.surfaceRaised
  border.width: input.activeFocus ? 2 : 0
  border.color: Colors.accent

  TextInput {
    id: input

    anchors {
      fill: parent
      leftMargin: Appearance.popupRowPadding + 4
      rightMargin: Appearance.popupRowPadding + 4
    }
    verticalAlignment: TextInput.AlignVCenter
    color: Colors.foreground
    selectionColor: Colors.accent
    selectedTextColor: Colors.foregroundOnAccent
    font.family: Appearance.fontFamily
    font.pixelSize: Appearance.fontSize
    clip: true
    selectByMouse: true

    onAccepted: root.accepted()
    Keys.onEscapePressed: root.cancelled()
  }

  StyledText {
    anchors.fill: input
    visible: input.text === ""
    verticalAlignment: Text.AlignVCenter
    text: root.placeholderText
    color: Colors.foregroundMuted
  }
}
