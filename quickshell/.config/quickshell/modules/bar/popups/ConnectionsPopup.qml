import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  // 0 = Wi-Fi, 1 = Bluetooth
  property int tab: 0

  readonly property bool wifiTab: tab === 0

  implicitWidth: Appearance.networkPopupWidth

  //-- Header: tabs and the on/off switch --

  RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.popupRowPadding

    SegmentedToggle {
      options: ["Wi-Fi", "Bluetooth"]
      currentIndex: root.tab
      onSelected: index => root.tab = index
    }

    Item {
      Layout.fillWidth: true
    }

    StyledToggle {
      visible: root.wifiTab ? Network.wifiAvailable : Bluetooth.available
      enabled: root.wifiTab ? !Network.wifiBlocked : !Bluetooth.blocked
      checked: root.wifiTab ? Network.wifiEnabled && !Network.wifiBlocked : Bluetooth.enabled
      onToggled: {
        if (root.wifiTab)
          Network.setWifiEnabled(!Network.wifiEnabled);
        else
          Bluetooth.setEnabled(!Bluetooth.enabled);
      }
    }
  }

  //-- The tabs --

  WifiPage {
    Layout.fillWidth: true
    visible: root.wifiTab
    active: root.visible && root.wifiTab
    onCloseRequested: root.visible = false
  }

  BluetoothPage {
    Layout.fillWidth: true
    visible: !root.wifiTab
    active: root.visible && !root.wifiTab
  }
}
