pragma Singleton

import Quickshell

Singleton {
  //-- Bar --
  readonly property int barHeight: 44
  readonly property int barSideMargin: 10 // gap between screen edge and first/last pill
  readonly property int sectionSpacing: 8 // gap between pills in a row

  //-- Pills --
  readonly property int pillHeight: 32
  readonly property int pillPadding: 14
  readonly property int pillContentSpacing: 8

  //-- Workspaces --
  readonly property int workspacePadding: 6
  readonly property int workspaceSpacing: 6
  readonly property int workspaceDotSize: 20
  readonly property int workspaceActiveWidth: 44
  readonly property int workspaceActiveRadius: 6

  //-- Media --
  readonly property int mediaMaxTextWidth: 220
  readonly property int mediaPopupWidth: 360
  readonly property int mediaArtSize: 96
  readonly property int mediaControlSpacing: 12

  //-- Typography --
  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 13
  readonly property int fontSizeSmall: 11
  readonly property int iconSize: 15

  //-- Motion --
  readonly property int animationDuration: 180 

  //-- Popups --
  readonly property int popupWidth: 320
  readonly property int popupPadding: 16
  readonly property int popupSpacing: 12
  readonly property int popupRadius: 16
  readonly property int popupGap: 8
  readonly property int popupRowPadding: 8
  readonly property int popupRowRadius: 10

  //-- Sliders --
  readonly property int sliderHeight: 16
  readonly property int sliderTrackHeight: 6

  //-- Popup Content --
  readonly property int popupTitleSize: 16
  readonly property int cardPadding: 12
  readonly property int cardRadius: 12
  readonly property int cardIconSize: 26
  readonly property int graphHeight: 56

  //-- Controls --
  readonly property int buttonHeight: 30
  readonly property int buttonPadding: 14
  readonly property int fieldHeight: 36
  readonly property int toggleWidth: 40
  readonly property int toggleHeight: 22
  readonly property int toggleInset: 3

  //-- Network --
  readonly property int networkPopupWidth: 360
  readonly property int networkRowHeight: 40
  readonly property int networkListMaxHeight: 240
  readonly property int pillMaxTextWidth: 160
  readonly property int graphRadius: 8
  readonly property int graphPadding: 6

  //-- Battery --
  readonly property int bigNumberSize: 32
  readonly property int levelBarHeight: 10

  //-- Notifications --
  readonly property int notificationWidth: 360
  readonly property int notificationCenterWidth: 380
  readonly property int notificationListMaxHeight: 480
  readonly property int notificationIconSize: 36
  readonly property int notificationGap: 8
  readonly property int notificationBodyLines: 3
  readonly property int badgeSize:7

  //-- Session Menu --
  readonly property int sessionTileWidth: 140
  readonly property int sessionTileHeight: 150
  readonly property int sessionTileRadius: 24
  readonly property int sessionTileSpacing: 24
  readonly property int sessionIconSize: 44
}
