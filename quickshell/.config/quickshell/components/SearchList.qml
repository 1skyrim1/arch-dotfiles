import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

ColumnLayout {
  id: root

  property alias query: field.text
  property alias placeholderText: field.placeholderText

  property var results: []

  property alias delegate: list.delegate
  property alias currentIndex: list.currentIndex

  property int rowHeight: Appearance.searchRowHeight
  property int visibleRows: Appearance.searchVisibleRows

  property string emptyIcon
  property string emptyText: "No results"

  signal picked(var item)
  signal cancelled()

  function focusInput(): void {
    field.focusInput();
  }

  function reset(): void {
    field.text = "";
    selectFirst();
  }

  function selectFirst(): void {
    list.currentIndex = 0;
    list.positionViewAtBeginning();
  }

  function move(step: int): void {
    if (list.count === 0)
      return;
    list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + step));
  }

  function pick(index: int): void {
    if (index >= 0 && index < results.length)
      picked(results[index]);
  }

  spacing: Appearance.popupSpacing

  onResultsChanged: Qt.callLater(selectFirst)

  Keys.onPressed: event => {
    switch(event.key) {
    case Qt.Key_Up:
      move(-1);
      break;
    case Qt.Key_Down:
      move(1);
      break;
    case Qt.Key_PageUp:
      move(-visibleRows);
      break;
    case Qt.Key_PageDown:
      move(visibleRows);
      break;
    default:
      return;
    }
    event.accepted = true;
  }

  StyledTextField {
    id: field

    Layout.fillWidth: true
    onAccepted: root.pick(list.currentIndex)
    onCancelled: root.cancelled()
  }

  ListView {
    id: list

    readonly property int rowHeight: root.rowHeight
    signal rowClicked(int index)
    property point lastMousePosition

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(root.results.length, root.visibleRows) * root.rowHeight
    visible: root.results.length > 0
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel {
      values: root.results
      comparisonMode: ObjectComparison.Identity
    }

    highlight: Rectangle {
      radius: Appearance.popupRowRadius
      color: Colors.surfaceRaised
    }
    highlightMoveDuration: Appearance.animationDuration
    highlightMoveVelocity: -1

    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
    onRowClicked: index => root.pick(index)
  }

  EmptyState {
    visible: root.results.length === 0 && root.query !== ""
    icon: root.emptyIcon
    text: root.emptyText
  }
}
