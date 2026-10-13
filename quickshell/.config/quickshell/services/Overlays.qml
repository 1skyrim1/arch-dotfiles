pragma Singleton

import Quickshell

Singleton {
  id: root

  property string current: ""

  property ShellScreen screen: null

  function open(name: string): void {
    screen = Hypr.focusedScreen;
    current = name;
  }

  function close(): void {
    current = "";
  }

  function toggle(name: string): void {
    if (current === name)
      close();
    else
      open(name);
  }
}
