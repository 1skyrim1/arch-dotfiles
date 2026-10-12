import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components
import qs.modules.notifications

BarPopup {
  id: root

  implicitWidth: Appearance.notificationCenterWidth

  onVisibleChanged: {
    if (visible)
      Notifications.hidePopups();
  }

  //-- header --

  RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.popupRowPadding

    StyledText {
      Layout.fillWidth: true
      text: "Notifications"
      font.bold: true
      font.pixelSize: Appearance.popupTitleSize
    }

    StyledText {
      text: "Do not disturb"
      color: Colors.foregroundMuted
    }

    StyledToggle {
      checked: Notifications.doNotDisturb
      onToggled: Notifications.doNotDisturb = !Notifications.doNotDisturb
    }
  }

  //-- List --

  ListView {
    id: list

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, Appearance.notificationListMaxHeight)
    visible: count > 0
    clip: true
    spacing: Appearance.popupRowPadding
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel {
      comparisonMode: ObjectComparison.Identity
      values: Array.from(Notifications.entries)
    }

    delegate: NotificationCard {
      required property var modelData

      width: list.width
      notification: modelData?.notification ?? null
      time: modelData?.time ?? new Date()
      maximumBodyLines: Appearance.notificationBodyLines * 2
      onCloseRequested: modelData?.notification.dismiss()
    }

    remove: Transition {
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

  // Shown instead of the list when there's notification
  EmptyState {
    visible: Notifications.count === 0
    icon: Notifications.doNotDisturb ? Icons.bellOff : Icons.bell
    text: "No notifications"
  }

  //-- Footer --

  StyledButton {
    Layout.alignment: Qt.AlignRight
    visible: Notifications.count > 0
    text: "Clear all"
    onClicked: Notifications.dismissAll()
  }
}
