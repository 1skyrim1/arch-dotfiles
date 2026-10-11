// The Network popup, top to bottom:
//  1: Header with the Wi-Fi on/off switch
//  2: Current Connection: name, status, IP, gateway, signal
//  3: Live download/upload speed with a graph of the last minute
//  4: Networks in range(click to connect; asks for a password if needed)
//  5: Errors, and a shortcut to the full network settings (nmtui)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as QsNetworking
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  property QsNetworking.WifiNetwork passwordNetwork: null

  implicitWidth: Appearance.networkPopupWidth

  onVisibleChanged: {
    Network.setScanning(visible);
    if (!visible)
      passwordNetwork = null;
  }

  onPasswordNetworkChanged: {
    passwordField.text = "";
    if (passwordNetwork)
      Qt.callLater(passwordField.focusInput);
  }

  Connections {
    target: Network

    function onPasswordNeeded(network: QsNetworking.WifiNetwork): void {
      root.passwordNetwork = network;
    }
  }

  function activate(network: QsNetworking.WifiNetwork): void {
    if (Network.needsSettings(network)) {
      visible = false;
      Network.openSettings();
      return;
    }
    passwordNetwork = null;
    Network.connect(network);
  }

  function submitPassword(): void {
    if (!passwordNetwork || passwordField.text === "")
      return;
    Network.connectWihPassword(passwordNetwork, passwordField.text);
    passwordNetwork = null;
  }

  //-- 1.Header --

  RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.popupRowPadding

    StyledText {
      Layout.fillWidth: true
      text: "Network"
      font.bold: true
      font.pixelSize: Appearance.popupTitleSize
    }

    StyledText {
      visible: Network.wifiAvailable
      text: "Wi-Fi"
      color: Colors.foregroundMuted
    }

    StyledToggle {
      visible: Network.wifiAvailable
      enabled: !Network.wifiBlocked
      checked: Network.wifiEnabled && !Network.wifiBlocked
      onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
    }
  }

  //-- 2: Current connection --

  ConnectionCard {
    Layout.fillWidth: true
  }

  //-- 3: Traffic --

  TrafficCard {
    Layout.fillWidth: true
    visible: Network.online
  }

  //-- 4: Networks --

  RowLayout {
    Layout.fillWidth: true
    visible: Network.wifiAvailable && Network.wifiEnabled

    SectionHeader {
      Layout.fillWidth: true
      text: "Networks"
    }

    StyledText {
      visible: Network.scanning
      text: "Scanning..."
      color: Colors.foregroundMuted
    }
  }

  StyledText {
    visible: Network.wifiAvailable && (!Network.wifiEnabled || Network.wifiBlocked)
    text: Network.wifiBlocked ? "Wi-Fi is blocked by a hardware switch." : "Wi-Fi is turned off."
    color: Colors.foregroundMuted
  }

  // ListView instead of Repeater so that list scrolls
  ListView {
    id: networkList

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, Appearance.networkListMaxHeight)
    visible: Network.wifiAvailable && Network.wifiEnabled && count > 0
    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel {
      comparisonMode: ObjectComparison.Identity
      values: Array.from(Network.networks).filter(network => network !==Network.currentNetwork)
    }

    delegate: NetworkRow {
      width: networkList.width
      selected: modelData === root.passwordNetwork
      onClicked: root.activate(modelData)
    }
  }

  // Password Prompt
  ColumnLayout {
    Layout.fillWidth: true
    visible: root.passwordNetwork !== null
    spacing: Appearance.popupRowPadding

    StyledText {
      Layout.fillWidth: true
      text: `Password for “${root.passwordNetwork?.name ?? ""}”`
      elide: Text.ElideRight
    }

    StyledTextField {
      id: passwordField

      Layout.fillWidth: true
      echoMode: TextInput.Password
      placeholderText: "Password"
      onAccepted: root.submitPassword()
      onCancelled: root.passwordNetwork = null
    }

    RowLayout {
      Layout.alignment: Qt.AlignRight

      StyledButton {
        text: "Cancel"
        onClicked: root.passwordNetwork = null
      }
      
      StyledButton {
        text: "Connect"
        primary: true
        enabled: passwordField.text !== ""
        onClicked: root.submitPassword()
      }
    }
  }

  //-- 5. Errors and settings --

  StyledText {
    Layout.fillWidth: true
    visible: Network.lastError !== ""
    text: Network.lastError
    color: Colors.critical
    wrapMode: Text.WordWrap
  }

  StyledButton {
    Layout.alignment: Qt.AlignRight
    icon: Icons.settings
    text: "Network settings"
    onClicked: {
      root.visible = false;
      Network.openSettings();
    }
  }

  // Used only in this file

  component Card: Rectangle {
    default property alias content: cardColumn.data

    implicitHeight: cardColumn.implicitHeight + 2 * Appearance.cardPadding
    radius: Appearance.cardRadius
    color: Colors.surfaceRaised

    ColumnLayout {
      id: cardColumn

      anchors {
        fill: parent
        margins: Appearance.cardPadding
      }
      spacing: Appearance.popupRowPadding
    }
  }

  component ConnectionCard: Card {
    id: card

    readonly property QsNetworking.WifiNetwork network: Network.currentNetwork
    readonly property bool wifiConnected: Network.kind === "wifi" && (network?.connected ?? false)

    readonly property string title: Network.kind === "wired" ? "Ethernet"
                                  : network ? network.name
                                  : "Not Connected"

    readonly property string subtitle: {
      if (Network.kind === "wired")
        return Network.primaryInterface;
      if (Network.connecting)
        return "Connecting";
      if (network?.stateChanging)
        return "Disconnecting...";
      if (wifiConnected) {
        const channel = Network.channel ? `Channel ${Network.channel}` : "";
        return ["Connected", Network.band, channel].filter(Boolean).join(" · ");
      }
      if (Network.wifiAvailable && Network.wifiEnabled)
        return "Choose a network below";
      return Network.wifiAvailable ? "Wi-Fi is off" : "No connection";
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Appearance.cardPadding

      StyledText {
        text: Icons.network(Network.kind, Network.signalLevel(card.network))
        color: Network.online ? Colors.accent : Colors.foregroundMuted
        font.pixelSize: Appearance.cardIconSize
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        StyledText {
          Layout.fillWidth: true
          text: card.title
          font.bold: true
          elide: Text.ElideRight
        }

        StyledText {
          Layout.fillWidth: true
          text: card.subtitle
          color: Colors.foregroundMuted
          elide: Text.ElideRight
        }
      }
    }

    DetailRow {
      label: "IP address"
      value: Network.ipAddress
    }

    DetailRow {
      label: "Gateway"
      value: Network.gateway
    }

    DetailRow {
      label: "Signal"
      value: card.wifiConnected ? `${Math.round(card.network.signalStrength * 100)}%` : ""
    }

    RowLayout {
      Layout.alignment: Qt.AlignRight
      visible: card.network !== null

      StyledButton {
        visible: card.network?.known ?? false
        enabled: !(card.network?.stateChanging ?? true)
        text: "Forget"
        onClicked: Network.forget(card.network)
      }

      StyledButton {
        enabled: !(card.network?.stateChanging ?? true)
        text: "Disconnect"
        onClicked: Network.disconnect()
      }
    }
  }

  component TrafficCard: Card {
    id: traffic

    readonly property real graphMaximum: Math.max(4*1024,
                                                  ...Array.from(Network.downloadHistory),
                                                  ...Array.from(Network.uploadHistory))

    function formatRate(bytesPerSecond: real): string {
      const units = ["B/s", "KB/s", "MB/s", "GB/s"];
      let value = bytesPerSecond;
      let unit = 0;
      while (value >= 1000 && unit < units.length - 1) {
        value /= 1024;
        unit++;
      }
      const shown = unit > 0 && value < 10 ? value.toFixed(1): Math.round(value);
      return `${shown} ${units[unit]}`;
    }

    RowLayout {
      Layout.fillWidth: true

      Stat {
        Layout.fillWidth: true
        label: "Download"
        icon: Icons.arrowDown
        value: traffic.formatRate(Network.downloadRate)
        accent: Colors.accent
      }

      Stat {
        Layout.fillWidth: true
        label: "Upload"
        icon: Icons.arrowUp
        value: traffic.formatRate(Network.uploadRate)
        accent: Colors.accentSecondary
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: Appearance.graphHeight
      radius:Appearance.graphRadius
      color: Colors.popupBackground

      Item {
        anchors {
          fill: parent
          margins: Appearance.graphPadding
        }

        Sparkline {
          anchors.fill: parent
          values: Network.downloadHistory
          capacity: Config.trafficHistoryLength
          maximum: traffic.graphMaximum
          color: Colors.accent
          filled: true
        }

        Sparkline {
          anchors.fill: parent
          values: Network.uploadHistory
          capacity: Config.trafficHistoryLength
          maximum: traffic.graphMaximum
          color: Colors.accentSecondary
        }
      }

      StyledText {
        anchors {
          top: parent.top
          right: parent.right
          margins: Appearance.graphPadding
        }
        text: traffic.formatRate(traffic.graphMaximum)
        color: Colors.foregroundMuted
        font.pixelSize: Appearance.fontSizeSmall
      }
    }
  }

  component Stat: ColumnLayout {
    id: stat

    property string label
    property string icon
    property string value
    property color accent

    spacing: 2

    StyledText {
      text: stat.label
      color: Colors.foregroundMuted
    }

    IconLabel {
      icon: stat.icon
      text: stat.value
      iconColor: stat.accent
    }
  }

  component NetworkRow: Rectangle {
    id: row

    required property QsNetworking.WifiNetwork modelData
    property bool selected: false

    signal clicked()

    implicitHeight: Appearance.networkRowHeight
    radius: Appearance.popupRowRadius
    color: selected ? Colors.surfaceRaised : "transparent"

    RowLayout {
      anchors {
        fill: parent
        leftMargin: Appearance.popupRowPadding
        rightMargin: Appearance.popupRowPadding
      }
      spacing: Appearance.popupRowPadding

      StyledText {
        text: Icons.wifiLevels[Network.signalLevel(row.modelData)]
        font.pixelSize: Appearance.iconSize
      }

      StyledText {
        Layout.fillWidth: true
        text: row.modelData?.name ?? ""
        elide: Text.ElideRight
      }

      StyledText {
        visible: row.modelData?.known ?? false
        text: "Saved"
        color: Colors.foregroundMuted
      }

      StyledText {
        visible: Network.isSecured(row.modelData)
        text: Icons.lock
        color: Colors.foregroundMuted
      }
    }

    StateLayer {
      mouseArea: rowMouse
      radius: row.radius
    }

    MouseArea {
      id: rowMouse

      anchors.fill: parent
      hoverEnabled: Qt.PointingHandCursor
      onClicked: row.clicked()
    }
  }
}
