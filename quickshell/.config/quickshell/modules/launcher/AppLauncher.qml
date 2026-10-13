// The app launcher (SUPER + Space):
//
//   ┌────────────────────────────────────┐
//   │ [ Search apps…                   ] │
//   │ ▌[icon] Firefox                    │ ← selected
//   │  [icon] Web Browser                │
//   │  [icon] Files                      │
//   └────────────────────────────────────┘
//
// Type to search, ↑ ↓ to choose, Enter to open, Esc to close.
// Named AppLauncher (not Launcher) so it doesn't clash with the Launcher
// service.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

Overlay {
  id: root

  name: "launcher"

  onOpened: {
    search.reset();
    search.focusInput();
  }

  Binding {
    target: Launcher
    property: "query"
    value: search.query
  }

  OverlayCard {
    width: Appearance.launcherWidth
    anchors {
      horizontalCenter: parent.horizontalCenter
      top: parent.top
      topMargin: parent.height * Appearance.launcherTopFraction
    }

    SearchList {
      id: search

      Layout.fillWidth: true
      placeholderText: "Apps, =calculate, :emoji"
      results: Launcher.results
      emptyIcon: Launcher.emptyIcon
      emptyText: Launcher.emptyText

      onPicked: result => Launcher.activate(result)
      onCancelled: Launcher.close()

      delegate: SearchListRow {
        id: row

        required property var modelData

        readonly property bool isEmoji: modelData.kind === "emoji"

        RowLayout {
          anchors.fill: parent
          spacing: Appearance.popupRowPadding

          AppIcon {
            visible: !row.isEmoji
            icon: row.modelData.icon
            name: row.modelData.glyph || row.modelData.title
          }

          StyledText {
            Layout.preferredWidth: Appearance.launcherIconSize
            visible: row.isEmoji
            horizontalAlignment: Text.AlignHCenter
            text: row.modelData.glyph
            font.pixelSize: Appearance.launcherIconSize * 0.8
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
              Layout.fillWidth: true
              text: row.modelData.title
              elide: Text.ElideRight
            }

            StyledText {
              Layout.fillWidth: true
              visible: text !== ""
              text: row.modelData.subtitle
              color: Colors.foregroundMuted
              font.pixelSize: Appearance.fontSizeSmall
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
