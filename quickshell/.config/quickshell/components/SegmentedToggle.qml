// A row of options where exactly one is chosen:
//
//   ( Dark │ Light )
//
// The chosen option is filled with the accent color, and the fill slides
// over when the choice changes.
//
//   SegmentedToggle {
//       options: ["Dark", "Light"]
//       currentIndex: 0
//       onSelected: index => …      // set currentIndex here (or bind it)
//   }

import QtQuick
import qs.config
import qs.services

Rectangle {
  id: root

  property var options: []
  property int currentIndex: 0

  signal selected(int index)

  implicitWidth: row.implicitWidth
  implicitHeight: Appearance.chipHeight
  radius: height / 2
  color: Colors.surfaceRaised

  Rectangle {
    readonly property Item chosen: repeater.count > 0 ? repeater.itemAt(root.currentIndex): null

    x: chosen?.x ?? 0
    width: chosen?.width ?? 0
    height: parent.height
    radius: height / 2
    color: Colors.accent

    Behavior on x {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.OutCubic
      }
    }
    Behavior on width {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  Row {
    id: row

    Repeater {
      id: repeater

      model: root.options

      delegate: Item {
        id: option

        required property string modelData
        required property int index

        readonly property bool chosen: index === root.currentIndex

        implicitWidth: label.implicitWidth + 2 * Appearance.chipPadding
        implicitHeight: root.height

        StyledText {
          id: label

          anchors.centerIn: parent
          text: option.modelData
          color: option.chosen ? Colors.foregroundOnAccent : Colors.foreground
        }

        StateLayer {
          mouseArea: mouseArea
          radius: root.radius
        }

        MouseArea {
          id: mouseArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selected(option.index)
        }
      }
    }
  }
}
