import QtQuick
import qs.config

StyledTextField {
  id: root

  property bool busy: false

  function shake(): void {
    shakeAnimation.restart();
  }

  implicitWidth: Appearance.lockFieldWidth
  echoMode: TextInput.Password
  placeholderText: busy ? "Checking..." : "Password"

  opacity: busy ? 0.5 : 1

  Behavior on opacity {
    NumberAnimation { duration: Appearance.animationDuration }
  }

  transform: Translate {
    id: shakeOffset
  }

  SequentialAnimation {
    id: shakeAnimation

    loops: 2
    NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: 50 }
    NumberAnimation { target: shakeOffset; property: "x"; to: 10; duration: 100 }
    NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
  }
}
