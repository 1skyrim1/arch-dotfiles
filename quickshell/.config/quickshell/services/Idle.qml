pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs.config

Singleton {
  id: root

  //-- Public state --

  readonly property bool mediaPlaying: Mpris.players.values.some(player => player.isPlaying)

  property bool screensOff: false

  property bool stayingAwake: false

  property real stayAwakeUntil: 0

  //-- Functions --

  function stayAwake(minutes: int): void {
    stayAwakeUntil = minutes > 0 ? Date.now() + minutes * 60 * 1000 : 0;
    stayingAwake = true;
  }

  function stopStayingAwake(): void {
    stayingAwake = false;
    stayAwakeUntil = 0;
  }

  function toggleStayAwake(): void {
    if (stayingAwake)
      stopStayingAwake();
    else
      stayAwake(0);
  }

  //-- Internals --

  function setScreens(on: bool): void {
    if (screensOff === !on)
      return;
    screensOff = !on;
    Hyprland.dispatch(`hl.dsp.dpms({ action = '${on ? "on" : "off"}' })`);
  }

  Timer {
    running: root.stayingAwake && root.stayAwakeUntil > 0
    interval: 15 * 1000
    repeat: true
    onTriggered: {
      if (Date.now() >= root.stayAwakeUntil)
        root.stopStayingAwake();
    }
  }

  // 1. Lock
  IdleMonitor {
    enabled: Config.lockAfterIdle > 0 && !Lock.locked && !root.stayingAwake
    timeout: Config.lockAfterIdle

    onIsIdleChanged: {
      if (isIdle)
        Lock.lock();
    }
  }

  // 2. Screen off
  IdleMonitor {
    enabled: Config.screenOffAfterLock > 0 && Lock.locked && !root.stayingAwake
    timeout: Config.screenOffAfterLock

    onIsIdleChanged: root.setScreens(!isIdle)
  }

  // 3. Sleep
  IdleMonitor {
    readonly property int seconds: Power.runningOnBattery ? Config.suspendAfterIdleOnBattery : Config.suspendAfterIdlePluggedIn

    enabled: seconds > 0 && !root.mediaPlaying && !root.stayingAwake
    timeout: seconds

    onIsIdleChanged: {
      if (isIdle)
        Session.run("suspend");
    }
  }

  IpcHandler {
    target: "idle"

    function toggleStayAwake(): void {
      root.toggleStayAwake();
    }

    function stayAwake(minutes: int): void {
      root.stayAwake(minutes);
    }

    function stopStayingAwake(): void {
      root.stopStayingAwake();
    }
  }
}
