import QtQuick
import qs.config

Item {
    id: frame

    property int cols: 10
    property int rows: 3
    property color tl: Ascii.frame
    property color br: Ascii.frame
    property int gapCol: 0
    property int gapLen: 0

    readonly property int xL: Math.floor(Ascii.cw / 2) - 1
    readonly property int xR: (cols - 1) * Ascii.cw + xL
    readonly property int yT: Math.ceil(Ascii.ch / 2) - 1
    readonly property int yB: (rows - 1) * Ascii.ch + yT

    width: cols * Ascii.cw
    height: rows * Ascii.ch

    Rectangle {
        x: frame.xL
        y: frame.yT
        width: (frame.gapLen > 0 ? frame.gapCol * Ascii.cw : (frame.cols - 1) * Ascii.cw) - x
        height: 2
        color: frame.tl
    }
    Rectangle {
        visible: frame.gapLen > 0
        x: (frame.gapCol + frame.gapLen) * Ascii.cw
        y: frame.yT
        width: (frame.cols - 1) * Ascii.cw - x
        height: 2
        color: frame.tl
    }
    Rectangle {
        x: (frame.cols - 1) * Ascii.cw
        y: frame.yT
        width: frame.xR + 2 - x
        height: 2
        color: frame.br
    }
    Rectangle {
        x: frame.xL
        y: frame.yB
        width: Ascii.cw - x
        height: 2
        color: frame.tl
    }
    Rectangle {
        x: Ascii.cw
        y: frame.yB
        width: frame.xR + 2 - x
        height: 2
        color: frame.br
    }
    Rectangle {
        x: frame.xL
        y: frame.yT
        width: 2
        height: frame.yB + 2 - y
        color: frame.tl
    }
    Rectangle {
        x: frame.xR
        y: frame.yT
        width: 2
        height: frame.yB + 2 - y
        color: frame.br
    }
}
