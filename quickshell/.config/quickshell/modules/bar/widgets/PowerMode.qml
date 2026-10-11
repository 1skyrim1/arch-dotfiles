import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

Pill {
  id: root

  readonly property string icon: {
    switch (Power.profile) {
    case PowerProfile.PowerSaver:
      return Icons.powerSaver;
    case PowerProfile.Performance:
      return Icons.powerPerformance;
    default:
      return Icons.powerBalanced;
    }
  }

  readonly property color iconColor: {
    switch (Power.profile) {
    case PowerProfile.PowerSaver:
      return Colors.accent;
    case PowerProfile.Performance:
      return Colors.warning;
    default:
      return Colors.foreground;
    }
  }

  interactive: true
  onClicked: mouse => Power.cycleProfile(mouse.button === Qt.RightButton ? -1 : 1)

  StyledText {
    text: root.icon
    color: root.iconColor
    font.pixelSize: Appearance.iconSize
  }
}
