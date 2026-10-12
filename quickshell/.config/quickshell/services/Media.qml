pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
  id: root

  //-- Players --

  readonly property list<MprisPlayer> players: Mpris.players.values

  property MprisPlayer chosenPlayer: null

  readonly property MprisPlayer player: {
    const all = Array.from(players);
    if (chosenPlayer && all.includes(chosenPlayer))
      return chosenPlayer;
    return all.find(candidate => candidate.isPlaying) ?? all[0] ?? null;
  }

  //-- Current track --

  readonly property bool active: player !== null
  readonly property bool playing: player?.isPlaying ?? false
  readonly property string title: player?.trackTitle ?? ""
  readonly property string artist: player?.trackArtist ?? ""
  readonly property string album: player?.trackAlbum ?? ""
  readonly property string artUrl: player?.trackArtUrl ?? ""
  readonly property string playerName: player?.identity ?? ""

  property real length: 0
  readonly property real position: (player?.positionSupported ?? false) ? player.position : 0

  readonly property bool canSeek: (player?.canSeek ?? false) && length > 0
  readonly property bool canGoNext: player?.canGoNext ?? false
  readonly property bool canGoPrevious: player?.canGoPrevious ?? false
  readonly property bool canTogglePlaying: player?.canTogglePlaying ?? false

  readonly property bool shuffleSupported: (player?.canControl ?? false) && (player?.shuffleSupported ?? false)
  readonly property bool shuffle: player?.shuffle ?? false
  readonly property bool loopSupported: (player?.canControl ?? false) && (player?.loopSupported ?? false)
  readonly property int loopState: player?.loopState ?? MprisLoopState.None

  //-- Functions --

  function choosePlayer(newPlayer: MprisPlayer): void {
    chosenPlayer = newPlayer;
  }

  function togglePlaying(): void {
    if (canTogglePlaying)
      player.togglePlaying();
  }

  function next(): void {
    if (canGoNext)
      player.next();
  }

  function previous(): void {
    if (canGoPrevious)
      player.previous();
  }

  function seekTo(seconds: real): void {
    if (!canSeek)
      return;
    if (player.positionSupported)
      player.position = seconds;
    else
      player.seek(seconds - position);
  }

  function toggleShuffle(): void {
    if (shuffleSupported)
      player.shuffle = !player.shuffle
  }

  function cycleLoop(): void {
    if (!loopSupported)
      return;
    switch (player.loopState) {
    case MprisLoopState.None:
      player.loopState = MprisLoopState.Playlist;
      break;
    case MprisLoopState.Playlist:
      player.loopState = MprisLoopState.Track;
      break;
    default:
      player.loopState = MprisLoopState.None;
    }
  }

  function updateLength(): void {
    const reported = (player?.lengthSupported ?? false) ? player.length : 0;
    if (reported > 0)
      length = reported;
    }

    function resetLength(): void {
      length = 0;
      updateLength();
    }

  function raisePlayer(): void {
    if (player?.canRaise)
      player.raise();
  }

  //-- Internals --

  onPlayerChanged: resetLength()

  Connections {
    target: root.player

    function onPostTrackChanged(): void {
      root.resetLength();
    }

    function onLengthChanged(): void {
      root.updateLength();
    }
  }

  Timer {
    interval: 1000
    running: root.playing
    repeat: true
    onTriggered: {
      root.player?.positionChanged();
      root.updateLength();
    }
  }

  IpcHandler {
    target: "media"

    function togglePlaying(): void {
      root.togglePlaying();
    }

    function next(): void {
      root.next();
    }

    function previous(): void {
      root.previous();
    }
  }
}
