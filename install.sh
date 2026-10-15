#!/usr/bin/env bash
# Sets up this whole desktop on a fresh Arch install, or brings an existing
# one up to date with the repo.
#
# On a new machine: install Arch (archinstall is fine), log in on the
# console, then:
#   git clone https://github.com/1skyrim1/arch-dotfiles ~/arch-dotfiles
#   ~/arch-dotfiles/install.sh
#
# Run it as yourself, NOT with sudo: it asks for your password when it
# needs root. Safe to run again and again: every step installs only what's
# missing or overwrites with the repo's version.
#
# What it does, in order:
#    1. system files      /etc files from system/etc (mirrors, locales, zram)
#    2. packages          everything in packages/*.txt, from the official
#                         repos and the AUR
#    3. extras            the zsh prompt (powerlevel10k)
#    4. configs           links everything into your home folder with stow
#                         (files that are in the way are moved to a backup)
#    5. look              dark GTK theme, icons, cursor; first colors from
#                         the default wallpaper
#    6. services          Bluetooth, power profiles, NetworkManager
#    7. shell             zsh as your login shell
#    8. login screen      runs system/greeter/install.sh

# Stop at the first failing command (-e), on unset variables (-u), and when
# any command in a pipe fails (pipefail).
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────
# Settings
# ─────────────────────────────────────────────────────────────────────────

# The repo: the folder this script is in, wherever it was cloned to.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The folders that stow links into your home folder. Not listed on
# purpose: packages/ and scripts/ (used from the repo directly) and
# system/ (goes to /etc, see below).
STOW_PACKAGES=(bin gtk hypr kitty matugen nvim qt6ct quickshell wallpapers zsh)

# Your own files that are in the way of a link are moved here, never
# deleted. One folder per run.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y-%m-%d_%H-%M-%S)"

# Look and feel, matching qt6ct.conf and hypr/modules/env_vars.lua.
GTK_THEME="adw-gtk3-dark"
ICON_THEME="Papirus-Dark"
CURSOR_THEME="Bibata-Modern-Classic"
CURSOR_SIZE=24

# The wallpaper the first colors are made from.
DEFAULT_WALLPAPER="$REPO/wallpapers/Pictures/wallpapers/default.jpg"

# ─────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────

# A blue "==>" per step, yellow notes, red errors (same as the greeter's
# install script).
step() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
note() { printf '\033[1;33mnote:\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

# The package names in one or more package lists, one per line: comments
# (# …) and empty lines removed. Same rules as scripts/dotfiles-check.
read_list() { sed 's/#.*//' "$@" | tr -s ' \t' '\n' | sed '/^$/d'; }

# ─────────────────────────────────────────────────────────────────────────
# Checks: all before changing anything.
# ─────────────────────────────────────────────────────────────────────────

# Under sudo, $HOME would be root's: everything would be linked into
# /root, and the AUR helper refuses to run as root anyway.
[[ $EUID -ne 0 ]] || die "Run this as your user, not with sudo. It uses sudo itself."
command -v pacman >/dev/null || die "This is for Arch Linux (pacman not found)."
sudo -v || die "Your user needs sudo rights."

# ─────────────────────────────────────────────────────────────────────────
# 1. System files
# ─────────────────────────────────────────────────────────────────────────

step "Installing system files from system/etc"
# First, so pacman already uses the mirror list from the repo. Each file
# goes to the same place under /, e.g. system/etc/locale.gen → /etc/locale.gen.
# (The login screen's files in system/greeter are installed in step 8.)
while IFS= read -r -d '' file; do
  relative="${file#"$REPO/system/"}"
  sudo install -D -m 644 "$file" "/$relative"
  echo "  /$relative"
done < <(find "$REPO/system/etc" -type f -print0)

# locale.gen lists the languages; this builds them.
sudo locale-gen >/dev/null

# ─────────────────────────────────────────────────────────────────────────
# 2. Packages
# ─────────────────────────────────────────────────────────────────────────

step "Installing packages from the official repos"
lists=("$REPO/packages/base.txt" "$REPO/packages/desktop.txt")
# Intel processor: its microcode updates (packages/intel.txt).
if grep -q GenuineIntel /proc/cpuinfo; then
  lists+=("$REPO/packages/intel.txt")
fi

# -Syu: update the system first (installing into an outdated system can
# break it). --needed: skip what's already installed. "-": the package
# names come from stdin. No --noconfirm: pacman shows the list and asks
# once, and if a package conflicts with an installed one (e.g. pipewire
# replacing pulseaudio), you decide.
read_list "${lists[@]}" | sudo pacman -Syu --needed -

step "Installing the AUR helper (yay)"
if command -v yay >/dev/null; then
  echo "  already installed"
else
  # yay comes from the AUR itself, so the first time it's built by hand:
  # download its build recipe and let makepkg build and install it (-si).
  build_dir="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
  (cd "$build_dir/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$build_dir"
fi

step "Installing packages from the AUR"
# yay-bin is in the list too (so dotfiles-check knows it), but it's
# installed above already.
read_list "$REPO/packages/aur.txt" | grep -vx 'yay-bin' | yay -S --needed --noconfirm -

# ─────────────────────────────────────────────────────────────────────────
# 3. Extras that aren't packages
# ─────────────────────────────────────────────────────────────────────────

step "Installing the zsh prompt (powerlevel10k)"
# .zshrc loads it from here.
P10K_DIR="$HOME/.local/share/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then
  git -C "$P10K_DIR" pull --quiet --ff-only || note "Couldn't update powerlevel10k, keeping the current version."
else
  git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# ─────────────────────────────────────────────────────────────────────────
# 4. Configs
# ─────────────────────────────────────────────────────────────────────────

step "Moving files that are in the way to $BACKUP_DIR"
# stow refuses to replace real files (e.g. a ~/.zshrc a fresh install
# created). Every file of every package is checked: if something else is
# at its place in your home folder, it's moved to the backup. Already
# linked to the repo (directly, or through a linked folder) is fine:
# readlink -m follows all links, so both paths end at the same file.
moved=0
for package in "${STOW_PACKAGES[@]}"; do
  while IFS= read -r -d '' file; do
    relative="${file#"$REPO/$package/"}"
    target="$HOME/$relative"
    if [[ -e "$target" || -L "$target" ]] && [[ "$(readlink -m "$target")" != "$(readlink -m "$file")" ]]; then
      mkdir -p "$(dirname "$BACKUP_DIR/$relative")"
      mv "$target" "$BACKUP_DIR/$relative"
      echo "  ~/$relative"
      moved=$((moved + 1))
    fi
  done < <(find "$REPO/$package" \( -type f -o -type l \) -print0)
done
((moved > 0)) || echo "  nothing in the way"

step "Linking the configs into your home folder (stow)"
# Folders that must be real folders, not links into the repo. stow links a
# whole folder when it doesn't exist yet ("folding"): on a fresh install,
# ~/.local would become a link to bin/.local, and everything programs keep
# in ~/.local/share and ~/.local/state (the shell's state too) would land
# in the repo. Same for ~/Pictures: screenshots would end up in the repo.
# With these folders in place, stow links only what's inside them.
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.local/state" "$HOME/Pictures"
# --restow: unlink and link again, which also removes links to files that
# were deleted from the repo.
stow --restow --dir="$REPO" --target="$HOME" "${STOW_PACKAGES[@]}"

# ─────────────────────────────────────────────────────────────────────────
# 5. Look and feel
# ─────────────────────────────────────────────────────────────────────────

step "Setting the GTK theme, icons and cursor"
# GTK apps (and Firefox-based browsers) read these. color-scheme makes
# libadwaita apps dark; they ignore gtk-theme.
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

step "Making the first colors from the default wallpaper"
# On a fresh install, the color files (kitty, GTK, Qt, Hyprland borders)
# don't exist until you pick a wallpaper. matugen creates them from the
# default wallpaper now, with the same settings as the shell's Theme
# service. Picking another wallpaper replaces them.
if [[ -f "$HOME/.config/kitty/colors.conf" ]]; then
  echo "  already there"
elif [[ -f "$DEFAULT_WALLPAPER" ]]; then
  mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/qt6ct/colors"
  matugen image "$DEFAULT_WALLPAPER" -m dark -t scheme-tonal-spot --source-color-index 0 >/dev/null
else
  note "No $DEFAULT_WALLPAPER: skipped. Pick a wallpaper after logging in."
fi

# ─────────────────────────────────────────────────────────────────────────
# 6. Services
# ─────────────────────────────────────────────────────────────────────────

step "Enabling Bluetooth, power profiles and NetworkManager"
# --now: also start them right away, not only from the next boot.
sudo systemctl enable --now bluetooth.service power-profiles-daemon.service NetworkManager.service

# The shell is the polkit agent (the password dialog), and only one agent
# can run. hyprpolkitagent, if it's still installed, mustn't start.
if systemctl --user is-enabled hyprpolkitagent.service &>/dev/null; then
  systemctl --user disable --now hyprpolkitagent.service
  note "Disabled hyprpolkitagent: the shell is the password dialog now."
fi

# ─────────────────────────────────────────────────────────────────────────
# 7. Login shell
# ─────────────────────────────────────────────────────────────────────────

step "Making zsh your login shell"
# getent: your entry in the user database; its 7th field is the shell.
if [[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]]; then
  echo "  already zsh"
else
  chsh -s /usr/bin/zsh
fi

# ─────────────────────────────────────────────────────────────────────────
# 8. Login screen
# ─────────────────────────────────────────────────────────────────────────

# Has its own script (it's also run alone, after changing the shell code
# the login screen uses). It prints its own steps and the final note.
"$REPO/system/greeter/install.sh"

if ((moved > 0)); then
  note "Your own versions of $moved files are in $BACKUP_DIR."
fi
