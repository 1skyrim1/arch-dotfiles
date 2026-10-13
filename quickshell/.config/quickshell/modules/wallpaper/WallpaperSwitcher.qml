// The wallpaper switcher (SUPER + CTRL + Space): your wallpapers in a row,
// floating over your windows. Nothing else: no panel, no backdrop.
//
//   ─┐  ┌─────┐  ┌─────┐  ╔═════════╗  ┌─────┐  ┌─────┐  ┌─
//   ─┘  └─────┘  └─────┘  ║ chosen  ║  └─────┘  └─────┘  └─
//                         ╚═════════╝
//
// ← → (or h l, or the mouse wheel) to choose, Enter (or a double-click) to
// apply, Esc or a click elsewhere to close without changes.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Overlay {
  id: root

  // The size thumbnails are decoded at. The preloader and the strip must
  // ask for exactly the same size: that's what lets the strip reuse the
  // preloaded images (see the Repeater below).
  readonly property size thumbnailSize: Qt.size(Appearance.thumbnailWidth, Appearance.thumbnailHeight)

  function apply(): void {
    const chosen = Wallpaper.available[strip.currentIndex];
    if (chosen)
      Theme.apply(chosen.path);
    Overlays.close();
  }

  name: "wallpaper"
  backdrop: "none"

  // Every opening starts at the wallpaper on screen now.
  onOpened: {
    Wallpaper.rescan();
    strip.currentIndex = Math.max(0, Wallpaper.available.findIndex(entry => entry.path === Wallpaper.current));
    strip.forceActiveFocus();
    Wallpaper.upcoming = "";
    upcomingDelay.restart();
  }

  // Tells the background which wallpaper is chosen, so it can load it at
  // full size before you press Enter. Shortly after the choice settles,
  // not for every wallpaper you pass while holding an arrow key.
  Timer {
    id: upcomingDelay

    interval: 50
    onTriggered: Wallpaper.upcoming = Wallpaper.available[strip.currentIndex]?.path ?? ""
  }

  // Loads every thumbnail at startup, in the background, and keeps them
  // in memory (a few MB). The strip below asks for the very same images
  // (same file, same size), and Qt hands it these finished ones instead
  // of decoding again: the switcher opens with all thumbnails in place.
  Repeater {
    model: ScriptModel {
      values: Wallpaper.available
      objectProp: "path"
    }

    delegate: Image {
      required property var modelData

      visible: false
      source: modelData.path
      asynchronous: true
      sourceSize: root.thumbnailSize
    }
  }

  // As wide as the screen: with no panel around it, the row simply runs
  // off both screen edges instead of being cut off somewhere.
  Item {
    width: parent.width
    height: Appearance.thumbnailHeight
    anchors.centerIn: parent

    // Catches clicks in the gaps between thumbnails: a slightly missed
    // click shouldn't close the switcher. (Clicks above or below the
    // row still reach the overlay's backdrop and close it.)
    MouseArea {
      anchors.fill: parent
    }

    //-- Wallpapers --

    ListView {
      id: strip

      anchors.fill: parent
      visible: count > 0
      orientation: ListView.Horizontal
      spacing: Appearance.thumbnailSpacing

      // ScriptModel hands each entry to the delegate as `modelData`.
      // (A plain JavaScript array of objects isn't passed on the same
      // way in every Qt version; that's what left `modelData.path`
      // undefined.) objectProp: an entry counts as "the same" when
      // its path is, so a rescan of the folder keeps the existing
      // thumbnails instead of loading them all again.
      model: ScriptModel {
        values: Wallpaper.available
        objectProp: "path"
      }

      // Keeps the chosen wallpaper in the middle: the strip slides
      // instead of the selection moving. (Scrolling with the mouse
      // wheel changes the selection the same way.) This also centers
      // it on opening; positionViewAtIndex() would fight this mode.
      highlightRangeMode: ListView.StrictlyEnforceRange
      preferredHighlightBegin: (width - Appearance.thumbnailWidth) / 2
      preferredHighlightEnd: (width + Appearance.thumbnailWidth) / 2
      highlightMoveDuration: Appearance.animationDuration

      onCurrentIndexChanged: upcomingDelay.restart()

      Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_H:
          strip.decrementCurrentIndex();
          break;
        case Qt.Key_Right:
        case Qt.Key_L:
          strip.incrementCurrentIndex();
          break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
          root.apply();
          break;
        default:
          return;
        }
        event.accepted = true;
      }

      delegate: Item {
        id: thumbnail

        // { path, modified }: one entry of Wallpaper.available.
        required property var modelData
        required property int index

        readonly property bool chosen: ListView.isCurrentItem

        width: Appearance.thumbnailWidth
        height: Appearance.thumbnailHeight
        // The others are a bit smaller and dimmer, so the chosen
        // one stands out.
        scale: chosen ? 1 : Appearance.thumbnailUnchosenScale
        opacity: chosen ? 1 : 0.6

        Behavior on scale {
          NumberAnimation {
            duration: Appearance.animationDuration
            easing.type: Easing.OutCubic
          }
        }
        Behavior on opacity {
          NumberAnimation { duration: Appearance.animationDuration }
        }

        ClippingRectangle {
          anchors.fill: parent
          radius: Appearance.thumbnailRadius
          // shows while image is loading
          color: Colors.surfaceRaised

          Image {
            anchors.fill: parent
            source: thumbnail.modelData.path
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // Decoded at thumbnail size, not the full image, and
            // the same size as the preloader's, to reuse its work.
            sourceSize: root.thumbnailSize
          }
        }

        // accent outline around the chosen wallpaper
        Rectangle {
          anchors.fill: parent
          visible: thumbnail.chosen
          radius: Appearance.thumbnailRadius
          color: "transparent"
          border.width: 3
          border.color: Colors.accent
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: strip.currentIndex = thumbnail.index
          onDoubleClicked: {
            strip.currentIndex = thumbnail.index;
            root.apply();
          }
        }
      }
    }

    EmptyState {
      anchors.centerIn: parent
      visible: strip.count === 0
      icon: Icons.image
      text: `No images in ${Config.wallpaperDir}`
    }
  }
}
