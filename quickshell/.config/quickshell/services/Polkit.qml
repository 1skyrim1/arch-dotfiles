pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

Singleton {
  id: root

  //-- Public state --

  readonly property AuthFlow flow: agent.flow

  property string message: ""
  property string iconName: ""
  property string userName: ""

  readonly property string prompt: (flow?.inputPrompt ?? "").replace(/:\s*$/, "")

  property bool checking: false

  readonly property string status: {
    if (!flow)
      return "";
    const pamMessage = flow.supplementaryMessage;
    if (flow.supplementaryIsError && pamMessage !== "")
      return pamMessage;
    if (flow.failed)
      return "Wrong password, try again";
    return pamMessage;
  }
  readonly property bool statusIsError: !!flow && ((flow.supplementaryIsError && flow.supplementaryMessage !== "") || flow.failed)

  signal requestStarted()
  signal failed()

  //-- Functions --

  function submit(response: string): void {
    if (!flow || !flow.isResponseRequired)
      return;
    checking = true;
    flow.submit(response);
  }

  function cancel(): void {
    if (flow && !flow.isCompleted)
      flow.cancelAuthenticationRequest();
  }

  //-- Internals --

  PolkitAgent {
    id: agent

    onAuthenticationRequestStarted: {
      const request = agent.flow;
      root.message = request.message;
      root.iconName = request.iconName;
      root.userName = request.selectedIdentity?.displayName ?? "";
      root.checking = false;
      Overlays.open("polkit");
      root.requestStarted();
    }

    onIsActiveChanged: {
      if (!isActive)
        Qt.callLater(root.closeIfIdle);
    }
  }

  function closeIfIdle(): void {
    if (!agent.isActive && Overlays.current === "polkit")
      Overlays.close();
  }

  Connections {
    target: Overlays

    function onCurrentChanged(): void {
      if (Overlays.current !== "polkit")
        root.cancel();
    }
  }

  Connections {
    target: agent.flow

    function onIsResponseRequiredChanged(): void {
      if (agent.flow.isResponseRequired)
        root.checking = false;
    }

    function onAuthenticationFailed(): void {
      root.checking = false;
      root.failed();
    }
  }

  IpcHandler {
    target: "polkit"

    function status(): string {
      if (!agent.isRegistered)
        return "Not registered: is another polkit agent running? (pgrep -af polkit)";
      return agent.isActive ? `Registered, asking: ${root.message}` : "Registered, waiting for requests";
    }
  }
}
