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
    readonly property int titleCol: Ascii.dialog ? Math.floor((cols - shownTitle.length - 2) / 2) + 1 : 3

    width: (cols + (Ascii.dialog ? 2 : 0)) * Ascii.cw
    height: (rows + (Ascii.dialog ? 1 : 0)) * Ascii.ch

    Rectangle {
        visible: Ascii.dialog
        x: 2 * Ascii.cw
        y: Ascii.ch
        width: root.cols * Ascii.cw
        height: root.rows * Ascii.ch
        color: "#000000"
    }

    Rectangle {
        width: root.cols * Ascii.cw
        height: root.rows * Ascii.ch
        color: Ascii.bg
    }

    Frame {
        cols: root.cols
        rows: root.rows
        tl: root.frameColor
        br: Ascii.dialog ? Ascii.shade : root.frameColor
        gapCol: root.titleCol - 1
        gapLen: root.shownTitle !== "" ? root.shownTitle.length + 2 : 0
    }

    AsciiText {
        x: root.titleCol * Ascii.cw
        visible: root.shownTitle !== ""
        color: root.titleColor
        text: root.shownTitle
    }
}
