import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  property real now: Date.now()

  readonly property int minutesLeft: Idle.stayingAwake && Idle.stayAwakeUntil > 0
    ? Math.max(1, Math.ceil((Idle.stayAwakeUntil - now) / 60000))
    : 0

  function formatMinutes(minutes: int): string {
    if (minutes < 60)
      return `${minutes} min`;
    const rest = minutes % 60;
    return rest > 0 ? `${Math.floor(minutes / 60)} h ${rest}` : `${minutes / 60} h`;
  }

  interactive: true
  onClicked: mouse => {
    if (mouse.button === Qt.RightButton)
      popup.visible = !popup.visible;
    else
      Idle.toggleStayAwake();
  }

  Timer {
    running: Idle.stayingAwake && Idle.stayAwakeUntil > 0
    interval: 10 * 1000
    repeat: true
    onTriggered: root.now = Date.now()
  }

  Connections {
    target: Idle

    function onStayAwakeUntilChanged(): void {
      root.now = Date.now();
    }
  }

  StyledText {
    text: Idle.stayingAwake ? Icons.stayAwakeOn : Icons.stayAwakeOff
    color: Idle.stayingAwake ? Colors.accent : Colors.foregroundMuted
    font.pixelSize: Appearance.iconSize
  }

  StyledText {
    visible: root.minutesLeft > 0
    text: root.formatMinutes(root.minutesLeft)
  }

  StayAwakePopup {
    id: popup

    anchorItem: root
  }
}
