// The media popup:
//
//   ┌─────┐  Title
//   │ art │  Artist
//   └─────┘  Album · Player
//   ●────────────○──────────  (drag to seek)
//   1:23                3:45
//      ⤮    ⏮    ⏯    ⏭    ↻
//   [Spotify] [Firefox]        (only with more than one player)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  implicitWidth: Appearance.mediaPopupWidth

  function formatTime(seconds: real): string {
    const total = Math.max(0, Math.floor(seconds));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor(total / 60) % 60;
    const secs = String(total % 60).padStart(2, "0");
    return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${secs}` : `${minutes}:${secs}`;
  }

  //-- Nothing playing --

  EmptyState {
    visible: !Media.active
    icon: Icons.music
    text: "Nothing is playing"
  }

  //-- Art and track info --

  RowLayout {
    Layout.fillWidth: true
    visible: Media.active
    spacing: Appearance.cardPadding

    ClippingRectangle {
      implicitWidth: Appearance.mediaArtSize
      implicitHeight: Appearance.mediaArtSize
      radius: Appearance.cardRadius
      color: Colors.surfaceRaised

      StyledText {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        text: Icons.music
        color: Colors.foregroundMuted
        font.pixelSize: Appearance.cardIconSize
      }

      Image {
        id: cover

        anchors.fill: parent
        source: Media.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: Appearance.mediaArtSize * 2
        sourceSize.height: Appearance.mediaArtSize * 2
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      StyledText {
        Layout.fillWidth: true
        text: Media.title || "Unknown title"
        font.bold: true
        font.pixelSize: Appearance.popupTitleSize
        elide: Text.ElideRight
      }

      StyledText {
        Layout.fillWidth: true
        text: [Media.album, Media.playerName].filter(Boolean).join(" · ")
        color: Colors.foregroundMuted
        elide: Text.ElideRight
      }
    }
  }

  //-- Progress --

  ColumnLayout {
    Layout.fillWidth: true
    visible: Media.active && Media.length > 0
    spacing: 2

    StyledSlider {
      id: progress

      property real dragValue: 0

      Layout.fillWidth: true
      value: pressed ? dragValue : Media.position / Media.length
      enabled: Media.canSeek
      onMoved: newValue => dragValue = newValue
      onReleased: newValue => Media.seekTo(newValue * Media.length)
    }

    RowLayout {
      Layout.fillWidth: true

      StyledText {
        Layout.fillWidth: true
        text: root.formatTime(progress.pressed ? progress.dragValue * Media.length : Media.position)
        color: Colors.foregroundMuted
        font.pixelSize: Appearance.fontSizeSmall
      }

      StyledText {
        text: root.formatTime(Media.length)
        color: Colors.foregroundMuted
        font.pixelSize: Appearance.fontSizeSmall
      }
    }
  }

  //-- Controls --

  RowLayout {
    Layout.alignment: Qt.AlignHCenter
    visible: Media.active
    spacing: Appearance.mediaControlSpacing

    ControlButton {
      visible: Media.shuffleSupported
      icon: Icons.shuffle
      highlighted: Media.shuffle
      onClicked: Media.toggleShuffle()
    }

    ControlButton {
      icon: Icons.previous
      enabled: Media.canGoPrevious
      onClicked: Media.previous()
    }

    StyledButton {
      implicitWidth: implicitHeight
      primary: true
      icon: Media.playing ? Icons.pauseControl : Icons.playControl
      enabled: Media.canTogglePlaying
      onClicked: Media.togglePlaying()
    }

    ControlButton {
      icon: Icons.next
      enabled: Media.canGoNext
      onClicked: Media.next()
    }

    ControlButton {
      visible: Media.loopSupported
      icon: Media.loopState === MprisLoopState.Track ? Icons.repeatOne
          : Media.loopState === MprisLoopState.Playlist ? Icons.repeat
          : Icons.repeatOff
      highlighted: Media.loopState !== MprisLoopState.None
      onClicked: Media.cycleLoop()
    }
  }

  //-- Player Switcher --

  Flow {
    Layout.fillWidth: true
    visible: Media.players.length > 1
    spacing: Appearance.popupRowPadding

    Repeater {
      model: Media.players

      delegate: StyledButton {
        required property MprisPlayer modelData

        text: modelData.identity
        primary: modelData === Media.player
        onClicked: Media.choosePlayer(modelData)
      }
    }
  }

  //-- Inline Components --

  component ControlButton: Rectangle {
    id: control

    property string icon
    property bool highlighted: false

    signal clicked()

    implicitWidth: Appearance.buttonHeight
    implicitHeight: Appearance.buttonHeight
    radius: width / 2
    color: "transparent"
    opacity: enabled ? 1 : 0.4

    StyledText {
      anchors.centerIn: parent
      text: control.icon
      color: control.highlighted ? Colors.accent : Colors.foreground
      font.pixelSize: Appearance.iconSize
    }

    StateLayer {
      mouseArea: controlMouse
      radius: control.radius
    }

    MouseArea {
      id: controlMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: control.clicked()
    }
  }
}
