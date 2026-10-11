import Quickshell

Scope {
  Variants {
    model: Quickshell.screens

    delegate: BarWindow {
      required property ShellScreen modelData

      screen: modelData
    }
  }
}
