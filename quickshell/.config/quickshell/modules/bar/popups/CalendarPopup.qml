// The calendar popup, opened from the clock:
//
//   Wednesday
//   14 October 2026
//
//   October 2026                    ‹  ›
//        Mo  Tu  We  Th  Fr  Sa  Su
//   40   28  29  30   1   2   3   4      ← days of other months are dimmed
//   41    5   6   7   8   9  10  11
//   42   12  13 (14) 15  16  17  18      ← today is filled with the accent
//   …
//
// ‹ › or the mouse wheel move by a month; clicking the month name jumps
// back to today. It always opens on the current month. Only dates, no
// events.
//
// The grid comes from Qt's MonthGrid, which already knows how months line
// up with weekdays, and follows your locale: the week starts on Monday or
// Sunday, and day and month names are in your language.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

BarPopup {
  id: root

  implicitWidth: calendarGrid.implicitWidth + 2 * Appearance.popupPadding

  property int shownMonth: clock.date.getMonth()
  property int shownYear: clock.date.getFullYear()

  readonly property bool showingToday: shownMonth === clock.date.getMonth()
                                    && shownYear === clock.date.getFullYear()

  function moveMonth(step: int): void {
    const target = new Date(shownYear, shownMonth + step, 1);
    shownMonth = target.getMonth();
    shownYear = target.getFullYear();
  }

  function showToday(): void {
    shownMonth = clock.date.getMonth();
    shownYear = clock.date.getFullYear();
  }

  function sameDay(a: date, b: date): bool {
    return a.getFullYear() === b.getFullYear()
        && a.getMonth() === b.getMonth()
        && a.getDate() === b.getDate()
  }

  onVisibleChanged: {
    if (visible)
      showToday();
  }

  SystemClock {
    id: clock

    precision: SystemClock.Hours
  }

  //-- Today, in words --

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    StyledText {
      text: Qt.locale().dayName(clock.date.getDay(), Locale.LongFormat)
      color: Colors.foregroundMuted
    }

    StyledText {
      text: clock.date.toLocaleDateString(Qt.locale(), Config.calendarDateFormat)
      font.pixelSize: Appearance.popupTitleSize
      font.bold: true
    }
  }

  //-- Month header: name and arrows --

  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: Appearance.popupSpacing

    StyledText {
      Layout.fillWidth: true
      text: `${Qt.locale().standaloneMonthName(root.shownMonth, Locale.LongFormat)} ${root.shownYear}`
      color: root.showingToday ? Colors.foreground : Colors.accent
      font.bold: true

      MouseArea {
        anchors.fill: parent
        enabled: !root.showingToday
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showToday()
      }
    }

    ArrowButton {
      icon: Icons.chevronLeft
      onClicked: root.moveMonth(-1)
    }

    ArrowButton {
      icon: Icons.chevronRight
      onClicked: root.moveMonth(1)
    }
  }

  //-- The grid --

  GridLayout {
    id: calendarGrid

    columns: 2
    columnSpacing: 0
    rowSpacing: 0

    // Corner above the week numbers
    Item {
      visible: Config.calendarWeekNumbers
      implicitWidth: 1
      implicitHeight: 1
    }

    // Mo Tu We ...
    DayOfWeekRow {
      Layout.fillWidth: true
      locale: grid.locale
      spacing: 0

      delegate: StyledText {
        required property string shortName

        width: Appearance.calendarCellSize
        horizontalAlignment: Text.AlignHCenter
        text: shortName
        color: Colors.foregroundMuted
        font.pixelSize: Appearance.fontSizeSmall
      }
    }

    // Calendar week numbers
    WeekNumberColumn {
      visible: Config.calendarWeekNumbers
      month: grid.month
      year: grid.year
      locale: grid.locale
      spacing: 0

      delegate: StyledText {
        required property int weekNumber

        width: Appearance.calendarCellSize
        height: Appearance.calendarCellSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: weekNumber
        color: Colors.foregroundMuted
        opacity: 0.6
        font.pixelSize: Appearance.fontSizeSmall
      }
    }

    MonthGrid {
      id: grid

      month: root.shownMonth
      year: root.shownYear
      locale: Qt.locale()
      spacing: 0

      // One day. MonthGrid always shows six weeks, so the first and
      // last rows hold days of the months around this one.
      delegate: Item {
        id: day

        // Provided by MonthGrid for each cell
        required property date date
        required property int month

        readonly property bool inShownMonth: month === grid.month
        readonly property bool isToday: root.sameDay(date, clock.date)

        implicitWidth: Appearance.calendarCellSize
        implicitHeight: Appearance.calendarCellSize

        Rectangle {
          anchors.centerIn: parent
          width: Appearance.calendarCellSize - 4
          height: width
          radius: width / 2
          visible: day.isToday
          color: Colors.accent
        }

        StyledText {
          anchors.centerIn: parent
          text: day.date.getDate()
          color: day.isToday ? Colors.foregroundOnAccent : Colors.foreground
          opacity: day.inShownMonth ? 1 : 0.35
          font.bold: day.isToday
        }
      }

      WheelHandler {
        property real collected: 0

        onWheel: event => {
          collected += event.angleDelta.y;
          if (Math.abs(collected) >= 120) {
            root.moveMonth(collected > 0 ? -1 : 1);
            collected = 0;
          }
        }
      }
    }
  }

  //-- Inline component --

  component ArrowButton: Rectangle {
    id: arrow

    property string icon

    signal clicked()

    implicitWidth: Appearance.calendarCellSize
    implicitHeight: Appearance.calendarCellSize
    radius: width / 2
    color: "transparent"

    StyledText {
      anchors.centerIn: parent
      text: arrow.icon
      font.pixelSize: Appearance.iconSize
    }

    StateLayer {
      mouseArea: arrowMouse
      radius: arrow.radius
    }

    MouseArea {
      id: arrowMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: arrow.clicked()
    }
  }
}
