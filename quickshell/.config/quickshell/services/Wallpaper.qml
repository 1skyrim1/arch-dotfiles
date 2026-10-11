pragma Singleton

// Owns "which wallpaper is set"

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.config

Singleton {
  id: root

  readonly property string current: storage.text().trim()

  readonly property FolderListModel available: folderModel

  FolderListModel {
    id: folderModel

    folder: `file://${Config.wallpaperDir}`
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    showDirs: false
    sortField: FolderListModel.Name
  }

  function set(path: string): void {
    storage.setText(path);
  }

  FileView {
    id: storage

    path: Quickshell.statePath("wallpaper")
    watchChanges: true
    onFileChanged: reload()
    printErrors: false
  }

  IpcHandler {
    target: "wallpaper"
    function set(path: string): void {
      root.set(path);
    }

    function get(): string {
      return root.current;
    }
  }
}
