//@ pragma StateDir $BASE/myshell
//@ pragma CacheDir $BASE/myshell

import Quickshell
import qs.services
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit
import qs.modules.screenshot
import qs.modules.session
import qs.modules.wallpaper

ShellRoot {
  readonly property var startupServices: [
    Audio,
    Brightness,
    Idle,
    Launcher,
    Lock,
    Media,
    Notifications,
    Osd,
    Polkit,
    Screenshot,
    Session,
    Theme,
    Updates,
    Wallpaper,
  ]

  Background {}
  Bar {}
  NotificationPopups {}
  SessionMenu {}
  ScreenshotSelector {}
  AppLauncher {}
  WallpaperSwitcher {}
  LockScreen {}
  OnScreenDisplay {}
  PolkitDialog {}
}
