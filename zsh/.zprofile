if [ "$(tty)" = /dev/tty1 ] && uwsm check may-start; then
    exec uwsm start hyprland-uwsm.desktop
fi

export PATH="$HOME/.local/bin:$PATH"
