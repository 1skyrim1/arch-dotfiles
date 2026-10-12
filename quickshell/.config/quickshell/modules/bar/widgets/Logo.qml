import QtQuick
import qs.config
import qs.services
import qs.components

Pill {
  interactive: true
  onClicked: Session.toggleMenu()

  StyledText {
    text: Icons.distroLogo
    color: Colors.accent
    font.pixelSize: Appearance.iconSize + 2
  }
}
