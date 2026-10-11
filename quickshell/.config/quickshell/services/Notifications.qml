pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as QsNotifications
import qs.config

Singleton {
  id: root

  //-- Public State --

  property list<NotificationEntry> entries: []

  readonly property list<NotificationEntry> popups: Array.from(entries).filter(entry => entry.popup)

  readonly property int count: entries.length

  property bool doNotDisturb: false

  readonly property date now: clock.date

  //-- Functions --

  function dismissAll(): void {
    for (const entry of Array.from(entries))
      entry.notification.dismiss();
  }

  function hidePopups(): void {
    for (const entry of Array.from(entries))
      entry.popup = false;
  }

  //-- Internals --

  function remove(entry: NotificationEntry): void {
    entries = Array.from(entries).filter(other => other !== entry);
    entry.destroy();
  }

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  QsNotifications.NotificationServer {
    keepOnReload: true

    actionsSupported: true
    imageSupported: true
    persistenceSupported: true
    bodyMarkupSupported: false

    onNotification: notification => {
      notification.tracked = true;
      const critical = notification.urgency === QsNotifications.NotificationUrgency.Critical;
      const entry = entryComponent.createObject(root, {
        notification: notification,
        popup: !root.doNotDisturb || critical,
      });
      root.entries = [entry].concat(Array.from(root.entries));
    }
  }

  Component {
    id: entryComponent

    NotificationEntry {}
  }

  component NotificationEntry: QtObject {
    id: entry

    required property QsNotifications.Notification notification
    readonly property date time: new Date()
    readonly property bool critical: notification?.urgency === QsNotifications.NotificationUrgency.Critical

    property bool popup: false
    property bool hovered: false

    readonly property int timeout: (notification?.expireTimeout ?? 0) > 0 ? notification.expireTimeout * 1000
                                 : critical ? 0
                                 : Config.notificationTimeout

    property Timer popupTimer: Timer {
      interval: entry.timeout
      running: entry.popup && !entry.hovered && entry.timeout > 0
      onTriggered: {
        if (entry.notification.transient)
          entry.notification.expire();
        else
          entry.popup = false;
      }
    }

    property Connections closeWatcher: Connections {
      target: entry.notification

      function onClosed(): void {
        root.remove(entry);
      }
    }
  }

  // Hyprland Keybinds
  IpcHandler {
    target: "notifications"

    function toggleDoNotDisturb(): void {
      root.doNotDisturb = !root.doNotDisturb;
    }

    function dismissAll(): void {
      root.dismissAll();
    }
  }
}
