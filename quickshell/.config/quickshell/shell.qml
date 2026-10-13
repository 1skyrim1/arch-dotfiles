//@ pragma StateDir $BASE/myshell
//@ pragma CacheDir $BASE/myshell

import Quickshell
import qs.services
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notifications
import qs.modules.session
import qs.modules.wallpaper

ShellRoot {
  readonly property var startupServices: [
    Audio,
    Launcher,
    Lock,
    Media,
    Notifications,
    Session,
    Theme,
    Updates,
    Wallpaper,
  ]

  Background {}
  Bar {}
  NotificationPopups {}
  SessionMenu {}
  AppLauncher {}
  WallpaperSwitcher {}
  LockScreen {}
}
