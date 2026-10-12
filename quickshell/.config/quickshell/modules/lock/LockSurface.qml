import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

WlSessionLockSurface {
  id: root

  readonly property string userName: Quickshell.env("USER") ?? ""

  color: Colors.background

  Item {
    id: content

    anchors.fill: parent

    opacity: 0
    Component.onCompleted: {
      opacity = 1;
      passwordField.focusInput();
    }
    Behavior on opacity {
      NumberAnimation { duration: Appearance.animationDuration }
    }

    BlurredWallpaper {
      anchors.fill: parent
    }

    //-- Date and time --

    DateTimeHeader {
      anchors {
        top: parent.top
        topMargin: parent.height * 0.12
        horizontalCenter: parent.horizontalCenter
      }
    }

    //-- User and password --

    ColumnLayout {
      anchors {
        bottom: parent.bottom
        bottomMargin: parent.height * 0.1
        horizontalCenter: parent.horizontalCenter
      }
      spacing: Appearance.cardPadding

      UserAvatar {
        Layout.alignment: Qt.AlignHCenter
        source: `file://${Quickshell.env("HOME")}/.face`
        name: root.userName
      }

      StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: root.userName
        font.pixelSize: Appearance.popupTitleSize
      }

      PasswordField {
        id: passwordField

        Layout.alignment: Qt.AlignHCenter

        onAccepted: {
          Lock.authenticate(text);
          text = "";
        }
      }

      StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: implicitHeight
        text: Lock.errorMessage || " "
        color: Colors.critical
      }
    }
  }

  Connections {
    target: Lock

    function onAuthenticationFailed(): void {
      passwordField.shake();
      passwordField.focusInput();
    }
  }
}
