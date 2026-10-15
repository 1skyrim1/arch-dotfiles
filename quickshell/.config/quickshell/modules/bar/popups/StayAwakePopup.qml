// The stay-awake popup (right click on the cup):
//
//   Stay awake                         [on/off]
//   Until 17:45
//   [ 30 min ]  [ 1 h ]  [ 2 h ]
//
// The switch: on until turned off, or off. The buttons: on for that long
// (from now, also when it's already on).

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  readonly property list<int> durations: [30, 60, 120]

  readonly property string status: {
    if (!Idle.stayingAwake)
      return "Off: locks, turns off and sleeps as usual";
    if (Idle.stayingAwakeUntil > 0)
      return "On until turned off";
    return `On until ${Qt.formatDateTime(new Date(), Config.barClockFormat)}`;
  }

  //-- Header: title and switch --

  RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.popupRowPadding

    StyledText {
      Layout.fillWidth: true
      text: "Stay awake"
      font.bold: true
      font.pixelSize: Appearance.popupTitleSize
    }

    StyledToggle {
      checked: Idle.stayingAwake
      onToggled: Idle.toggleStayAwake()
    }
  }

  StyledText {
    Layout.fillWidth: true
    text: root.status
    color: Colors.foregroundMuted
    wrapMode: Text.WordWrap
  }

  //-- Durations --

  RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.popupRowPadding

    Repeater {
      model: root.durations

      delegate: StyledButton {
        required property int modelData

        Layout.fillWidth: true
        text: modelData < 60 ? `${modelData} min` : `${modelData / 60} h`
        onClicked: {
          Idle.stayAwake(modelData);
          root.visible = false;
        }
      }
    }
  }
}
