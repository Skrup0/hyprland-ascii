import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services

PanelWindow {
    id: bar

    required property ShellScreen modelData

    readonly property var workspaces: [...Hyprland.workspaces.values]
        .filter(w => w.id > 0 && w.monitor?.name === bar.modelData.name)
        .sort((a, b) => a.id - b.id)
    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
        || battery.state === UPowerDeviceState.PendingCharge
        || battery.state === UPowerDeviceState.FullyCharged
    readonly property bool batteryLow: battery.percentage <= 0.15 && !charging
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var players: [...Mpris.players.values]
    readonly property var player: players.find(p => p.isPlaying)
        ?? players.find(p => p.playbackState === MprisPlaybackState.Paused)
        ?? null

    function cycle(step) {
        const i = workspaces.findIndex(w => w.active)
        workspaces[(i + step + workspaces.length) % workspaces.length]?.activate()
    }

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 2 * Ascii.ch
    exclusiveZone: implicitHeight
    readonly property int itemsHeight: Ascii.dialog
        ? implicitHeight - Ascii.ch / 2 + Math.ceil(Ascii.ch / 4) - 1 - margins.top
        : implicitHeight
    margins {
        top: 4
        left: Ascii.dialog ? 16 : 9
        right: Ascii.dialog ? 16 : 9
    }
    color: "transparent"
    WlrLayershell.namespace: "asciibar"

    SystemClock {
        id: time
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    AsciiTrayMenu {
        id: trayMenu
        barWindow: bar
    }

    AsciiPlayer {
        id: playerBox
        barWindow: bar
    }

    BorderImage {
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.config/hypr/borders/ascii-border-slim.png"
        border {
            left: Ascii.cw
            right: Ascii.cw
            top: Ascii.ch / 2
            bottom: Ascii.ch / 2
        }
        smooth: false
    }

    Row {
        x: Ascii.dialog ? 0 : 2 * Ascii.cw
        height: bar.itemsHeight
        spacing: 2 * Ascii.cw

        AsciiWindowMap {
            anchors.verticalCenter: parent.verticalCenter
            workspace: Hyprland.monitorFor(bar.modelData)?.activeWorkspace ?? null
        }

        Repeater {
            model: ScriptModel {
                values: bar.workspaces
            }

            delegate: AsciiText {
                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                text: modelData.name
                color: modelData.active ? Ascii.barFg : Ascii.barFrame
                font.bold: modelData.active

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: parent.modelData.activate()
                    onWheel: wheel => bar.cycle(wheel.angleDelta.y > 0 ? -1 : 1)
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Ascii.dialog ? 0 : 2 * Ascii.cw
        height: bar.itemsHeight
        spacing: 3 * Ascii.cw

        Repeater {
            model: SystemTray.items

            delegate: IconImage {
                id: trayIcon

                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: {
                    const icon = modelData.icon
                    if (!icon.includes("?path=")) return icon
                    const [name, path] = icon.split("?path=")
                    return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const item = trayIcon.modelData
                        if (mouse.button === Qt.MiddleButton)
                            item.secondaryActivate()
                        else if (mouse.button === Qt.LeftButton && !item.onlyMenu)
                            item.activate()
                        else if (item.hasMenu)
                            trayMenu.toggle(item, trayIcon)
                    }
                    onWheel: wheel => trayIcon.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }

        Alert {
            visible: SysStats.cpu >= 0.9
            label: "cpu "
            value: Math.round(SysStats.cpu * 100) + "%"
            valueColor: Ascii.barRed
        }

        Alert {
            visible: SysStats.temp >= 80
            label: "tmp "
            value: Math.round(SysStats.temp) + "°"
            valueColor: Ascii.barRed
        }

        Alert {
            visible: Notifs.count > 0 || Notifs.dnd
            label: Notifs.dnd ? "dnd " : "msg "
            value: Notifs.count
            valueColor: Ascii.barAcc

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : Notifs.historyRequested()
            }
        }

        Alert {
            id: nowPlaying

            visible: bar.player !== null
            label: bar.player?.isPlaying ? "\uf001 " : "\uf04c "
            value: {
                const t = (bar.player?.trackTitle || bar.player?.identity || "").toLowerCase()
                return t.length > 24 ? t.slice(0, 23) + "…" : t
            }
            labelColor: bar.player?.isPlaying ? Ascii.barDim : Ascii.barFrame
            valueColor: playerBox.visible ? Ascii.barAcc : labelColor

            MouseArea {
                anchors.fill: parent
                onClicked: playerBox.toggle(bar.player, nowPlaying)
            }
        }

        Alert {
            visible: bar.audio !== null
            label: "vol "
            value: bar.audio?.muted ? "mute" : Math.round((bar.audio?.volume ?? 0) * 100) + "%"
            valueColor: Ascii.barDim

            MouseArea {
                anchors.fill: parent
                onClicked: bar.audio.muted = !bar.audio.muted
                onWheel: wheel => bar.audio.volume = Math.max(0, Math.min(1.5, bar.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
            }
        }

        AsciiText {
            anchors.verticalCenter: parent.verticalCenter
            visible: bar.battery.ready && bar.battery.isLaptopBattery
            text: Math.round(bar.battery.percentage * 100) + "%" + (bar.charging ? "+" : "")
            color: bar.batteryLow ? Ascii.barRed : Ascii.barDim
        }

        AsciiText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(time.date, clockHover.hovered ? "ddd d MMM  h:mm ap" : "h:mm ap").toLowerCase()
            color: Ascii.barFg

            HoverHandler {
                id: clockHover
            }
        }
    }

    component Alert: Item {
        id: alert

        property string label
        property string value
        property color labelColor: Ascii.barDim
        property color valueColor: Ascii.barFg

        anchors.verticalCenter: parent?.verticalCenter
        implicitWidth: alertRow.implicitWidth
        implicitHeight: alertRow.implicitHeight

        Row {
            id: alertRow

            AsciiText {
                text: alert.label
                color: alert.labelColor
            }

            AsciiText {
                text: alert.value
                color: alert.valueColor
            }
        }
    }
}
