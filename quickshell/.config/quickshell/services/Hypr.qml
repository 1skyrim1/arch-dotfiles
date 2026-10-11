pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
  function focusWorkspace(workspace: string): void {
    if (Hyprland.usingLua)
      Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspace}" })`);
    else
      Hyprland.dispatch(`workspace ${workspace}`)
  }
}
