pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  //-- Public State --

  readonly property bool available: device !== ""

  property real brightness: 0

  //-- Functions --

  function set(value: real): void {
    if (!available)
      return;

    brightness = Math.max(Config.brightnessMinimum, Math.min(1, value));
    writer.exec(["brightnessctl", "--quiet", "--device", device, "set", String(Math.round(brightness * maximum))]);
  }

  function increase(): void {
    set(brightness + Config.brightnessStep);
  }

  function decrease(): void {
    set(brightness - Config.brightnessStep);
  }

  function refresh(): void {
    reader.running = true;
  }

  //-- Internals --

  property string device: ""
  property int maximum: 0

  Process {
    id: reader

    running: true
    command: ["brightnessctl", "-m", "-c", "backlight", "info"]

    stdout: StdioCollector {
      id: readerOutput
    }

    onExited: exitCode => {
      if (exitCode !== 0)
        return;
      const [name, , current, , highest] = readerOutput.text.trim().split(",");
      const maximum = parseInt(highest);
      if (!(maximum > 0))
        return;
      root.maximum = maximum;
      root.brightness = parseInt(current);
      root.device = name;
    }
  }

  Process {
    id: writer
  }

  IpcHandler {
    target: "brightness"

    function increase(): void {
      root.increase();
      Osd.show("brightness");
    }

    function decrease(): void {
      root.decrease();
      Osd.show("brightness");
    }

    function set(percent: int): void {
      root.set(percent / 100);
      Osd.show("brightness");
    }
  }
}
