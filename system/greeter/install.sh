#!/usr/bin/env bash
# Sets up the Quickshell login screen on this machine, or updates it.
#
# Run it as yourself, NOT with sudo. It asks for your password when it
# needs root:
#   ~/arch-dotfiles/system/greeter/install.sh
#
# Safe to run again and again: every step either checks something or
# overwrites with the repo's version. Run it after changing code the login
# screen uses, to deploy it.

# Stop at the first failing command (-e), on unset variables (-u), and when
# any command in a pipe fails (pipefail). A half-finished setup is worse
# than none.
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────────────────

# The folder this script is in, wherever the repo was cloned to. So it
# works from any directory and for any clone location.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"

# Copied straight from the repo (not from ~/.config), so it doesn't matter
# whether you've run stow yet. Change this if your package has another name.
SHELL_SRC="$REPO/quickshell/.config/quickshell"
SHELL_DEST="/etc/greetd/myshell"

# These must match Config.sharedDir and Config.avatarDir in Config.qml.
SHARED_DIR="/var/lib/myshell"
AVATAR_DIR="/var/lib/AccountsService/icons"

# Fonts you added by hand go here: the system-wide place for fonts that
# don't come from a package (pacman never touches /usr/local).
FONT_DEST="/usr/local/share/fonts/myshell"

# ─────────────────────────────────────────────────────────────────────────
# Output helpers: a blue "==>" per step, yellow notes, red errors.
# ─────────────────────────────────────────────────────────────────────────

step() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
note() { printf '\033[1;33mnote:\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

# ─────────────────────────────────────────────────────────────────────────
# Checks: all before changing anything, so a failure leaves the system
# untouched.
# ─────────────────────────────────────────────────────────────────────────

# Under sudo, $USER and $HOME would be root's, and your avatar and the
# shared folder's owner would come out wrong.
[[ $EUID -ne 0 ]] || die "Run this as your user, not with sudo. It uses sudo itself."

[[ -f "$SHELL_SRC/greeter.qml" ]] || die "No greeter.qml in $SHELL_SRC. Is SHELL_SRC right?"
command -v qs >/dev/null || die "Quickshell isn't installed."
command -v start-hyprland >/dev/null || die "Hyprland isn't installed."

# Only one login manager can be enabled. systemd marks the enabled one with
# a link called display-manager.service. If it points to something else
# (sddm, gdm, ly…), let you decide instead of silently replacing it.
DM_LINK="/etc/systemd/system/display-manager.service"
if [[ -L "$DM_LINK" ]]; then
  current_dm="$(basename "$(readlink "$DM_LINK")")"
  if [[ "$current_dm" != "greetd.service" ]]; then
    die "Another login manager is enabled: $current_dm. Disable it first: sudo systemctl disable $current_dm"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────────────────

step "Installing greetd and rsync"
# --needed: skip packages that are already installed.
sudo pacman -S --needed --noconfirm greetd rsync

# The greetd package creates this user; the login screen runs as it.
id greeter &>/dev/null || die "User 'greeter' doesn't exist. It should come with the greetd package."

step "Copying the shell code to $SHELL_DEST"
#   -a        keep folder structure and timestamps
#   -L        copy real files, never symlinks (the greeter can't follow
#             links into your home folder)
#   --delete  remove files that no longer exist in the repo
#   --chown / --chmod
#             owned by root, readable by everyone: the greeter can read
#             the code but not change it
# The "/" after $SHELL_SRC copies the folder's contents, not the folder.
sudo rsync -aL --delete --chown=root:root --chmod=D755,F644 \
  "$SHELL_SRC/" "$SHELL_DEST/"

step "Installing greetd's config"
# install -D: create missing parent folders, then copy with mode 644
# (root writes, everyone reads).
sudo install -D -m 644 "$HERE/etc/greetd/config.toml" /etc/greetd/config.toml
sudo install -D -m 644 "$HERE/etc/greetd/hyprland.lua" /etc/greetd/hyprland.lua

if [[ -d "$HERE/fonts" ]]; then
  step "Installing fonts to $FONT_DEST"
  sudo rsync -a --delete --chown=root:root --chmod=D755,F644 \
    "$HERE/fonts/" "$FONT_DEST/"
  # Rebuild the font list so new fonts are found without a reboot.
  sudo fc-cache -f
fi

step "Creating the shared folder $SHARED_DIR"
# Your shell writes the wallpaper and colors here (matugen's "greeter"
# template too), and the login screen reads them. Owned by you, so your
# shell can write without sudo; readable by everyone (755).
sudo install -d -m 755 -o "$USER" -g "$(id -gn)" "$SHARED_DIR"

step "Installing your avatar"
if [[ -f "$HOME/.face" ]]; then
  # Copied, not linked: the greeter can't read your home folder.
  sudo install -D -m 644 "$HOME/.face" "$AVATAR_DIR/$USER"
else
  note "No ~/.face found. The login screen shows your initial instead."
fi

step "Enabling greetd"
# Only enabled, not started: starting it now would take over the screen
# your session might be running on. It starts with the next boot.
sudo systemctl enable greetd.service

# ─────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────

# On a fresh install your shell hasn't published a wallpaper yet.
if [[ -z "$(ls -A "$SHARED_DIR")" ]]; then
  note "$SHARED_DIR is still empty. Log in once and pick a wallpaper,"
  note "so the login screen gets your wallpaper and colors."
fi

step "Done. Reboot to see the login screen."
echo "If it doesn't come up: press Ctrl+Alt+F2, log in, and run"
echo "  sudo systemctl disable greetd"
