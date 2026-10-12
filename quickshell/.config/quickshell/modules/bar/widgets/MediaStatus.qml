import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  readonly property string label: {
    if (!Media.active || Media.title === "")
      return "—";
    return Media.artist !== "" ? `${Media.artist} – ${Media.title}` : Media.title;
  }

  interactive: true
  onClicked: mouse => {
    if (mouse.button === Qt.RightButton)
      Media.togglePlaying();
    else
      popup.visible = !popup.visible
    }

    IconLabel {
      icon: Media.playing ? Icons.pause : Icons.play
      iconColor: Media.active ? Colors.accent : Colors.foregroundMuted
      text: root.label
      textColor: Media.active ? Colors.foreground : Colors.foregroundMuted
      maximumTextWidth: Appearance.mediaMaxTextWidth
    }

    MediaPopup {
      id: popup

      anchorItem: root
    }
}
