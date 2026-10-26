import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

Rectangle {
    id: map

    required property var workspace

    readonly property var monitor: workspace?.monitor ?? null
    readonly property var windows: [...Hyprland.toplevels.values]
        .filter(t => t.workspace === workspace && t.lastIpcObject.at && !t.lastIpcObject.hidden)
        .sort((a, b) => a.lastIpcObject.floating - b.lastIpcObject.floating || a.activated - b.activated)
    readonly property real ratio: monitor ? 13 / (monitor.height / monitor.scale) : 0
    readonly property real x0: Math.min(monitor?.x ?? 0, ...windows.map(t => t.lastIpcObject.at[0]))
    readonly property real x1: Math.max(monitor ? monitor.x + monitor.width / monitor.scale : 0,
        ...windows.map(t => t.lastIpcObject.at[0] + t.lastIpcObject.size[0]))

    implicitWidth: Math.round((x1 - x0) * ratio) + 3
    implicitHeight: 16
    color: "transparent"
    border.color: Ascii.barFrame

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland

        function onRawEvent() {
            Hyprland.refreshToplevels()
        }
    }

    Item {
        x: 2
        y: 2
        width: parent.width - 3
        height: parent.height - 3
        clip: true

        Repeater {
            model: ScriptModel {
                values: map.windows
            }

            delegate: Rectangle {
                required property var modelData
                readonly property var at: modelData.lastIpcObject.at
                readonly property var size: modelData.lastIpcObject.size

                x: Math.round((at[0] - map.x0) * map.ratio)
                y: Math.round((at[1] - map.monitor.y) * map.ratio)
                width: Math.max(1, Math.round((at[0] + size[0] - map.x0) * map.ratio) - x - 1)
                height: Math.max(1, Math.round((at[1] + size[1] - map.monitor.y) * map.ratio) - y - 1)
                color: Ascii.barBg
                border.color: modelData.activated ? Ascii.barAcc : Ascii.barDim
            }
        }
    }
}
