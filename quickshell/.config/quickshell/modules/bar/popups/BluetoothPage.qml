import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

ColumnLayout {
  id: root

  property bool active: false
  spacing: Appearance.popupSpacing
  onActiveChanged: Bluetooth.setScanning(active)

  Connections {
    target: Bluetooth

    function onEnabledChanged(): void {
      if (Bluetooth.enabled && root.active)
        Bluetooth.setScanning(true);
    }
  }

  //-- Off, blocked or no Bluetooth at all --

  StyledText {
    Layout.fillWidth: true
    visible: text !== ""
    text: !Bluetooth.available ? "No Bluetooth found. Is Bluetooth.service running?"
        : Bluetooth.blocked ? "Bluetooth is blocked by a hardware switch."
        : !Bluetooth.enabled ? "Bluetooth is turned off."
        : ""
    color: Colors.foregroundMuted
    wrapMode: Text.WordWrap
  }

  //-- My Devices --

  SectionHeader {
    visible: Bluetooth.enabled && Bluetooth.pairedDevices.length > 0
    text: "My devices"
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 2

    Repeater {
      model: ScriptModel {
        values: Bluetooth.enabled ? Bluetooth.pairedDevices : []
        comparisonMode: ObjectComparison.Identity
      }

      delegate: DeviceRow {
        Layout.fillWidth: true
      }
    }
  }

  //-- Nearby --

  RowLayout {
    Layout.fillWidth: true
    visible: Bluetooth.enabled

    SectionHeader {
      Layout.fillWidth: true
      text: "Nearby"
    }

    StyledText {
      visible: Bluetooth.scanning
      text: "Scanning..."
      color: Colors.foregroundMuted
    }
  }

  ListView {
    id: nearbyList

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, Appearance.networkListMaxHeight)
    visible: Bluetooth.enabled && count > 0
    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel {
      values: Bluetooth.enabled ? Bluetooth.nearbyDevices : []
      comparisonMode: ObjectComparison.Identity
    }

    delegate: DeviceRow {
      width: nearbyList.width
    }
  }

  StyledText {
    Layout.fillWidth: true
    visible: Bluetooth.enabled && nearbyList.count === 0
    text: "Nothing found yet. Put the device in paring mode."
    color: Colors.foregroundMuted
    wrapMode: Text.WordWrap
  }
  //-- Errors --

  StyledText {
    Layout.fillWidth: true
    visible: Bluetooth.lastError !== ""
    text: Bluetooth.lastError
    color: Colors.critical
    wrapMode: Text.WordWrap
  }

  //-- Inline omponent --

  component DeviceRow: Rectangle {
    id: row

    required property var modelData

    readonly property bool busy: Bluetooth.isBusy(modelData)
    readonly property bool hovered: rowMouse.containsMouse || forgetMouse.containsMouse

    implicitHeight: Appearance.networkRowHeight
    radius: Appearance.popupRowRadius
    color: "transparent"
    opacity: busy ? 0.6 : 1

    StateLayer {
      mouseArea: rowMouse
      radius: row.radius
    }

    MouseArea {
      id: rowMouse

      anchors.fill: parent
      enabled: !row.busy
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Bluetooth.activate(row.modelData)
    }

    RowLayout {
      anchors {
        fill: parent
        leftMargin: Appearance.popupRowPadding
        rightMargin: Appearance.popupRowPadding
      }
      spacing: Appearance.popupRowPadding

      StyledText {
        text: Icons.bluetoothDevice(row.modelData.icon)
        color: row.modelData.connected ? Colors.accent : Colors.foreground
        font.pixelSize: Appearance.iconSize
      }

      StyledText {
        Layout.fillWidth: true
        text: row.modelData.name
        elide: Text.ElideRight
      }

      StyledText {
        text: Bluetooth.describe(row.modelData)
        color: Colors.foregroundMuted
      }

      StyledText {
        readonly property bool usable: row.modelData.paired && !row.busy

        opacity: usable && row.hovered ? 1 : 0
        text: Icons.close
        color: Colors.foregroundMuted

        MouseArea {
          id: forgetMouse

          anchors {
            fill: parent
            margins: -4
          }
          enabled: parent.usable
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Bluetooth.forget(row.modelData)
        }
      }
    }
  }
}
