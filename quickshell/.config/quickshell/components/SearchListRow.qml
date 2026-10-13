import QtQuick
import qs.config

Item {
  id: root

  required property int index

  default property alias content: contentArea.data

  readonly property bool selected: ListView.isCurrentItem

  width: ListView.view.width
  height: ListView.view.rowHeight

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onPositionChanged: mouse => {
      const view = root.ListView.view;
      const position = mapToGlobal(mouse.x, mouse.y);
      if (position.x === view.lastMousePosition.x && position.y === view.lastMousePosition.y)
        return;
      view.lastMousePosition = position;
      view.currentIndex = root.index;
    }

    onClicked: root.ListView.view.rowClicked(root.index)
  }

  Item {
    id: contentArea

    anchors {
      fill: parent
      leftMargin: Appearance.popupRowPadding
      rightMargin: Appearance.popupRowPadding
    }
  }
}
