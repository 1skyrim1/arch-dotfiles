pragma Singleton

// Which wallpaper is on screen, and which ones you can choose from.
//
// Changing it goes through Theme.apply(), which switches the wallpaper and
// the colors made from it together, by calling show() here.

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  //-- Public state --

  readonly property string current: Config.greeterMode ? sharedCopy : state.path

  property var available: []

  property bool scanned: false

  // The wallpaper chosen in the switcher right now, or "". The
  // background loads it at full size ahead of time, so the sweep can
  // start the moment you press Enter.
  property string upcoming: ""

  readonly property string sharedCopy: `${Config.sharedDir}/wallpaper`

  //-- Functions --

  function show(path: string): void {
    if (path === state.path)
      return;
    state.path = path;
    Quickshell.execDetached(["cp", "--", path, sharedCopy]);
  }

  function updateAvailable(): void {
    if (folder.status !== FolderListModel.Ready)
      return;
    const wallpapers = [];
    for (let i = 0; i < folder.count; i++) {
      wallpapers.push({
        path: folder.get(i, "filePath"),
        modified: folder.get(i, "fileModified").getTime(),
      });
    }
    scanned: true;
    available = wallpapers;
  }

  //-- Internals --

  FolderListModel {
    id: folder

    folder: `file://${Config.wallpaperDir}`
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    caseSensitive: false
    showDirs: false
    sortField: FolderListModel.Name

    onCountChanged: root.updateAvailable()
    onStatusChanged: root.updateAvailable()
  }

  FileView {
    path: Quickshell.statePath("wallpaper.json")
    printErrors: false
    blockLoading: true
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: state

      property string path: ""
    }
  }

  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      Overlays.toggle("wallpaper");
    }

    function set(path: string): void {
      Theme.apply(path);
    }

    function get(): string {
      return root.current;
    }
  }
}
