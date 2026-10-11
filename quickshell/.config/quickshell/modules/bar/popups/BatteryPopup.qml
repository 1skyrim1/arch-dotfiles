// The battery popup, top to bottom
//  1. Big percentage with what's happening ("On Battery · 3 h 20 min left")
//  2. Level bar
//  3. Detail: power draw, energy, battery health

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  function formatDuration(seconds: real): string {
    if (seconds <= 0)
      return "";
    const minutes = Math.round(seconds / 60);
    const hours = Math.floor(minutes / 60);
    return hours > 0 ? `${hours} h ${minutes % 60} min` : `${minutes} min`;
  }

  readonly property string status: {
    if (Power.fullyCharged)
      return "Fully charged";
    if (Power.charging) {
      const time = formatDuration(Power.timeToFull);
      return time ? `Charging · ${time} until full` : "Charging";
    }
    if (Power.runningOnBattery) {
      const time = formatDuration(Power.timeToEmpty);
      return time ? `On battery · ${time} left` : "On battery";
    }

    return "Plugged in, not charging";
  }

  readonly property color levelColor: Power.low ? Colors.critical : Colors.accent

  //-- 1. Percentage and status --

  RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.cardPadding

    StyledText {
      text: `${Math.round(Power.charge * 100)}%`
      color: root.levelColor
      font.pixelSize: Appearance.bigNumberSize
      font.bold: true
    }

    StyledText {
      Layout.fillWidth: true
      text: root.status
      color: Colors.foregroundMuted
      wrapMode: Text.WordWrap
    }
  }

  //-- 2. Level bar --

  LevelBar {
    Layout.fillWidth: true
    value: Power.charge
    fillColor: root.levelColor
  }

  //-- 3. Details --

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: details.implicitHeight + 2 * Appearance.cardPadding
    radius: Appearance.cardRadius
    color: Colors.surfaceRaised

    ColumnLayout {
      id: details

      anchors {
        fill: parent
        margins: Appearance.cardPadding
      }
      spacing: Appearance.popupRowPadding

      DetailRow {
        label: Power.charging ? "Charging at" : "Power draw"
        value: Power.power > 0 ? `${Power.power.toFixed(1)} W` : ""
      }

      DetailRow {
        label: "Energy"
        value: Power.energyCapacity > 0
            ? `${Power.energy.toFixed(1)} of ${Power.energyCapacity.toFixed(1)} Wh`
            : ""
      }

      DetailRow {
        label: "Battery health"
        value: Power.health >= 0 ? `${Math.round(Power.health * 100)}%` : ""
      }
    }
  }
}
