import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root

    readonly property int cols: 64
    readonly property int listRows: 14
    readonly property int previewCols: 34
    readonly property string tmp: Quickshell.env("XDG_RUNTIME_DIR") + "/asciiclip-"

    property var entries: []

    readonly property var results: {
        const q = input.text.trim().toLowerCase()
        return q === "" ? entries : entries.filter(e => e.text.toLowerCase().includes(q))
    }
    readonly property var current: results[list.currentIndex] ?? null

    function toggle() {
        if (visible) {
            visible = false
            return
        }
        screen = [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        entries = []
        input.text = ""
        lister.running = true
        visible = true
        input.forceActiveFocus()
    }

    function parse(text) {
        return text.split("\n").filter(l => l.includes("\t")).map(line => {
            const tab = line.indexOf("\t")
            const body = line.slice(tab + 1)
            const m = body.match(/^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/)
            return {
                id: line.slice(0, tab),
                text: m ? `[image ${m[3]}×${m[4]} ${m[2]}]` : body,
                image: m ? { size: m[1], type: m[2], w: m[3], h: m[4] } : null,
                colour: /^#[0-9a-fA-F]{6}$/.test(body.trim()) ? body.trim() : ""
            }
        })
    }

    function copy(entry) {
        if (!entry)
            return
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id])
        visible = false
    }

    function remove(entry) {
        if (!entry)
            return
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "sh", entry.id])
        const i = list.currentIndex
        entries = entries.filter(e => e.id !== entry.id)
        list.currentIndex = Math.min(i, results.length - 1)
    }

    visible: false
    onVisibleChanged: if (!visible) Quickshell.execDetached(["sh", "-c", 'rm -f "$1"*', "sh", tmp])
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
    WlrLayershell.namespace: "asciibar-clipboard"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: box.width + 2 * Ascii.cw + preview.width
    implicitHeight: box.height

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle()
        }
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    Process {
        id: lister

        command: ["sh", "-c", `l=$(cliphist list)
            printf '%s\\n' "$l" | while IFS="$(printf '\\t')" read -r id body; do
                case $body in "[[ binary data"*) cliphist decode "$id" > "$1$id" ;; esac
            done
            printf '%s\\n' "$l"`, "sh", root.tmp]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text)
                list.currentIndex = 0
            }
        }
    }

    Box {
        id: box

        cols: root.cols
        rows: root.listRows + 6
        title: "clipboard"

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
            width: (root.cols - 18) * Ascii.cw
            height: Ascii.ch
            verticalAlignment: TextInput.AlignVCenter
            color: Ascii.fg
            selectionColor: Ascii.acc
            selectedTextColor: Ascii.accText
            font.family: Ascii.family
            font.styleName: Ascii.style
            font.pixelSize: Ascii.pixelSize
            clip: true
            onTextChanged: list.currentIndex = 0

            Keys.onEscapePressed: root.visible = false
            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
            Keys.onReturnPressed: root.copy(root.current)
            Keys.onEnterPressed: root.copy(root.current)
            Keys.onDeletePressed: root.remove(root.current)
        }

        AsciiText {
            x: (root.cols - 2) * Ascii.cw - width
            y: Ascii.ch
            text: root.results.length + " of " + root.entries.length
            color: Ascii.dim
        }

        Repeater {
            model: [2, root.listRows + 3]

            delegate: Separator {
                required property int modelData

                y: modelData * Ascii.ch
                cols: root.cols
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
                    text: (row.current ? "▸ " : "  ") + String(row.index + 1).padStart(2) + "  "
                        + (row.modelData.colour ? "   " : "") + row.modelData.text
                    color: row.current ? Ascii.accText : Ascii.fg
                }

                AsciiText {
                    x: 7 * Ascii.cw
                    visible: row.modelData.colour !== ""
                    text: "██"
                    color: row.modelData.colour || Ascii.fg
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: list.currentIndex = row.index
                    onClicked: mouse => mouse.button === Qt.RightButton ? root.remove(row.modelData) : root.copy(row.modelData)
                }
            }
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: 3 * Ascii.ch
            visible: list.count === 0
            text: root.entries.length === 0 ? "nothing copied yet" : "no match"
            color: Ascii.dim
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: (root.listRows + 4) * Ascii.ch
            text: "enter copy · del remove · type to filter"
            color: Ascii.dim
        }
    }

    Box {
        id: preview

        x: box.width + 2 * Ascii.cw
        visible: root.current?.image ?? false
        cols: root.previewCols
        rows: 13
        title: root.current?.image ? `${root.current.image.w}×${root.current.image.h} ${root.current.image.type}` : ""

        Image {
            x: 2 * Ascii.cw
            y: Ascii.ch
            width: (root.previewCols - 4) * Ascii.cw
            height: 10 * Ascii.ch
            source: root.current?.image ? "file://" + root.tmp + root.current.id : ""
            sourceSize.width: 2 * width
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            asynchronous: true
            cache: false
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: 11 * Ascii.ch
            text: root.current?.image?.size ?? ""
            color: Ascii.dim
        }
    }
}
