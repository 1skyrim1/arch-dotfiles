pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  //-- Public state --

  property string kind: ""
  readonly property bool shown: kind !== ""

  //-- Functions --

  function show(what: string): void {
    if (what === openPopup)
      return;
    kind = what;
    hideDelay.restart();
  }

  function hide(): void {
    hideDelay.stop();
    kind = "";
  }

  function popupOpened(what: string): void {
    openPopup = what;
    if (kind === what)
      hide();
  }

  function popupClosed(what: string): void {
    if (openPopup === what)
      openPopup = "";
  }

  //-- Internals --

  property string openPopup: ""

  Timer {
    id: hideDelay

    interval: Config.osdTimeout
    onTriggered: root.kind = ""
  }
}
