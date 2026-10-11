import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications as QsNotifications
import qs.config
import qs.services
import qs.components

Rectangle {
  id: root

  property QsNotifications.Notification notification: null
  property date time: new Date()
  property int maximumBodyLines: Appearance.notificationBodyLines
  readonly property alias hovered: hover.hovered

  signal closeRequested()

  readonly property bool critical: notification?.urgency === QsNotifications.NotificationUrgency.Critical

  readonly property QsNotifications.NotificationAction defaultAction: Array.from(notification?.actions ?? []).find(
    action => action.identifier === "default") ?? null
  readonly property list<QsNotifications.NotificationAction> buttonActions: Array.from(notification?.actions ?? []).filter(
    action => action.identifier !== "default")

  readonly property string iconSource: {
    if (!notification)
      return "";
    if (notification.image !== "")
      return notification.image;
    const icon = notification.appIcon;
    if (icon.startsWith("/") || icon.includes("://"))
      return icon;
    return icon !== "" ? Quickshell.iconPath(icon, true) : "";
  }

  function relativeTime(): string {
    const minutes = Math.floor((Notifications.now - time) / 60000);
    if (minutes < 1)
      return "now";
    if (minutes < 60)
      return `${minutes} min`;
    if (minutes < 24 * 60)
      return `${Math.floor(minutes / 60)} h`;
    return Qt.formatDate(time, "d MMM");
  }

  implicitHeight: content.implicitHeight + 2 * Appearance.cardPadding
  radius: Appearance.cardRadius
  color: Colors.surfaceRaised

  // HoverHandler (unlike MouseArea) keeps reporting
  // hover while the mouse is over the buttons inside.
  HoverHandler {
    id: hover
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.defaultAction?.invoke()
  }

  Rectangle {
    visible: root.critical
    width: 3
    radius: width / 2
    color: Colors.critical
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
      margins: Appearance.cardPadding / 2
    }
  }

  RowLayout {
    id: content

    anchors {
      fill: parent
      margins: Appearance.cardPadding
    }
    spacing: Appearance.cardPadding

    IconImage {
      Layout.alignment: Qt.AlignTop
      visible: root.iconSource !== ""
      source: root.iconSource
      implicitSize: Appearance.notificationIconSize
      asynchronous: true
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      RowLayout {
        Layout.fillWidth: true

        StyledText {
          Layout.fillWidth: true
          text: `${root.notification?.appName || "Notification"} · ${root.relativeTime()}`
          color: Colors.foregroundMuted
          font.pixelSize: Appearance.fontSizeSmall
          elide: Text.ElideRight
        }

        StyledText {
          text: Icons.close
          color: closeMouse.containsMouse ? Colors.foreground : Colors.foregroundMuted

          MouseArea {
            id: closeMouse

            anchors {
              fill: parent
              margins: -6
            }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()
          }
        }
      }

      StyledText {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.notification?.summary ?? ""
        font.bold: true
        elide: Text.ElideRight
      }

      StyledText {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.notification?.body ?? ""
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: root.maximumBodyLines
        elide: Text.ElideRight
      }

      RowLayout {
        Layout.topMargin: 4
        visible: root.buttonActions.length > 0
        spacing: Appearance.popupRowPadding

        Repeater {
          model: root.buttonActions

          delegate: StyledButton {
            required property QsNotifications.NotificationAction modelData

            text: modelData.text
            onClicked: modelData.invoke()
          }
        }
      }
    }
  }
}
