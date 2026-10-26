import QtQuick
import Quickshell
import qs.config

PopupWindow {
    id: root

    required property var barWindow

    property var item: null
    property var stack: []
    property real anchorX: 0
    property real anchorWidth: 0

    readonly property var currentMenu: stack.length > 0 ? stack[stack.length - 1] : (item?.menu ?? null)
    readonly property var entries: [...(opener.children?.values ?? [])]
    readonly property int headRows: stack.length > 0 ? 2 : 0
    readonly property int cols: Math.max(22, Math.min(48, 10 + Math.max(0, ...entries.map(e => label(e).length))))

    function label(entry) {
        return entry.isSeparator ? "" : entry.text.replace(/_(.)/g, "$1")
    }

    function mark(entry) {
        if (entry.buttonType === QsMenuButtonType.CheckBox)
            return entry.checkState === Qt.Checked ? "[x] " : "[ ] "
        if (entry.buttonType === QsMenuButtonType.RadioButton)
            return entry.checkState === Qt.Checked ? "(•) " : "( ) "
        return ""
    }

    function toggle(trayItem, icon) {
        if (visible && item === trayItem) {
            visible = false
            return
        }
        item = trayItem
        stack = []
        anchorX = icon.mapToItem(null, 0, 0).x
        anchorWidth = icon.width
        visible = true
        box.forceActiveFocus()
    }

    function run(entry) {
        if (entry.isSeparator || !entry.enabled)
            return
        if (entry.hasChildren) {
            stack = [...stack, entry]
            return
        }
        entry.triggered()
        visible = false
    }

    visible: false
    color: "transparent"
    grabFocus: true
    anchor.window: barWindow
    anchor.rect.x: anchorX
    anchor.rect.y: barWindow.height + 4
    anchor.rect.width: anchorWidth
    anchor.rect.height: 1
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    implicitWidth: box.width
    implicitHeight: box.height

    QsMenuOpener {
        id: opener
        menu: root.visible ? root.currentMenu : null
    }

    Box {
        id: box

        cols: root.cols
        rows: Math.max(1, root.headRows + root.entries.length) + 2
        title: root.item ? (root.item.tooltipTitle || root.item.title || root.item.id).toLowerCase() : ""
        focus: true
        Keys.onEscapePressed: root.visible = false

        Row {
            id: back

            x: Ascii.cw
            y: Ascii.ch
            visible: root.stack.length > 0

            readonly property bool lit: backMouse.containsMouse

            Rectangle {
                width: (root.cols - 2) * Ascii.cw
                height: Ascii.ch
                color: back.lit ? Ascii.acc : "transparent"

                AsciiText {
                    x: Ascii.cw
                    text: "◄ " + (root.stack.length > 0 ? root.label(root.stack[root.stack.length - 1]) : "")
                    color: back.lit ? Ascii.accText : Ascii.fg
                }

                MouseArea {
                    id: backMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.stack = root.stack.slice(0, -1)
                }
            }
        }

        Separator {
            y: 2 * Ascii.ch
            visible: root.stack.length > 0
            cols: root.cols
        }

        Repeater {
            model: root.entries

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool lit: mouse.containsMouse && modelData.enabled && !modelData.isSeparator

                x: Ascii.cw
                y: (1 + root.headRows + index) * Ascii.ch
                width: (root.cols - 2) * Ascii.cw
                height: Ascii.ch

                Separator {
                    x: -Ascii.cw
                    visible: row.modelData.isSeparator
                    cols: root.cols
                }

                Rectangle {
                    anchors.fill: parent
                    visible: row.lit
                    color: Ascii.acc
                }

                AsciiText {
                    x: Ascii.cw
                    width: parent.width - 4 * Ascii.cw
                    elide: Text.ElideRight
                    visible: !row.modelData.isSeparator
                    text: root.mark(row.modelData) + root.label(row.modelData)
                    color: row.lit ? Ascii.accText : row.modelData.enabled ? Ascii.fg : Ascii.dim
                }

                AsciiText {
                    x: parent.width - 2 * Ascii.cw
                    visible: row.modelData.hasChildren
                    text: "►"
                    color: row.lit ? Ascii.accText : Ascii.dim
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(row.modelData)
                }
            }
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: Ascii.ch
            visible: root.entries.length === 0
            text: "no menu"
            color: Ascii.dim
        }
    }
}
