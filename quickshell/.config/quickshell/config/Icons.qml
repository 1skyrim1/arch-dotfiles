pragma Singleton

import Quickshell

Singleton {
  readonly property string distroLogo: "\uf303"       // Arch Logo
  readonly property string clock: "\uf017"
  readonly property string play: "\uf144"
  readonly property string pause: "\uf28b"
  readonly property string bell: "\uf0f3"
  readonly property string updates: "\uf0ed"          // cloud with download arrow
  readonly property string volume: "\uf025"           // headphones
  readonly property string volumeMuted: "\uf026"

  readonly property string search: "\uf002"           // magnifying glass

  readonly property string powerSaver: "\uf06c"       // leaf
  readonly property string powerBalanced: "\uf24e"    // balance scale
  readonly property string powerPerformance: "\uf0e7" // bolt

  readonly property string batteryCharging: "\uf1e6"  // plug
  // Ordered empty -> full
  readonly property list<string> batteryLevels: ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]

  readonly property string wifiOff: "\u{f092e}"
  readonly property list<string> wifiLevels: ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]
  readonly property string ethernet: "\u{f0200}"
  readonly property string arrowDown: "\u{f0045}"
  readonly property string arrowUp: "\u{f005d}"
  readonly property string settings: "\u{f0493}"
  readonly property string lock: "\uf023"

  readonly property string bellOff: "\uf1f6"
  readonly property string close: "\uf00d"

  readonly property string calculator: "\uf1ec"
  readonly property string emoji: "\uf118"

  readonly property string image: "\uf03e"

  //-- Media --
  readonly property string music: "\uf001"
  readonly property string previous: "\uf048"
  readonly property string next: "\uf051"
  readonly property string playControl: "\uf04b"
  readonly property string pauseControl: "\uf04c"
  readonly property string shuffle: "\uf074"
  readonly property string repeat: "\u{f0456}"
  readonly property string repeatOne: "\u{f048}"
  readonly property string repeatOff: "\u{f0457}"

  //-- Session Menu --
  readonly property string shutdown: "\uf011"
  readonly property string reboot: "\uf0e2"
  readonly property string logout: "\uf08b"
  readonly property string sleep: "\uf186"

  function network(kind: string, level: int): string {
    if (kind === "wired")
      return ethernet;
    if (kind === "wifi")
      return wifiLevels[Math.max(0, Math.min(4, level))];
    return wifiOff;
  }
}
