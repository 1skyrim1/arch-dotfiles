import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  readonly property string icon: {
    if (Power.charging || Power.fullyCharged)
      return Icons.batteryCharging;
    const levels = Icons.batteryLevels;
    return levels[Math.round(Power.charge * (levels.length - 1))];
  }

  readonly property color iconColor: Power.low ? Colors.critical
                                   : Power.charging ? Colors.accent
                                   : Colors.foreground

  visible: Power.hasBattery
  interactive: true
  onClicked: popup.visible = !popup.visible

  IconLabel {
    icon: root.icon
    text: `${Math.round(Power.charge * 100)}%`
    iconColor: root.iconColor
    textColor: Power.low ? Colors.critical : Colors.foreground
  }

  BatteryPopup {
    id: popup

    anchorItem: root
  }
}
