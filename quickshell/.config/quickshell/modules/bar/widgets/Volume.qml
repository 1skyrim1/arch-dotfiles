import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.bar.popups

Pill {
  id: root

  interactive: true

  onScrolled: wheel => Audio.changeVolume(Math.sign(wheel.angleDelta.y) * Config.volumeStep)
  onClicked: mouse => {
    if (mouse.button === Qt.LeftButton)
      mixer.visible = !mixer.visible;
    else
      Audio.toggleMute();
    }

    IconLabel {
      icon: Audio.muted ? Icons.volumeMuted : Icons.volume
      text: `${Math.round(Audio.volume * 100)}%`
      // Dimmed while muted
      iconColor: Audio.muted ? Colors.foregroundMuted : Colors.foreground
      textColor: Audio.muted ? Colors.foregroundMuted : Colors.foreground
    }

    AudioPopup {
      id: mixer

      anchorItem: root
    }
}
