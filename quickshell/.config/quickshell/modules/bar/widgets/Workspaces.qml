import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

Pill {
  id: root

  required property HyprlandMonitor monitor

  readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

  readonly property var workspacesById: {
    const byId = {};
    for (const workspace of Hyprland.workspaces.values) {
      if (workspace.id > 0)
        byId[workspace.id] = workspace;
      }
      return byId;
  }

  readonly property list<int> shownIds: {
    const ids = new Set();
    for (let id = 1; id <= Config.workspaceCount; id++)
      ids.add(id);
    for (const id of Object.keys(workspacesById))
      ids.add(Number(id));
    return Array.from(ids).sort((a, b) => a - b);
  }

  property real scrollAccumulator: 0

  function switchBy(step: int): void {
    const ids = Array.from(shownIds);
    const current = ids.indexOf(activeId);
    const target = Math.max(0, Math.min(ids.length - 1, current + step));
    if (target !== current)
      Hypr.focusWorkspace(String(ids[target]));
  }

  horizontalPadding: Appearance.workspacePadding
  spacing: Appearance.workspaceSpacing

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    onWheel: event => {
      root.scrollAccumulator += event.angleDelta.y;
      if (Math.abs(root.scrollAccumulator) < 120)
        return;
      root.switchBy(root.scrollAccumulator > 0 ? -1 : 1);
      root.scrollAccumulator = 0;
    }
  }

  Repeater {
    model: root.shownIds

    delegate: WorkspaceDot {
      required property int modelData

      workspaceId: modelData
      workspace: root.workspacesById[modelData] ?? null
      active: modelData === root.activeId
    }
  }

  //-- One Dot --

  component WorkspaceDot: Rectangle {
    id: dot

    required property int workspaceId
    property HyprlandWorkspace workspace: null
    property bool active: false

    readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
    readonly property bool urgent: workspace?.urgent ?? false

    implicitWidth: active ? Appearance.workspaceActiveWidth : Appearance.workspaceDotSize
    implicitHeight: Appearance.workspaceDotSize
    radius: active ? Appearance.workspaceActiveRadius : height / 2
    color: active ? Colors.accent
         : urgent ? Colors.critical
         : occupied ? Colors.workspaceOccupied
         : Colors.workspaceEmpty

    Behavior on implicitWidth {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.OutCubic
      }
    }
    Behavior on color {
      ColorAnimation { duration: Appearance.animationDuration }
    }

    StyledText {
      anchors.centerIn: parent
      text: dot.workspaceId.toString()
      color: Colors.foregroundOnAccent
      font.bold: true
      opacity: dot.active ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: Appearance.animationDuration }
      }
    }

    StateLayer {
      mouseArea: dotMouse
      radius: dot.radius
    }

    MouseArea {
      id: dotMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Hypr.focusWorkspace(String(dot.workspaceId))
    }
  }
}
