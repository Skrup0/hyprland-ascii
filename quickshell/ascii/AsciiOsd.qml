import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.config

Scope {
    id: root

    readonly property var screen: [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null

    property string label: "volume"
    property int level: 0

    readonly property int meterCells: 28
    readonly property int full: Ascii.filled(Math.max(0, level) / 100, meterCells)

    function show(label, level) {
        root.label = label
        root.level = level
        meterWin.visible = true
        meterTimer.restart()
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Timer {
        id: settle
        interval: 2000
        running: true
    }

    Connections {
        target: root
        function onSinkChanged() { settle.restart() }
    }

    Connections {
        target: root.audio
        enabled: !settle.running

        function onVolumeChanged() {
            if (!root.audio.muted) root.show("volume", Math.round(root.audio.volume * 100))
        }
        function onMutedChanged() {
            root.show(root.audio.muted ? "muted" : "volume", root.audio.muted ? -1 : Math.round(root.audio.volume * 100))
        }
    }

    Process {
        id: backlight
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: root.show("brightness", parseInt(text.split(",")[3]))
        }
    }

    IpcHandler {
        target: "osd"

        function brightness(): void {
            backlight.running = true
        }
    }

    Timer { id: meterTimer; interval: 1500; onTriggered: meterWin.visible = false }

    PanelWindow {
        id: meterWin

        visible: false
        screen: root.screen
        anchors.bottom: true
        margins.bottom: 72
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "asciibar-osd"
        implicitWidth: meterBox.width
        implicitHeight: meterBox.height

        Box {
            id: meterBox

            cols: 40
            rows: 3
            title: root.label

            AsciiText {
                x: 2 * Ascii.cw
                y: Ascii.ch
                text: "█".repeat(root.full)
                color: Ascii.acc
            }

            AsciiText {
                x: (2 + root.full) * Ascii.cw
                y: Ascii.ch
                text: "░".repeat(root.meterCells - root.full)
                color: Ascii.dim
            }

            AsciiText {
                x: (3 + root.meterCells) * Ascii.cw
                y: Ascii.ch
                text: root.level < 0 ? "  off" : (String(root.level) + "%").padStart(5)
            }
        }
    }
}
