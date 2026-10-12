hl.config({
    input = {
	kb_layout = "de",
    },
    misc = {
	disable_hyprland_logo = true,
	disable_splash_rendering = true,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("MYSHELL_GREETER=1 qs -p /etc/greetd/myshell/greeter.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)
