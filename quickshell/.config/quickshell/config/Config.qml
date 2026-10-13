pragma Singleton

// Behaviour Settings: which programs to launh, how often to poll, formats.
// Commands are argument lists, not shell strings: no shell is involved
// so spaces or quotes in arguments can never break them
import Quickshell

Singleton {
  id: root

  readonly property list<string> terminal: ["kitty"]

  readonly property list<string> networkSettingsCommand: inTerminal(["nmtui"])
  readonly property list<string> updateCommand: inTerminal(["sh", "-c", "sudo pacman -Syu; qs ipc call updates check"])

  // Material You schemes in a dark and a light variant; this one is passed to matugen
  readonly property string colorMode: "dark"

  readonly property string clockFormat: "h:mm AP"
  readonly property int workspaceCount: 5
  readonly property real volumeStep: 0.05

  readonly property int updateCheckInterval: 30 * 60 * 1000 // 30 minutes
  readonly property int networkPollInterval: 5 * 1000       // 5 seconds

  readonly property int trafficSampleInterval: 1000
  readonly property int trafficHistoryLength: 60

  readonly property string wallpaperDir: `${Quickshell.env("HOME")}/Pictures/wallpapers`

  readonly property real batteryLowThreshold: 0.2
  readonly property real batteryCriticalThreshold: 0.1

  readonly property int notificationTimeout: 5000

  //-- Session Menu --
  readonly property list<string> shutdownCommand: ["systemctl", "poweroff"]
  readonly property list<string> rebootCommand: ["systemctl", "reboot"]
  readonly property list<string> suspendCommand: ["systemctl", "suspend"]
  readonly property list<string> logoutCommand: ["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""]
  readonly property list<string> lockCommand: ["loginctl", "lock-session"]

  //-- Lock screen --
  readonly property int lockAfterIdle: -1
  readonly property string lockClockFormat: "HH:mm"
  readonly property string lockDateFormat: "dddd, MMMM d"

  //-- Login screen (greeter) --
  readonly property bool greeterMode: Quickshell.env("MYSHELL_GREETER") === "1"
  readonly property string sharedDir: "/var/lib/myshell"
  readonly property string avatarDir: "/var/lib/AccountsService/icons"
  readonly property int greeterMinUid: 1000
  readonly property list<string> greeterSessionCommand: ["systemd-cat", "-t", "hyprland", "start-hyprland"]

  // Returns the terminal command followed by `args`, so the command opens in a new terminal window.
  function inTerminal(args: list<string>): list<string> {
    return Array.from(root.terminal).concat(Array.from(args));
  }
}
