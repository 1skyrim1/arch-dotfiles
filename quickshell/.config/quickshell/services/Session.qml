pragma Singleton

import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  property bool menuVisible: false

  function openMenu(): void {
    menuVisible = true;
  }

  function closeMenu(): void {
    menuVisible = false;
  }

  function toggleMenu(): void {
    menuVisible = !menuVisible;
  }

  function run(action: string): void {
    const commands = {
      shutdown: Config.shutdownCommand,
      reboot: Config.rebootCommand,
      logout: Config.logoutCommand,
      suspend: Config.suspendCommand,
      lock: Config.lockCommand,
    };
    const command = commands[action];
    if (!command) {
      console.warn(`Session: unknown action "${action}"`);
      return;
    }
    menuVisible = false;
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
