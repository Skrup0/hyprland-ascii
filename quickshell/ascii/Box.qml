import QtQuick
import qs.config

Item {
    id: root

    property int cols: 20
    property int rows: 3
    property string title: ""
    property color frameColor: Ascii.frame
    property color titleColor: Ascii.acc

    readonly property string shownTitle: title.length > cols - 6 ? title.slice(0, Math.max(0, cols - 7)) + "…" : title

    width: cols * Ascii.cw
    height: rows * Ascii.ch

    Rectangle {
        anchors.fill: parent
        color: Ascii.bg
    }

    AsciiText {
        color: root.frameColor
        text: {
            const gap = root.shownTitle !== "" ? " ".repeat(root.shownTitle.length + 2) : ""
            const inner = Math.max(0, root.cols - 2)
            const top = "┌─" + gap + "─".repeat(Math.max(0, inner - 1 - gap.length)) + "┐"
            const mid = "│" + " ".repeat(inner) + "│"
            const bottom = "└" + "─".repeat(inner) + "┘"
            return [top, ...Array(Math.max(0, root.rows - 2)).fill(mid), bottom].join("\n")
        }
    }

    AsciiText {
        x: 3 * Ascii.cw
        visible: root.shownTitle !== ""
        color: root.titleColor
        text: root.shownTitle
    }
}
