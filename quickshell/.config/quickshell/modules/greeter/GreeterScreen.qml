import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

Scope {
  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: window

      required property ShellScreen modelData

      readonly property bool primary: modelData === Quickshell.screens[0]

      screen: modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "myshell-greeter"
      WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      color: Colors.background

      BlurredWallpaper {
        anchors.fill: parent
      }

      DateTimeHeader {
        anchors {
          top: parent.top
          topMargin: parent.height * 0.12
          horizontalCenter: parent.horizontalCenter
        }
      }

      //-- Login (main screen only) --

      ColumnLayout {
        visible: window.primary
        anchors {
          bottom: parent.bottom
          bottomMargin: parent.height * 0.1
          horizontalCenter: parent.horizontalCenter
        }
        spacing: Appearance.cardPadding

        UserAvatar {
          Layout.alignment: Qt.AlignHCenter
          source: Greeter.selected?.avatar ?? ""
          name: Greeter.selected?.displayName ?? ""
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: Greeter.selected?.displayName ?? ""
          font.pixelSize: Appearance.popupTitleSize
        }

        PasswordField {
          id: passwordField

          Layout.alignment: Qt.AlignHCenter
          busy: Greeter.busy
          Component.onCompleted: {
            if (window.primary)
              focusInput();
          }

          onAccepted: {
            Greeter.login(text);
            text = "";
          }

          onCancelled: {
            if (Greeter.preview)
              Qt.quit();
          }
        }

        StyledText {
          Layout.alignment: Qt.AlignHCenter
          text: Greeter.errorMessage || " "
          color: Colors.critical
        }
      }

      //-- Users (bottom left) --

      ColumnLayout {
        visible: window.primary && Greeter.users.length > 1
        anchors {
          left: parent.left
          bottom: parent.bottom
          margins: Appearance.greeterEdgeMargin
        }
        spacing: Appearance.popupRowPadding

        Repeater {
          model: Greeter.users

          delegate: UserRow {
            required property var modelData

            user: modelData
            selected: modelData.name === Greeter.selectedUser
            onClicked: {
              Greeter.selectUser(modelData.name);
              passwordField.focusInput();
            }
          }
        }
      }

      //-- Power (bottom right) --

      RowLayout {
        visible: window.primary
        anchors {
          right: parent.right
          bottom: parent.bottom
          margins: Appearance.greeterEdgeMargin
        }
        spacing: Appearance.popupRowPadding

        StyledButton {
          implicitWidth: implicitHeight
          icon: Icons.reboot
          onClicked: Quickshell.execDetached(Config.rebootCommand)
        }

        StyledButton {
          implicitWidth: implicitHeight
          icon: Icons.shutdown
          onClicked: Quickshell.execDetached(Config.shutdownCommand)
        }
      }

      //-- Preview notice --

      StyledText {
        visible: Greeter.preview && window.primary
        anchors {
          top: parent.top
          left: parent.left
          margins: Appearance.greeterEdgeMargin
        }
        text: "Preview (not started by greetd) · Esc to close"
        color: Colors.foregroundMuted
      }
    }
  }

  component UserRow: Rectangle {
    id: row

    property var user
    property bool selected: false

    signal clicked()

    implicitWidth: rowContent.implicitWidth + 2 * Appearance.popupRowPadding
    implicitHeight: rowContent.implicitHeight + 2 * Appearance.popupRowPadding
    radius: height / 2
    color: selected ? Colors.pillBackground : "transparent"

    Behavior on color {
      ColorAnimation { duration: Appearance.animationDuration }
    }

    RowLayout {
      id: rowContent

      anchors.centerIn: parent
      spacing: Appearance.popupRowPadding

      UserAvatar {
        size: Appearance.greeterListAvatarSize
        source: row.user.avatar
        name: row.user.displayName
      }

      StyledText {
        text: row.user.displayName
        font.bold: row.selected
      }
    }

    StateLayer {
      mouseArea: rowMouse
      radius: row.radius
    }

    MouseArea {
      id: rowMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row.clicked()
    }
  }
}
