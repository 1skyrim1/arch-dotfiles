pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs.config

Singleton {
  id: root

  //-- Public state --

  readonly property bool mediaPlaying: Mpris.players.values.some(player => player.isPlaying)

  property bool screensOff: false

  //-- Internals --

  function setScreens(on: bool): void {
    if (screensOff === !on)
      return;
    screensOff = !on;
    Hyprland.dispatch(`hl.dsp.dpms({ action = '${on ? "on" : "off"}' })`);
  }

  // 1. Lock
  IdleMonitor {
    enabled: Config.lockAfterIdle > 0 && !Lock.locked
    timeout: Config.lockAfterIdle

    onIsIdleChanged: {
      if (isIdle)
        Lock.lock();
    }
  }

  // 2. Screen off
  IdleMonitor {
    enabled: Config.screenOffAfterLock > 0 && Lock.locked
    timeout: Config.screenOffAfterLock

    onIsIdleChanged: root.setScreens(!isIdle)
  }

  // 3. Sleep
  IdleMonitor {
    readonly property int seconds: Power.onBattery ? Config.suspendAfterIdleOnBattery : Config.suspendAfterIdlePluggedIn

    enabled: seconds > 0 && !root.mediaPlaying
    timeout: seconds

    onIsIdleChanged: {
      if (isIdle)
        Session.run("suspend");
    }
  }
}
