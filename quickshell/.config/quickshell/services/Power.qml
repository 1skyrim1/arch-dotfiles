pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config

Singleton {
  id: root

  //-- Battery --

  readonly property UPowerDevice device: UPower.displayDevice

  readonly property UPowerDevice physicalBattery: UPower.devices.values.find(
    candidate => candidate.isLaptopBattery) ?? null

  readonly property bool hasBattery: physicalBattery !== null

  readonly property real charge: device.percentage
  readonly property int deviceState: device.state
  readonly property bool charging: deviceState === UPowerDeviceState.Charging
                                   || deviceState === UPowerDeviceState.PendingCharge
  readonly property bool fullyCharged: deviceState === UPowerDeviceState.FullyCharged

  readonly property bool runningOnBattery: UPower.onBattery

  readonly property bool low: runningOnBattery && charge <= Config.batteryLowThreshold
  readonly property bool critical: runningOnBattery && charge <= Config.batteryCriticalThreshold

  readonly property real timeToEmpty: device.timeToEmpty
  readonly property real timeToFull: device.timeToFull

  readonly property real power: Math.abs(device.changeRate)
  readonly property real energy: device.energy
  readonly property real energyCapacity: device.energyCapacity

  readonly property real health: {
    if (!(physicalBattery?.healthSupported ?? false))
      return -1;
    const value = physicalBattery.healthPercentage;
    return value > 1 ? value / 100 : value;
  }

  //-- Power Mode --

  readonly property int profile: PowerProfiles.profile

  readonly property list<int> profiles: PowerProfiles.hasPerformanceProfile
    ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    : [PowerProfile.PowerSaver, PowerProfile.Balanced]

  readonly property string degradation: {
    switch (PowerProfiles.degradationReason) {
    case PerformanceDegradationReason.Hightemperature:
      return "Performance reduced: the laptio is too hot";
    case PerformanceDegradationReason.LapDetected:
      return "Performance reduced: the laptop is on your Lap";
    default:
      return "";
    }
  }

  function setProfile(newProfile: int): void {
    PowerProfiles.profile = newProfile;
  }

  function cycleProfile(step: int): void {
    const count = profiles.length;
    const current = Array.from(profiles).indexOf(profile);
    setProfile(profiles[(current + step + count) % count]);
  }
}
