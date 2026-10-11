import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  //-- Output Devices --
  SectionHeader { text: "Output" }

  Repeater {
    model: Audio.outputs
    delegate: OutputRow {}
  }

  StyledSlider {
    Layout.fillWidth: true
    value: Audio.volume
    opacity: Audio.muted ? 0.4 : 1
    onMoved: newValue => Audio.setVolume(newValue)
  }

  //-- Applications --
  SectionHeader { text: "Applications" }

  StyledText {
    visible: Audio.streams.length === 0
    text: "Nothing is playing"
    color: Colors.foregroundMuted
  }

  Repeater {
    model: Audio.streams
    delegate: StreamRow {}
  }

  //-- Pieces used only in this file --

  component OutputRow: Rectangle {
    id: row

    required property PwNode modelData
    readonly property bool selected: modelData === Audio.sink

    Layout.fillWidth: true
    implicitHeight: label.implicitHeight + 2 * Appearance.popupRowPadding
    radius: Appearance.popupRowRadius
    color: selected ? Colors.accent : "transparent"

    Behavior on color {
      ColorAnimation { duration: Appearance.animationDuration }
    }

    StyledText {
      id: label

      anchors {
        left: parent.left
        right: parent.right
        verticalCenter: parent.verticalCenter
        leftMargin: Appearance.popupRowPadding
        rightMargin: Appearance.popupRowPadding
      }

      text: Audio.displayName(row.modelData)
      color: row.selected ? Colors.foregroundOnAccent : Colors.foreground
      elide: Text.ElideRight
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
      onClicked: Audio.setDefaultOutput(row.modelData)
    }
  }

  component StreamRow: ColumnLayout {
    id: stream

    required property PwNode modelData

    Layout.fillWidth: true
    spacing: 4

    StyledText {
      Layout.fillWidth: true
      text: Audio.displayName(stream.modelData)
      elide: Text.ElideRight
    }

    StyledSlider {
      Layout.fillWidth: true
      value: stream.modelData.audio?.volume ?? 0
      onMoved: newValue => Audio.setNodeVolume(stream.modelData, newValue)
    }
  }
}
