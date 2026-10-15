pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config

Singleton {
  id: root

  //-- Public state --

  property bool locked: false
  property bool secure: false
  readonly property bool checking: pam.active
  property string errorMessage: ""

  signal authenticationFailed()

  //-- Functions --

  function lock(): void {
    if (locked)
      return;
    errorMessage = "";
    locked = true;
  }

  function authenticate(password: string): void {
    if (!locked || checking || password === "")
      return;
    errorMessage = "";
    pamError = "";
    pendingPassword = password;
    if (!pam.start()) {
      pendingPassword = "";
      errorMessage = "Couldn't start the password check.";
    }
  }

  //-- Password check (PAM)

  property string pendingPassword: ""
  property string pamError: ""

  PamContext {
    id: pam

    config: "login"

    onPamMessage: {
      if (messageIsError)
        root.pamError = message;
      if (responseRequired) {
        respond(root.pendingPassword);
        root.pendingPassword = "";
      }
    }

    onCompleted: result => {
      root.pendingPassword = "";
      switch (result) {
      case PamResult.Success:
        root.locked = false;
        break;
      case PamResult.Failed:
        root.errorMessage = root.pamError || "Wrong password";
        root.authenticationFailed();
        break;
      case PamResult.MaxTries:
        root.errorMessage = root.pamError || "Too many attempts. Try again later.";
        root.authenticationFailed();
        break;
      default:
        root.errorMessage = pam.message || "The password check failed.";
        root.authenticationFailed();
      }
    }
  }

  onLockedChanged: {
    if (!locked)
      secure = false;
  }

  //-- Locking before sleep --

  property bool sleepPending: false

  Process {
    id: sleepInhibitor

    command: ["systemd-inhibit", "--what=sleep", "--mode=delay",
              "--who=Quickshell", "--why=Lock the screen before sleeping",
              "sleep", "infinity"]
    running: true
  }

  function prepareForSleep(goingToSleep: bool): void {
    if (goingToSleep) {
      sleepPending = true;
      lock();
      releaseSleepIfSecure();
    } else {
      sleepInhibitor.running = true;
    }
  }

  function releaseSleepIfSecure(): void {
    if (sleepPending && secure) {
      sleepPending = false;
      sleepInhibitor.running = false;
    }
  }

  onSecureChanged: releaseSleepIfSecure()

  //-- Listening to systemd-login --

  readonly property string sessionPath: {
    const id = Quickshell.env("XDG_SESSION_ID") ?? "";
    if (id === "")
      return "";
    const escaped = Array.from(id).map((character, index) =>
      /[A-Za-z]/.test(character) || (/[0-9]/.test(character) && index > 0)
        ? character
        : "_" + character.charCodeAt(0).toString(16).padStart(2, "0")).join("");
    return `/org/freedesktop/login1/session/${escaped}`;
  }

  function handleLogindSignal(line: string): void {
    const match = line.match(/^(\S+): org\.freedesktop\.login1\.(Session\.Lock|Manager\.PrepareForSleep) \((.*)\)$/);
    if (!match)
      return;
    const [, path, signal, args] = match;
    if (signal === "Session.Lock") {
      if (sessionPath === "" || path === sessionPath)
        lock();
    } else {
      prepareForSleep(args.startsWith("true"));
    }
  }

  Process {
    command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
    running: true
    stdout: SplitParser {
      onRead: line => root.handleLogindSignal(line)
    }
    onExited: console.warn("Lock: stopped listening to logind (is gdbus installed?). "
                           + "Locking on lid close and `loginctl lock-session` won't work.")
  }

  //-- Ipc --

  IpcHandler {
    target: "lock"

    function lock(): void {
      root.lock();
    }
  }
}
