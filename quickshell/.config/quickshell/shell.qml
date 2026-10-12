//@ pragma StateDir $BASE/myshell

import Quickshell
import qs.modules.background
import qs.modules.bar
import qs.modules.lock
import qs.modules.notifications
import qs.modules.session

ShellRoot {
  Background {}
  Bar {}
  NotificationPopups {}
  SessionMenu {}
  LockScreen {}
//Launcher {}
//ThemeSwitcher {}
}
