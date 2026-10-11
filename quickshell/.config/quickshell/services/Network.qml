pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.config

Singleton {
  id: root

  //-- Wifi --

  readonly property WifiDevice wifiDevice: Networking.devices.values.find(
    device => device.type === DeviceType.Wifi) ?? null
  readonly property bool wifiAvailable: wifiDevice !== null

  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool wifiBlocked: !Networking.wifiHardwareEnabled

  readonly property list<WifiNetwork> networks: Array.from(wifiDevice?.networks.values ?? [])
    .sort((a, b) => b.signalStrength - a.signalStrength)

  readonly property WifiNetwork currentNetwork: Array.from(networks).find(
    network => network.connected || network.stateChanging) ?? null
  readonly property bool connecting: currentNetwork?.state === ConnectionState.Connecting

  readonly property bool scanning: wifiDevice?.scannerEnabled ?? false

  property int channel: 0
  property int frequency: 0
  readonly property string band: frequency >= 5925 ? "6 GHz"
                               : frequency >= 4900 ? "5 GHz"
                               : frequency > 0 ? "2.4 GHz"
                               : ""

  property string lastError: ""

  signal passwordNeeded(WifiNetwork network)

  //-- Active Connection --

  property string primaryInterface: ""
  property string gateway: ""
  readonly property string ipAddress: addresses[primaryInterface] ?? ""
  readonly property bool online: primaryInterface !== ""

  readonly property string kind: online && primaryInterface === wifiDevice?.name ? "wifi"
                               : online ? "wired"
                               : currentNetwork ? "wifi"
                               : "offline"

  //-- Traffic --

  readonly property real downloadRate: rxCounter.bytesPerSecond
  readonly property real uploadRate: txCounter.bytesPerSecond

  property list<real> downloadHistory: []
  property list<real> uploadHistory: []

  //-- Functions --

  function setWifiEnabled(enabled: bool): void {
    Networking.wifiEnabled = enabled;
  }

  function setScanning(enabled: bool): void {
    if (wifiDevice)
      wifiDevice.scannerEnabled = enabled;
  }

  function connect(network: WifiNetwork): void {
    startAttempt(network, false);
    network.connect();
  }

  function connectWithPassword(network: WifiNetwork, password: string): void {
    startAttempt(network, true);
    network.connectWithPsk(password);
  }

  function disconnect(): void {
    currentNetwork?.disconnect();
  }

  // Deletes the saved password, so it stops auto-connecting
  function forget(network: WifiNetwork): void {
    network.forget();
  }

  function openSettings(): void {
    Quickshell.execDetached(Config.networkSettingsCommand);
  }

  function signalLevel(network: WifiNetwork): int {
    return Math.min(4, Math.floor((network?.signalStrength ?? 0) * 5));
  }

  function isSecured(network: WifiNetwork): bool {
    return network !== null
        && network.security !== WifiSecurityType.Open
        && network.security !== WifiSecurityType.Owe;
  }

  function usesPassword(network: WifiNetwork): bool {
    return network !== null
        && (network.security === WifiSecurityType.WpaPsk
          || network.security === WifiSecurityType.Wpa2Psk
          || network.security === WifiSecurityType.Sae);
  }

  function needsSettings(network: WifiNetwork): bool {
    return isSecured(network) && !usesPassword(network);
  }

  //-- Internals --

  property WifiNetwork attemptNetwork: null
  property bool attemptUsedPassword: false
  property var addresses: ({})

  function startAttempt(network: WifiNetwork, withPassword: bool): void {
    lastError = "";
    attemptNetwork = network;
    attemptUsedPassword = withPassword;
  }

  function resetChannel(): void {
    channel = 0;
    frequency = 0;
  }

  function describeFailure(reason: int): string {
    switch (reason) {
    case ConnectionFailReason.WifiNetworkLost:
      return "the network is out of range.";
    case ConnectionFailReason.WifiAuthTimeout:
      return "the network took too long to respond.";
    default:
      return "something went wrong. Try again.";
    }
  }

  function appendSample(history: list<real>, sample: real): list<real> {
    return Array.from(history).concat([sample]).slice(-Config.trafficHistoryLength);
  }

  Connections {
    target: root.attemptNetwork

    function onConnectionFailed(reason: int): void {
      const network = root.attemptNetwork;
      root.attemptNetwork = null;

      if (reason === ConnectionFailReason.NoSecrets) {
        if (root.attemptUsedPassword)
          root.lastError = "Wrong password. Try again.";
        root.passwordNeeded(network);
        return;
      }
      root.lastError = `Couldn't connect to ${network.name}: ${root.describeFailure(reason)}`;
    }

    function onConnectedChanged(): void {
      if (root.attemptNetwork?.connected)
        root.attemptNetwork = null;
    }
  }

  //-- Processes --

  Process {
    id: routeProcess

    command: ["ip", "-j", "route", "show", "default"]
    stdout: StdioCollector {
      onStreamFinished: {
        let routes = [];
        try {
          routes = JSON.parse(text);
        } catch (error) {}
        const best = routes.sort((a, b) => (a.metric ?? 0) - (b.metric ?? 0))[0];
        root.primaryInterface = best?.dev ?? "";
        root.gateway = best?.gateway ?? "";
      }
    }
  }

  Process {
    id: addressProcess

    command: ["ip", "-j", "-4", "addr", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        let interfaces = [];
        try {
          interfaces = JSON.parse(text);
        } catch (error) {}
        const addresses = {};
        for (const entry of interfaces)
          addresses[entry.ifname] = entry.addr_info?.[0]?.local ?? "";
        root.addresses = addresses;
      }
    }
  }

  Process {
    id: channelProcess

    command: ["nmcli", "-g", "IN-USE,CHAN,FREQ", "device", "wifi", "list",
              "--rescan", "no", "ifname", root.wifiDevice?.name ?? ""]
    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.split("\n").find(entry => entry.startsWith("*"));
        const fields = line ? line.split(":") : [];
        root.channel = parseInt(fields[1]) || 0;
        root.frequency = parseInt(fields[2]) || 0;
      }
    }
  }

  //-- Timers --

  // Addresses and channel can't be watched so they're polled
  Timer {
    interval: Config.networkPollInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      routeProcess.running = true;
      addressProcess.running = true;
      if (root.currentNetwork?.connected)
        channelProcess.running = true;
      else
        root.resetChannel();
    }
  }

  Timer {
    interval: Config.trafficSampleInterval
    running: true
    repeat: true
    onTriggered: {
      rxCounter.reload();
      txCounter.reload();
      root.downloadHistory = root.appendSample(root.downloadHistory, root.downloadRate)
      root.uploadHistory = root.appendSample(root.uploadHistory, root.uploadRate)
    }
  }

  //-- Traffic counters --

  // The kernel counts every byte an interface has sent and received since boot.
  // Reading the counter twice and dividing the difference by the
  // time in between gives the current spped
  component ByteCounter: FileView {
    property real bytesPerSecond: 0
    property real lastBytes: -1
    property real lastTime: 0

    printErrors: false

    // Interface has changed -> reset counter
    onPathChanged: {
      lastBytes = -1;
      bytesPerSecond = 0;
    }

    onLoaded: {
      const bytes = parseFloat(text());
      const now = Date.now();
      if (lastBytes >= 0 && now > lastTime && bytes >= lastBytes)
        bytesPerSecond = (bytes - lastBytes) * 1000 / (now - lastTime);
      lastBytes = bytes;
      lastTime = now;
    }
  }

  ByteCounter {
    id: rxCounter

    path: root.online ? `/sys/class/net/${root.primaryInterface}/statistics/rx_bytes` : ""
  }

  ByteCounter {
    id: txCounter

    path: root.online ? `/sys/class/net/${root.primaryInterface}/statistics/tx_bytes` : ""
  }
}
