import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    readonly property int cols: 64
    readonly property int listRows: 11
    readonly property int menuRows: listRows + 5

    readonly property var session: [
        { name: "log off", command: ["hyprctl", "dispatch", Hyprland.usingLua ? "hl.dsp.exit()" : "exit"], confirm: true },
        { name: "suspend", command: ["loginctl", "suspend"], confirm: false },
        { name: "restart", command: ["loginctl", "reboot"], confirm: true },
        { name: "shut down", command: ["loginctl", "poweroff"], confirm: true }
    ]
    readonly property var quick: ["Do not disturb", "Clipboard history", "Session"]

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

    property string page: "apps"
    readonly property var shown: page === "session" ? session : results
    readonly property int count: shown.length + (page === "apps" ? quick.length : 0)
    property int sel: 0
    property int btn: 0
    property string armed: ""

    onSelChanged: list.currentIndex = sel < shown.length ? sel : -1
    onShownChanged: list.currentIndex = sel < shown.length ? sel : -1

    function toggle(screenName) {
        if (visible) {
            visible = false
            return
        }
        screen = [...Quickshell.screens].find(s => s.name === screenName) ?? Quickshell.screens[0]
        input.text = ""
        page = "apps"
        sel = 0
        btn = 0
        armed = ""
        visible = true
        input.forceActiveFocus()
    }

    function move(by) {
        sel = sel < 0 ? (by > 0 ? 0 : count - 1) : (sel + by + count) % count
    }

    function activate() {
        if (btn === 1)
            return back()
        if (page === "apps" && sel >= shown.length) {
            if (quick[sel - shown.length] === "Do not disturb") {
                Notifs.dnd = !Notifs.dnd
            } else if (quick[sel - shown.length] === "Session") {
                page = "session"
                sel = 0
                armed = ""
            } else {
                visible = false
                Quickshell.execDetached(["qs", "ipc", "call", "clipboard", "toggle"])
            }
            return
        }
        run(sel >= 0 ? shown[sel] : null)
    }

    function back() {
        if (page === "session") {
            page = "apps"
            sel = results.length + quick.indexOf("Session")
            btn = 0
            armed = ""
        } else {
            visible = false
        }
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

    function label(item) {
        const name = root.armed === item.name ? "sure? press again" : item.name
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    visible: false
    anchors {
        top: true
        left: true
    }
    margins {
        top: Math.round(((screen?.height ?? 0) - box.height) / 2)
        left: Math.round(((screen?.width ?? 0) - box.width) / 2)
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "asciibar-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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

    component Inset: Frame {
        tl: Ascii.shade
        br: Ascii.frame
    }

    component Entry: Item {
        id: entry

        property string name: ""
        property string suffix: ""
        property string mark: ""
        property string note: ""
        property bool current: false
        property bool hotkey: true

        readonly property string shownName: name.length > 28 ? name.slice(0, 27) + "…" : name

        width: (root.cols - 6) * Ascii.cw
        height: Ascii.ch

        Rectangle {
            x: 3 * Ascii.cw
            width: (4 + entry.shownName.length + entry.suffix.length) * Ascii.cw
            height: Ascii.ch
            visible: entry.current
            color: Ascii.acc
        }
        AsciiText {
            x: 3 * Ascii.cw
            text: entry.mark
            color: entry.current ? Ascii.accText : Ascii.fg
            font.bold: entry.current
        }
        AsciiText {
            x: 7 * Ascii.cw
            text: (entry.hotkey ? " " + entry.shownName.slice(1) : entry.shownName) + entry.suffix
            color: entry.current ? Ascii.accText : Ascii.fg
            font.bold: entry.current
        }
        AsciiText {
            x: 7 * Ascii.cw
            visible: entry.hotkey
            text: entry.shownName.charAt(0)
            color: entry.current ? Ascii.accKey : Ascii.red
            font.bold: true
        }
        AsciiText {
            x: 37 * Ascii.cw
            width: 19 * Ascii.cw
            elide: Text.ElideRight
            text: entry.note
            color: Ascii.dim
        }
    }

    component Button: Item {
        id: button

        property string text: ""
        property int which: 0

        readonly property bool on: root.btn === which
        readonly property string core: text.replace(/^ +/, "")
        readonly property int lead: text.length - core.length

        width: (text.length + 2) * Ascii.cw
        height: Ascii.ch

        Rectangle {
            anchors.fill: parent
            visible: button.on
            color: Ascii.acc
        }
        AsciiText {
            text: "<" + " ".repeat(button.lead + 1) + button.core.slice(1) + ">"
            color: button.on ? Ascii.accText : Ascii.fg
            font.bold: true
        }
        AsciiText {
            x: (1 + button.lead) * Ascii.cw
            text: button.core.charAt(0)
            color: button.on ? Ascii.accKey : Ascii.red
            font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.btn = button.which
            onClicked: {
                root.btn = button.which
                root.activate()
            }
        }
    }

    Box {
        id: box

        cols: root.cols
        rows: root.menuRows + 9
        title: root.page === "session" ? "Session" : "Launcher"

        Inset {
            x: 2 * Ascii.cw
            y: Ascii.ch
            cols: root.cols - 4
            rows: 3
        }

        AsciiText {
            x: 4 * Ascii.cw
            y: 2 * Ascii.ch
            text: ">"
            color: Ascii.acc
            font.bold: true
        }

        TextInput {
            id: input

            x: 6 * Ascii.cw
            y: 2 * Ascii.ch
            width: (root.cols - 10) * Ascii.cw
            height: Ascii.ch
            verticalAlignment: TextInput.AlignVCenter
            color: Ascii.fg
            selectionColor: Ascii.acc
            selectedTextColor: Ascii.accText
            font.family: Ascii.family
            font.styleName: Ascii.style
            font.pixelSize: Ascii.pixelSize
            clip: true
            cursorDelegate: Rectangle {
                width: Ascii.cw
                height: Ascii.ch
                color: Ascii.acc
                visible: input.cursorVisible
            }
            onTextChanged: {
                root.page = "apps"
                root.armed = ""
                root.btn = 0
                root.sel = root.results.length || text.trim() === "" ? 0 : -1
            }

            Keys.onEscapePressed: root.back()
            Keys.onUpPressed: root.move(-1)
            Keys.onDownPressed: root.move(1)
            Keys.onTabPressed: root.btn = 1 - root.btn
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                    root.sel = event.key === Qt.Key_Home ? 0 : root.count - 1
                    event.accepted = true
                }
            }
            Keys.onReturnPressed: root.activate()
            Keys.onEnterPressed: root.activate()
        }

        Inset {
            x: 2 * Ascii.cw
            y: 4 * Ascii.ch
            cols: root.cols - 4
            rows: root.menuRows + 2
        }

        ListView {
            id: list

            x: 3 * Ascii.cw
            y: 5 * Ascii.ch
            width: (root.cols - 6) * Ascii.cw
            height: (root.page === "session" ? root.menuRows : root.listRows) * Ascii.ch
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            model: root.shown

            delegate: Entry {
                required property var modelData
                required property int index

                name: modelData.command && !modelData.execute ? root.label(modelData) : modelData.name
                note: modelData.genericName ?? ""
                current: index === root.sel

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        root.sel = parent.index
                        root.btn = 0
                    }
                    onClicked: {
                        root.btn = 0
                        root.activate()
                    }
                }
            }
        }

        AsciiText {
            x: 10 * Ascii.cw
            y: 5 * Ascii.ch
            visible: list.count === 0
            text: input.text.trim() === "" ? "" : "Enter runs: " + input.text.trim()
            color: Ascii.dim
            width: (root.cols - 12) * Ascii.cw
            elide: Text.ElideRight
        }

        Column {
            x: 3 * Ascii.cw
            y: (6 + root.listRows) * Ascii.ch
            visible: root.page === "apps"

            Entry {
                name: "*** Quick settings ***"
                hotkey: false
            }

            Repeater {
                model: root.quick

                delegate: Entry {
                    required property string modelData
                    required property int index

                    readonly property int at: root.shown.length + index

                    readonly property bool toggle: modelData === "Do not disturb"

                    name: modelData
                    suffix: toggle ? "" : "  --->"
                    mark: toggle ? (Notifs.dnd ? "[*]" : "[ ]") : ""
                    current: root.sel === at

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            root.sel = parent.at
                            root.btn = 0
                        }
                        onClicked: {
                            root.btn = 0
                            root.activate()
                        }
                    }
                }
            }
        }

        Separator {
            y: (root.menuRows + 6) * Ascii.ch
            cols: root.cols
        }

        Row {
            x: Math.floor((root.cols - 21) / 2) * Ascii.cw
            y: (root.menuRows + 7) * Ascii.ch
            spacing: 5 * Ascii.cw

            Button {
                text: "Select"
                which: 0
            }
            Button {
                text: " Exit "
                which: 1
            }
        }
    }
}
