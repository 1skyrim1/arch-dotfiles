pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
  readonly property ShellScreen focusedScreen: Array.from(Quickshell.screens).find(
    screen => Hyprland.monitorFor(screen) === Hyprland.focusedMonitor)
    ?? Quickshell.screens[0]
    ?? null

  function focusWorkspace(workspace: string): void {
    if (Hyprland.usingLua)
      Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspace}" })`);
    else
      Hyprland.dispatch(`workspace ${workspace}`)
  }
}
