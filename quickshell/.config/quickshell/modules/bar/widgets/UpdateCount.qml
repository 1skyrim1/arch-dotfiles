import QtQuick
import qs.config
import qs.services
import qs.components

Pill {
  visible: Updates.count >= 0

  interactive: true
  onClicked: Updates.update()

  IconLabel {
    icon: Icons.updates
    text: Updates.count.toString()
    iconColor: Colors.warning
    textColor: Colors.warning
  }
}
