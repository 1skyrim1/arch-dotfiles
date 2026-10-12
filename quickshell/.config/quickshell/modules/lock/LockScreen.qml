import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

Scope {
  WlSessionLock {
    id: sessionLock

    locked: Lock.locked

    LockSurface {}
  }

  Binding {
    target: Lock
    property: "secure"
    value: sessionLock.secure
  }
}
