import QtQuick
import qs.config

Image {
  property string path

  source: path
  fillMode: Image.PreserveAspectCrop
  asynchronous: true
  sourceSize: Qt.size(Appearance.thumbnailWidth, Appearance.thumbnailHeight)
}
