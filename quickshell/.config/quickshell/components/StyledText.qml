import QtQuick
import qs.config
import qs.services

Text {
  color: Colors.foreground
  font.family: Appearance.fontFamily
  font.pixelSize: Appearance.fontSize
  verticalAlignment: Text.AlignVCenter

  Behavior on color {
    ColorAnimation { duration: Appearance.animationDuration }
  }
}
