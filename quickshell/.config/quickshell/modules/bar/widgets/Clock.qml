import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  interactive: true
  onClicked: calendar.visible = !calendar.visible

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  IconLabel {
    icon: Icons.clock
    iconColor: Colors.accent
    text: Qt.formatDateTime(clock.date, Config.barClockFormat)
  }

  CalendarPopup {
    id: calendar

    anchorItem: root
  }
}
