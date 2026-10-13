pragma Singleton

import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  readonly property bool menuVisible: Overlays.current === "session"

  function openMenu(): void {
    Overlays.open("session");
  }

  function closeMenu(): void {
    if (menuVisible)
      Overlays.close();
  }

  function toggleMenu(): void {
    Overlays.toggle("session");
  }

  function run(action: string): void {
    if (action === "lock") {
      closeMenu();
      Lock.lock();
      return;
    }
    const commands = {
      shutdown: Config.shutdownCommand,
      reboot: Config.rebootCommand,
      logout: Config.logoutCommand,
      suspend: Config.suspendCommand,
    };
    const command = commands[action];
    if (!command) {
      console.warn(`Session: unknown action "${action}"`);
      return;
    }
    closeMenu();
    Quickshell.execDetached(command);
  }

  IpcHandler {
    target: "session"

    function toggle(): void {
      root.toggleMenu();
    }

    function open(): void {
      root.openMenu();
    }

    function close(): void {
      root.closeMenu();
    }

    function run(action: string): void {
      root.run(action);
    }
  }
}
