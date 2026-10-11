import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  readonly property string label: {
    switch (Network.kind) {
    case "wired":
      return "Wired";
    case "wifi":
      return Network.connecting ? "Connecting..." : Network.currentNetwork?.name ?? "Wi-Fi";
    default:
      return Network.wifiAvailable && !Network.wifiEnabled ? "Wi-Fi off" : "Offline";
    }
  }

  interactive: true
  onClicked: popup.visible = !popup.visible

  IconLabel {
    icon: Icons.network(Network.kind, Network.signalLevel(Network.currentNetwork))
    text: root.label
    maximumTextWidth: Appearance.pillMaxTextWidth
    iconColor: Network.online ? Colors.foreground : Colors.foregroundMuted
    textColor: Network.online ? Colors.foreground : Colors.foregroundMuted
  }

  NetworkPopup {
    id: popup

    anchorItem: root
  }
}
