pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth as QsBluetooth

Singleton {
  id: root

  //-- Public state --

  readonly property var adapter: QsBluetooth.Bluetooth.defaultAdapter

  readonly property bool available: adapter !== null
  readonly property bool enabled: adapter?.enabled ?? false
  readonly property bool blocked: adapter?.state === QsBluetooth.BluetoothAdapterState.Blocked
  readonly property bool scanning: adapter?.discovering ?? false

  readonly property var devices: adapter ? Array.from(adapter.devices.values) : []

  readonly property var pairedDevices: devices
    .filter(device => device.paired)
    .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

  readonly property var nearbyDevices: devices
    .filter(device => !device.paired && device.deviceName !== "")
    .sort((a, b) => a.name.localeCompare(b.name))

  readonly property var connectedDevices: pairedDevices.filter(device => device.connected)

  property string lastError: ""

  //-- Functions --

  function setEnabled(on: bool): void {
    if (adapter)
      adapter.enabled = on;
  }

  function setScanning(on: bool): void {
    if (adapter && enabled && adapter.discovering !== on)
    adapter.discovering = on;
  }

  function activate(device: var): void {
    lastError = "";
    if (device.connected) {
      device.disconnect();
    } else if (device.paired) {
      device.connect();
    } else if (!device.pairing) {
      pairingDevice = device;
      device.pair();
    }
  }

  function forget(device: var): void {
    lastError = "";
    device.forget();
  }

  function describe(device: var): string {
    if (device.pairing)
      return "Pairing...";
    switch (device.state) {
    case QsBluetooth.BluetoothDeviceState.Connecting:
      return "Connecting...";
    case QsBluetooth.BluetoothDeviceState.Disconnecting:
      return "Disconnecting...";
    case QsBluetooth.BluetoothDeviceState.Connected:
      return device.pbatteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
    default:
      return device.paired ? "Not connected" : "";
    }
  }

  function isBusy(device: var): bool {
    return device.pairing
      || device.state === QsBluetooth.BluetoothDeviceState.Connecting
      || device.state === QsBluetooth.BluetoothDeviceState.Disconnecting;
  }

  //-- Internals --

  property var pairingDevice: null

  Connections {
    target: root.pairingDevice

    function onPairedChanged(): void {
      const device = root.pairingDevice;
      if (!device.paired)
        return;
      root.pairingDevice = null;
      pairingCheck.stop();
      device.trusted = true;
      device.connect();
    }

    function onPairingChanged(): void {
      if (!root.pairingDevice.pairing)
        pairingCheck.restart();
    }
  }

  Timer {
    id: pairingCheck

    interval: 1000
    onTriggered: {
      const device = root.pairingDevice;
      if (!device || device.paired || device.pairing)
        return;
      root.pairingDevice = null;
      root.lastError = `Couldn't pair with ${device.name}. Is it in pairing mode?`;
    }
  }

  Process {
    id: pairingAgent

    running: true
    command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
    stdinEnabled: true

    stdout: SplitParser {
      onRead: line => {
        if (line.includes("Agent registered"))
          pairingAgent.write("default-agent\n");
      }
    }

    onExited: agentRestart.start()
  }

  Timer {
    id: agentRestart

    interval: 5000
    onTriggered: pairingAgent.running = true
  }

  IpcHandler {
    target: "bluetooth"

    function status(): string {
      if (!root.adapter)
        return "No adapter (is bluetooth.service running?)";
      const header = `Adapter ${root.adapter.name}: ${root.enabled ? "on" : "off"}${root.blocked ? ", blocked" : ""}, `
        + `${root.devices.length} devices (${root.pairedDevices.length} paired, ${root.nearbyDevices.length} nearby)`;
      const lines = root.devices.map(device => [
        device.name || "(no name)",
        device.paired ? "paired" : "-",
        device.connected ? "connected" : "-",
        device.address,
      ].join("  "));
      return [header, ...lines].join("\n");
    }
  }
}
