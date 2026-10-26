pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    function target(window) {
        return `address:0x${window.address}`
    }

    function lua(name, window, args) {
        const fields = [`window = "${root.target(window)}"`]
        for (const [key, value] of Object.entries(args ?? {}))
            fields.push(`${key} = ${JSON.stringify(value)}`)
        Hyprland.dispatch(`hl.dsp.${name}({ ${fields.join(", ")} })`)
    }

    function focus(window) {
        if (!window) return
        if (Hyprland.usingLua)
            root.lua("focus", window)
        else
            Hyprland.dispatch(`focuswindow ${root.target(window)}`)
    }
}
