import QtQuick
import qs.config

Item {
    id: sep

    property int cols: 20

    readonly property int xL: Math.floor(Ascii.cw / 2) - 1
    readonly property int yT: Math.ceil(Ascii.ch / 2) - 1

    width: cols * Ascii.cw
    height: Ascii.ch

    Rectangle {
        x: sep.xL
        y: sep.yT
        width: (sep.cols - 1) * Ascii.cw - x
        height: 2
        color: Ascii.frame
    }
    Rectangle {
        x: (sep.cols - 1) * Ascii.cw
        y: sep.yT
        width: sep.xL + 2
        height: 2
        color: Ascii.shade
    }
}
