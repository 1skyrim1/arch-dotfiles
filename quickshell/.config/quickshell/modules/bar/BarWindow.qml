import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.modules.bar.widgets


PanelWindow {
  id: root

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Appearance.barHeight
  color: "transparent"

  WlrLayershell.namespace: "myshell-bar"

  Item {
    anchors {
      fill: parent
      leftMargin: Appearance.barSideMargin
      rightMargin: Appearance.barSideMargin
    }

    RowLayout {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: Appearance.sectionSpacing

      // Logo {}
      Clock {}
      // Media {}
    }

    RowLayout {
      anchors.centerIn: parent
      spacing: Appearance.sectionSpacing

      NotificationBell {}
      Workspaces { monitor: Hyprland.monitorFor(root.screen) }
      PowerMode {}
    }

    RowLayout {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Appearance.sectionSpacing

      UpdateCount {}
      Volume {}
      NetworkStatus {}
      BatteryStatus {}
    }
  }
}
