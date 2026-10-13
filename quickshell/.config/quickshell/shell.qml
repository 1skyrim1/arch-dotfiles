//@ pragma StateDir $BASE/myshell

import Quickshell
import qs.services
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notifications
import qs.modules.session

ShellRoot {
  readonly property var ipcServices: [
    Audio,
    Launcher,
    Lock,
    Media,
    Notifications,
    Session,
    Updates,
    Wallpaper,
  ]

  Background {}
  Bar {}
  NotificationPopups {}
  SessionMenu {}
  AppLauncher {}
  LockScreen {}
}
