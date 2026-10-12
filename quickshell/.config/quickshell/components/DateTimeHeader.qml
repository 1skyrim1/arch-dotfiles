import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

ColumnLayout {
  spacing: 0

  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  StyledText {
    Layout.alignment: Qt.AlignHCenter
    text: Qt.formatDate(clock.date, Config.lockDateFormat)
    font.pixelSize: Appearance.lockDateSize
    font.bold: true
  }

  StyledText {
    Layout.alignment: Qt.AlignHCenter
    text: Qt.formatTime(clock.date, Config.lockClockFormat)
    font.pixelSize: Appearance.lockClockSize
    font.bold: true
  }
}
