pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs.config

Singleton {
  id: root

  //-- Public State --

  property var users: []

  property string selectedUser: ""
  readonly property var selected: users.find(user => user.name === selectedUser) ?? null

  property bool busy: false
  property string errorMessage: ""

  readonly property bool preview: !Greetd.available

  signal loginFailed()

  //-- Functions --

  function selectUser(name: string): void {
    if (name === selectedUser)
      return;
    if (busy) {
      Greetd.cancelSession();
      busy = false;
      pendingPassword = "";
    }
    errorMessage = "";
    selectedUser = name;
  }

  function login(password: string): void {
    if (busy || password === "" || selectedUser === "")
      return;
    if (preview) {
      errorMessage = "Preview: logging in only works when started by greetd.";
      loginFailed();
      return;
    }
    errorMessage = "";
    pendingPassword = password;
    busy = true;
    Greetd.createSession(selectedUser);
  }

  //-- Internals --

  property string pendingPassword: ""

  function fail(message: string): void {
    busy = false;
    pendingPassword = "";
    errorMessage = message;
    loginFailed();
  }

  // Reads /etc/passwd and keeps real people
  function parseUsers(passwd: string): var {
    return passwd.split("\n")
      .map(line => line.split(":"))
      .filter(([, , uid, , , , shell]) => Number(uid) >= Config.greeterMinUid
                                          && Number(uid) < 60000
                                          && !/(nologin|false)$/.test(shell))
      .map(([name, , , , gecos]) => ({
        name: name,
        displayName: gecos.split(",")[0] || name,
        avatar: `${Config.avatarDir}/${name}`,
      }));
  }

  function selectDefaultUser(): void {
    if (selectedUser !== "" || users.length === 0)
      return;
    const last = lastUserFile.text().trim();
    selectedUser = users.some(user => user.name === last) ? last : users[0].name;
  }

  FileView {
    path: "/etc/passwd"
    onLoaded: {
      root.users = root.parseUsers(text());
      root.selectDefaultUser();
    }
  }

  FileView {
    id: lastUserFile

    path: Quickshell.statePath("last-user")
    printErrors: false
    blockWrites: true
    onLoaded: root.selectDefaultUser()
    onLoadFailed: root.selectDefaultUser()
  }

  Connections {
    target: Greetd

    function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
      if (error) {
        root.errorMessage = message;
        return;
      }
      if (!responseRequired)
        return;
      if (root.pendingPassword !== "") {
        Greetd.respond(root.pendingPassword);
        root.pendingPassword = "";
      } else {
        Greetd.cancelSession();
        root.fail(message || "This account needs a login step the greeter doesn't support.");
      }
    }

    function onReadyToLaunch(): void {
      lastUserFile.setText(root.selectedUser);
      Greetd.launch(Config.greeterSessionCommand);
    }

    function onAuthFailure(message: string): void {
      root.fail("Wrong password");
    }

    function onError(error: string): void {
      root.fail(error);
    }
  }
}
