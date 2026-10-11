import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  interactive: true
  onClicked: center.visible = !center.visible

  StyledText {
    text: Notifications.doNotDisturb ? Icons.bellOff : Icons.bell
    color: Notifications.doNotDisturb ? Colors.foregroundMuted : Colors.foreground
    font.pixelSize: Appearance.iconSize

    Rectangle {
      visible: Notifications.count > 0
      width : Appearance.badgeSize
      height: width
      radius: width / 2
      color: Colors.accent
      anchors {
        top: parent.top
        right: parent.right
        rightMargin: -width / 3
      }
    }
  }

  NotificationCenter {
    id: center

    anchorItem: root
  }
}
