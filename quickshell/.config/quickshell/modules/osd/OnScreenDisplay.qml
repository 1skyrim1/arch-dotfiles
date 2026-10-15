import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
  id: root

  property string kind: "volume"

  readonly property bool isVolume: kind === "volume"
  readonly property real value: isVolume ? Audio.volume : Brightness.brightness
  readonly property bool muted: isVolume && Audio.muted

  readonly property string icon: {
    if (!isVolume)
      return Icons.brightness;
    if (muted || value === 0)
      return Icons.volumeOff
    const levels = Icons.volumeLevels;
    return levels[Math.min(levels.length - 1, Math.floor(value * levels.length))];
  }

  Connections {
    target: Osd

    function onKindChanged(): void {
      if (Osd.kind !== "")
        root.kind = Osd.kind;
    }
  }

  screen: Hypr.focusedScreen
  visible: Osd.shown || card.opacity > 0

  anchors.bottom: true
  margins.bottom: Appearance.osdMargin
  implicitWidth: Appearance.osdWidth
  implicitHeight: Appearance.osdHeight

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "myshell-osd"
  mask: Region {}
  color: "transparent"

  Rectangle {
    id: card

    anchors.fill: parent
    radius: height / 2
    color: Colors.popupBackground
    opacity: Osd.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Appearance.animationDuration }
    }

    RowLayout {
      anchors {
        fill: parent
        leftMargin: Appearance.osdPadding
        rightMargin: Appearance.osdPadding
      }
      spacing: Appearance.osdPadding

      StyledText {
        Layout.preferredWidth: Appearance.iconSize * 1.5
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        color: root.muted ? Colors.foregroundMuted : Colors.foreground
        font.pixelSize: Appearance.iconSize
      }

      LevelBar {
        Layout.fillWidth: true
        value: root.value
        opacity: root.muted ? 0.4 : 1
      }

      StyledText {
        id: number

        Layout.preferredWidth: widest.width
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100)
        color: root.muted ? Colors.foregroundMuted : Colors.foreground

        TextMetrics {
          id: widest

          font: number.font
          text: "100"
        }
      }
    }
  }
}
