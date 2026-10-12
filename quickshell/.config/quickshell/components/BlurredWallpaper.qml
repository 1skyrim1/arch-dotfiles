import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

Item {
  id: root

  property real blur: 1
  // How much the background darkens
  property real dim: 0.35

  readonly property int overscan: 64

  clip: true

  Rectangle {
    anchors.fill: parent
    color: Colors.background
  }

  Image {
    id: wallpaper

    anchors {
      fill: parent
      margins: -root.overscan
    }
    source: Wallpaper.current
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    sourceSize.width: root.width / 2
    visible: false
  }

  MultiEffect {
    anchors.fill: wallpaper
    source: wallpaper
    blurEnabled: true
    blur: root.blur
    blurMax: 64
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    opacity: root.dim
  }
}
