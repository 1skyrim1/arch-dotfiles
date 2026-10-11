import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
  PanelWindow {
    id: window

    screen: Array.from(Quickshell.screens).find(
      candidate => Hyprland.monitorFor(candidate) === Hyprland.focusedMonitor)
      ?? Quickshell.screens[0]

    anchors {
      top: true
      right: true
    }
    margins {
      top: Appearance.notificationGap
      right: Appearance.notificationGap
    }

    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "myshell-notifications"

    implicitWidth: Appearance.notificationWidth
    implicitHeight: Math.max(1, list.contentHeight)
    visible: Notifications.popups.length > 0
    color: "transparent"

    ListView {
      id: list

      anchors.fill: parent
      spacing: Appearance.notificationGap
      interactive: false

      model: ScriptModel {
        comparisonMode: ObjectComparison.Identity
        values: Array.from(Notifications.popups)
      }

      delegate: NotificationCard {
        id: card

        required property var modelData

        width: list.width
        notification: modelData?.notification ?? null
        time: modelData?.time ?? new Date()
        color: Colors.popupBackground
        onCloseRequested: if (modelData) modelData.popup = false

        Binding {
          target: card.modelData
          property: "hovered"
          value: card.hovered
        }
      }

      add: Transition {
        NumberAnimation {
          property: "x"
          from: Appearance.notificationWidth
          to: 0
          duration: Appearance.animationDuration * 1.5
          easing.type: Easing.OutCubic
        }
      }

      remove: Transition {
        NumberAnimation {
          property: "x"
          to: Appearance.notificationWidth
          duration: Appearance.animationDuration
          easing.type: Easing.InCubic
        }
        NumberAnimation {
          property: "opacity"
          to: 0
          duration: Appearance.animationDuration
        }
      }

      displaced: Transition {
        NumberAnimation {
          property: "y"
          duration: Appearance.animationDuration
          easing.type: Easing.OutCubic
        }
      }
    }
  }
}
