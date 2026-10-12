import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

Scope {
  LazyLoader {
    active: Session.menuVisible

    PanelWindow {
      id: window

      readonly property var actions: [
        { id: "shutdown", label: "Shutdown", icon: Icons.shutdown },
        { id: "reboot", label: "Reboot", icon: Icons.reboot },
        { id: "logout", label: "Log out", icon: Icons.logout },
        { id: "suspend", label: "Sleep", icon: Icons.sleep },
        { id: "lock", label: "Lock", icon: Icons.lock },
      ]

      property int currentIndex: actions.length - 1

      function move(step: int): void {
        currentIndex = (currentIndex + step + actions.length) % actions.length;
      }

      function runCurrent(): void {
        Session.run(actions[currentIndex].id);
      }

      screen: Hypr.focusedScreen

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "myshell-session"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      color: "transparent"

      Item {
        id: content

        anchors.fill: parent
        focus: true

        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity {
          NumberAnimation { duration: Appearance.animationDuration }
        }

        Keys.onPressed: event => {
          switch (event.key) {
          case Qt.Key_Left:
          case Qt.Key_H:
          case Qt.Key_Backtab:
            window.move(-1);
            break;
          case Qt.Key_Right:
          case Qt.Key_L:
          case Qt.Key_Tab:
            window.move(1);
            break;
          case Qt.Key_Return:
          case Qt.Key_Enter:
          case Qt.Key_Space:
            window.runCurrent();
            break;
          case Qt.Key_Escape:
            Session.closeMenu();
            break;
          default:
            return;
          }
          event.accepted = true;
        }

        BlurredWallpaper {
          anchors.fill: parent
        }

        MouseArea {
          anchors.fill: parent
          onClicked: Session.closeMenu()
        }

        Row {
          anchors.centerIn: parent
          spacing: Appearance.sessionTileSpacing

          Repeater {
            model: window.actions

            delegate: SessionTile {
              required property var modelData
              required property int index

              icon: modelData.icon
              label: modelData.label
              selected: index === window.currentIndex
              onHovered: window.currentIndex = index
              onClicked: Session.run(modelData.id)
            }
          }
        }
      }
    }
  }

  component SessionTile: Rectangle {
    id: tile

    property string icon
    property string label
    property bool selected: false

    signal hovered()
    signal clicked()

    width: Appearance.sessionTileWidth
    height: Appearance.sessionTileHeight
    radius: Appearance.sessionTileRadius
    color: selected ? Colors.accent : "transparent"
    scale: selected ? 1.06 : 1

    Behavior on color {
      ColorAnimation { duration: Appearance.animationDuration }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.OutCubic
      }
    }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: Appearance.cardPadding

      StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: tile.icon
        color: tile.selected ? Colors.foregroundOnAccent : Colors.foreground
        font.pixelSize: Appearance.sessionIconSize
      }

      StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: tile.label
        color: tile.selected ? Colors.foregroundOnAccent : Colors.foreground
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: tile.hovered()
      onClicked: tile.clicked()
    }
  }
}
