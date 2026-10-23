import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    readonly property int cols: 44
    readonly property int listRows: 14

    readonly property var session: [
        { name: "log off", command: ["hyprctl", "dispatch", Hyprland.usingLua ? "hl.dsp.exit()" : "exit"], confirm: true },
        { name: "suspend", command: ["loginctl", "suspend"], confirm: false },
        { name: "restart", command: ["loginctl", "reboot"], confirm: true },
        { name: "shut down", command: ["loginctl", "poweroff"], confirm: true }
    ]

    readonly property var apps: [...DesktopEntries.applications.values]
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var results: {
        const q = input.text.trim().toLowerCase()
        if (q === "") return apps
        const matches = apps.filter(a =>
            [a.name, a.genericName, a.comment, ...a.keywords].join(" ").toLowerCase().includes(q))
        return matches.sort((a, b) =>
            (b.name.toLowerCase().startsWith(q) - a.name.toLowerCase().startsWith(q)) || a.name.localeCompare(b.name))
            .concat(session.filter(s => s.name.includes(q)))
    }

    property string armed: ""

    function toggle(screenName) {
        if (visible) {
            visible = false
            return
        }
        screen = [...Quickshell.screens].find(s => s.name === screenName) ?? Quickshell.screens[0]
        input.text = ""
        list.currentIndex = 0
        armed = ""
        visible = true
        input.forceActiveFocus()
    }

    function run(item) {
        if (item && item.command && !item.execute) {
            if (item.confirm && armed !== item.name) {
                armed = item.name
                disarm.restart()
                return
            }
            Quickshell.execDetached(item.command)
        } else if (item) {
            if (item.runInTerminal)
                Quickshell.execDetached(["foot", "-e", ...item.command])
            else
                item.execute()
        } else if (input.text.trim() !== "") {
            Quickshell.execDetached(["sh", "-c", input.text])
        }
        visible = false
    }

    visible: false
    anchors {
        top: true
        left: true
    }
    margins {
        top: 4
        left: 9
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "asciibar-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    implicitWidth: box.width
    implicitHeight: box.height

    Connections {
        target: Popups
        function onStartMenuRequested(screenName) { root.toggle(screenName) }
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Box {
        id: box

        cols: root.cols
        rows: root.listRows + 6
        title: "run"

        AsciiText {
            x: 2 * Ascii.cw
            y: Ascii.ch
            text: ">"
            color: Ascii.acc
        }

        TextInput {
            id: input

            x: 4 * Ascii.cw
            y: Ascii.ch
            width: (root.cols - 6) * Ascii.cw
            height: Ascii.ch
            verticalAlignment: TextInput.AlignVCenter
            color: Ascii.fg
            selectionColor: Ascii.acc
            selectedTextColor: Ascii.bg
            font.family: Ascii.family
            font.pixelSize: Ascii.pixelSize
            clip: true
            onTextChanged: {
                list.currentIndex = 0
                root.armed = ""
            }

            Keys.onEscapePressed: root.visible = false
            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
            Keys.onReturnPressed: root.run(root.results[list.currentIndex])
            Keys.onEnterPressed: root.run(root.results[list.currentIndex])
        }

        Repeater {
            model: [2, root.listRows + 3]

            delegate: AsciiText {
                required property int modelData

                y: modelData * Ascii.ch
                text: "├" + "─".repeat(root.cols - 2) + "┤"
                color: Ascii.frame
            }
        }

        ListView {
            id: list

            x: Ascii.cw
            y: 3 * Ascii.ch
            width: (root.cols - 2) * Ascii.cw
            height: root.listRows * Ascii.ch
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            model: root.results

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool current: ListView.isCurrentItem
                readonly property bool sessionEntry: !!modelData.command && !modelData.execute

                width: list.width
                height: Ascii.ch

                Rectangle {
                    anchors.fill: parent
                    visible: row.current
                    color: Ascii.acc
                }

                AsciiText {
                    x: Ascii.cw
                    width: parent.width - 2 * Ascii.cw
                    elide: Text.ElideRight
                    text: (row.current ? "▸ " : "  ")
                        + (root.armed === row.modelData.name ? "sure? press again" : row.modelData.name)
                    color: row.current ? Ascii.bg : row.sessionEntry ? Ascii.red : Ascii.fg
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: list.currentIndex = row.index
                    onClicked: root.run(row.modelData)
                }
            }
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: 3 * Ascii.ch
            visible: list.count === 0
            text: input.text.trim() === "" ? "" : "enter runs: " + input.text.trim()
            color: Ascii.dim
            width: (root.cols - 4) * Ascii.cw
            elide: Text.ElideRight
        }

        Row {
            x: 2 * Ascii.cw
            y: (root.listRows + 4) * Ascii.ch
            spacing: 2 * Ascii.cw

            Repeater {
                model: root.session

                delegate: AsciiText {
                    required property var modelData

                    text: root.armed === modelData.name ? "sure?" : modelData.name
                    color: root.armed === modelData.name ? Ascii.red : Ascii.dim

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Ascii.acc
                        onExited: parent.color = Qt.binding(() => root.armed === parent.modelData.name ? Ascii.red : Ascii.dim)
                        onClicked: root.run(parent.modelData)
                    }
                }
            }
        }
    }
}
