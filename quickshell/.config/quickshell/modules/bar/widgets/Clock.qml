import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Pill {
  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  IconLabel {
    icon: Icons.clock
    iconColor: Colors.accent
    text: Qt.formatDateTime(clock.date, Config.clockFormat)
  }
}
