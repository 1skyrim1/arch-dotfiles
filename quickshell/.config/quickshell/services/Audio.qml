pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config

Singleton {
  id: root

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink?.ready ?? false

  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? false

  readonly property list<PwNode> outputs: Pipewire.nodes.values.filter(
    node => node.audio && node.isSink && !node.isStream)

  readonly property list<PwNode> streams: Pipewire.nodes.values.filter(
    node => node.audio && node.isStream && !node.isSink)

  //-- Actions --

  function setNodeVolume(node: PwNode, value: real): void {
    if (node?.ready)
      node.audio.volume = Math.max(0, Math.min(1, value));
  }

  function setVolume(value: real): void {
    if (!ready)
      return;
    sink.audio.muted = false;
    sink.audio.volume = Math.max(0, Math.min(1, value));
  }

  function changeVolume(delta: real): void {
    setVolume(volume + delta);
  }

  function toggleMute(): void {
    if (ready)
      sink.audio.muted = !sink.audio.muted;
  }

  function setDefaultOutput(node: PwNode): void {
    Pipewire.preferredDefaultAudioSink = node;
  }

  function displayName(node: PwNode): string {
    if (!node)
      return ""
    if (node.isStream)
      return node.properties?.["application.name"] || node.description || node.name;
    return node.description || node.nickname || node.name;
  }

  PwObjectTracker {
    objects: Array.from(root.outputs).concat(Array.from(root.streams))
  }

  IpcHandler {
    target: "audio"

    function increase(): void {
      root.changeVolume(Config.volumeStep);
      Osd.show("volume");
    }

    function decrease(): void {
      root.changeVolume(-Config.volumeStep);
      Osd.show("volume");
    }

    function toggleMute(): void {
      root.toggleMute();
      Osd.show("volume");
    }
  }
}
