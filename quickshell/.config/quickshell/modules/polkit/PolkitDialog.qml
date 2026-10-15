// The password dialog for programs that need admin rights, over the
// blurred wallpaper (the logic is in services/Polkit.qml):
//
//      ╭────────────────────────────────────────╮
//      │                 (lock)                 │
//      │        Authentication required         │
//      │   Authentication is required to run    │
//      │  `/usr/bin/gparted' as the super user  │
//      │                                        │
//      │             (avatar) Philip            │
//      │  [ ••••••••                         ]  │
//      │       Wrong password, try again        │
//      │                   [ Cancel ] [ Allow ] │
//      ╰────────────────────────────────────────╯
//
// Enter submits, Esc or Cancel refuses. Clicking outside does nothing:
// a stray click shouldn't throw away a half-typed password, nor answer
// "no" to the program behind your back.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Overlay {
  id: root

  function submit(): void {
    if (field.text === "")
      return;
    Polkit.submit(field.text);
    field.text = "";
  }

  name: "polkit"
  backdrop: "blur"
  closeOnBackdropClick: false

  onOpened: field.focusInput()

  Connections {
    target: Polkit

    function onRequestStarted(): void {
      field.text = "";
      field.focusInput();
    }
  }

  OverlayCard {
    anchors.centerIn: parent
    width: Appearance.polkitWidth

    Item {
      Layout.alignment: Qt.AlignHCenter
      implicitWidth: Appearance.polkitIconSize
      implicitHeight: Appearance.polkitIconSize

      readonly property string source: Polkit.iconName !== "" ? Quickshell.iconPath(Polkit.iconName, true) : ""

      IconImage {
        anchors.fill: parent
        visible: parent.source !== ""
        source: parent.source
        asynchronous: true
      }

      StyledText {
        anchors.centerIn: parent
        visible: parent.source === ""
        text: Icons.lock
        color: Colors.accent
        font.pixelSize: Appearance.polkitIconSize * 0.75
      }
    }

    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: "Authentication required"
      font.pixelSize: Appearance.popupTitleSize
      font.bold: true
    }

    StyledText {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: Polkit.message
      color: Colors.foregroundMuted
      wrapMode: Text.Wrap
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: Appearance.cardPadding
      spacing: Appearance.popupRowPadding

      UserAvatar {
        size: Appearance.polkitAvatarSize
        source: `file://${Quickshell.env("HOME")}/.face`
        name: Polkit.userName
      }

      StyledText {
        text: Polkit.userName
      }
    }

    PasswordField {
      id: field

      Layout.fillWidth: true
      busy: Polkit.checking
      placeholderText: Polkit.checking ? "Checking..." : (Polkit.prompt || "Password")
      echoMode: Polkit.flow?.responseVisible ? TextInput.Normal : TextInput.Password

      onAccepted: root.submit()
      onCancelled: Overlays.close()
    }

    StyledText {
      Layout.fillWidth: true
      horizontalAlignment: Qt.AlignHCenter
      text: Polkit.status || " "
      color: Polkit.statusIsError ? Colors.critical : Colors.foregroundMuted
      wrapMode: Text.Wrap
    }

    RowLayout {
      Layout.alignment: Qt.AlignRight
      spacing: Appearance.popupRowPadding

      StyledButton {
        text: "Cancel"
        onClicked: Overlays.close()
      }

      StyledButton {
        text: "Allow"
        primary: true
        enabled: field.text !== "" && !Polkit.checking
        onClicked: root.submit()
      }
    }
  }
}
