import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.ascii
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: AsciiBar {}
    }

    AsciiToasts {}

    AsciiOsd {}

    AsciiLauncher {}

    AsciiHistory {}

    AsciiClipboard {}

    IpcHandler {
        target: "startmenu"

        function toggle(): void {
            Popups.startMenuRequested(Hyprland.focusedMonitor?.name ?? "")
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            Notifs.dnd = !Notifs.dnd
        }

        function clear(): void {
            Notifs.clear()
        }

        function history(): void {
            Notifs.historyRequested()
        }
    }
}
