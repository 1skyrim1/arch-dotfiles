# arch-dotfiles

My Arch Linux desktop: Hyprland with a self-written [Quickshell](https://quickshell.org) shell. Bar, launcher, notifications, lock and login screen, and everything else on screen share one design. Their colors come from the wallpaper (Material You via [matugen](https://github.com/InioX/matugen)), and the terminal, GTK and Qt apps and the window borders follow along.

## Install

On a fresh Arch install (archinstall is fine), log in on the console and run:

```sh
git clone https://github.com/1skyrim1/arch-dotfiles ~/arch-dotfiles
~/arch-dotfiles/install.sh
```

Run it as yourself, not with `sudo`; it asks for your password when it needs root. Then reboot.

What `install.sh` does:

1. **System files**: copies `system/etc` to `/etc` (mirror list, locales, zram).
2. **Packages**: installs everything in `packages/*.txt`, with `yay` for the AUR.
3. **Extras**: installs the zsh prompt (powerlevel10k).
4. **Configs**: links every config into your home folder with stow. Files already in the way are moved to `~/.dotfiles-backup/`, never deleted.
5. **Look**: sets the dark GTK theme, Papirus icons and the Bibata cursor, and makes the first colors from the default wallpaper.
6. **Services**: enables Bluetooth, power profiles and NetworkManager.
7. **Shell**: makes zsh your login shell.
8. **Login screen**: runs `system/greeter/install.sh`.

It's safe to run again at any time to bring a machine up to date with the repo.

## Keybinds

### Windows and apps

| Keys | Action |
|---|---|
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + SHIFT + Return` | Browser (Zen) |
| `SUPER + SHIFT + F` | File manager (Nautilus) |
| `SUPER + W` | Close window |
| `SUPER + F` | Maximize / restore |
| `SUPER + T` | Float / tile |
| `SUPER + J` | Swap the split direction |
| `SUPER + ←↑↓→` | Move focus |
| `SUPER + 1 … 0` | Go to workspace 1–10 |
| `SUPER + SHIFT + 1 … 0` | Move window to workspace 1–10 |
| `SUPER + scroll` | Next / previous workspace |
| `SUPER + S` | Show / hide the scratchpad |
| `SUPER + SHIFT + S` | Move window to the scratchpad |
| `SUPER + left drag` | Move window |
| `SUPER + right drag` | Resize window |
| `SUPER + C / V / X / A` | Copy / paste / cut / select all (copy and paste also work in the terminal) |

### Shell

| Keys | Action |
|---|---|
| `SUPER + Space` | App launcher: start typing `=` for the calculator (e.g. `=5 ft to cm`) or `:` for emoji (e.g. `:fire`) |
| `SUPER + CTRL + Space` | Wallpaper switcher: ← → to choose, Enter to apply (colors follow) |
| `SUPER + Escape` | Session menu: shutdown, reboot, log out, sleep, lock |
| `SUPER + L` | Lock the screen |
| `SUPER + N` | Do Not Disturb on / off |
| `SUPER + SHIFT + N` | Dismiss all notifications |
| `Print` | Screenshot of a region (the screen freezes; drag, Esc cancels) |
| `SHIFT + Print` | Screenshot of the whole screen |

Screenshots are saved to `~/Pictures/Screenshots` and copied to the clipboard.

### Hardware keys

These work on the lock screen too.

| Keys | Action |
|---|---|
| Volume up / down / mute | Volume, with an on-screen indicator |
| Brightness up / down | Screen brightness, with an on-screen indicator |
| Play / pause, next, previous | Media |

### The bar

| Item | Left click | Right click |
|---|---|---|
| Logo | Session menu | |
| Workspaces | Go to that workspace (scroll to switch) | |
| Media | Player controls | Play / pause |
| Clock | Calendar | |
| Updates | Update in a terminal | |
| Power mode | Next mode | Previous mode |
| Network | Wi-Fi and Bluetooth | |
| Volume | Mixer (devices, per-app volume) | Mute |
| Battery | Battery details and power mode | |
| Bell | Notification center | |

## Automatic

- **Idle**: locks after 5 min, turns the screen off 30 s after locking, sleeps after 15 min on battery (30 min plugged in). It waits while a video plays, and sleep waits while any media plays. The times are in `Config.qml`.
- **Password dialog**: appears when an app needs admin rights (the shell is the polkit agent).

## Layout

Each top-level folder except `packages`, `scripts` and `system` is a stow package, mirroring its place in your home folder.

| Folder | What's in it |
|---|---|
| `quickshell` | The shell (`shell.qml`) and the login screen (`greeter.qml`) |
| `hypr` | Hyprland (Lua config; keybinds in `modules/keybinds.lua`) |
| `matugen` | Templates that turn the wallpaper's colors into config files |
| `kitty`, `nvim`, `zsh` | Terminal, editor, shell |
| `gtk`, `qt6ct` | GTK and Qt theming |
| `wallpapers` | `~/Pictures/wallpapers`, the switcher's folder |
| `bin` | `~/.local/bin` helper commands (see below) |
| `packages` | Package lists: `base.txt`, `desktop.txt`, `aur.txt`, `intel.txt` |
| `system` | Files for `/etc`; `system/greeter` sets up the login screen |
| `scripts` | `dotfiles-check` |

Generated files (the color files, `gtk-4.0/gtk.css`) are in `.gitignore`.

## Keeping things in sync

| Command | What it does |
|---|---|
| `pkg-install` | Search the official repos, install, and add to `desktop.txt` |
| `pkg-aur-install` | The same for the AUR (`aur.txt`) |
| `pkg-remove` | Remove packages and take them off the lists |
| `scripts/dotfiles-check` | Everything on this system that isn't in the repo, and the other way round |
| `system/greeter/install.sh` | Deploy the shell code to the login screen; run it after changing code the login screen uses |

## Checking on the shell

The shell answers on the command line (`qs ipc call <target> <function>`). The shell keybinds above go through this too.

| Command | Answer |
|---|---|
| `qs ipc call theme status` | Whether all wallpapers' colors are calculated |
| `qs ipc call polkit status` | Whether the password dialog is registered |
| `qs ipc call bluetooth status` | Bluetooth adapter and every known device |
| `qs ipc call wallpaper set <file>` | Apply a wallpaper from a script |
| `qs ipc call brightness set <percent>` | Set the brightness |

To see the shell's warnings, restart it from a terminal: `pkill qs; qs`.

## If the login screen doesn't come up

Press `Ctrl + Alt + F2`, log in, and run `sudo systemctl disable greetd`. After a reboot you're back to logging in on the console, where `.zprofile` starts Hyprland.
