pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg: "#aaaaaa"
    readonly property color fg: "#000000"
    readonly property color bright: "#000000"
    readonly property color dim: "#555555"
    readonly property color frame: "#ffffff"
    readonly property color line: "#8a8a8a"
    readonly property color acc: "#0000aa"
    readonly property color red: "#aa0000"
    readonly property color mint: "#005f00"
    readonly property color accText: "#ffffff"
    readonly property color accKey: "#ffff55"

    readonly property bool dialog: true
    readonly property color shade: "#000000"

    readonly property color barFg: "#ffffff"
    readonly property color barDim: "#55ffff"
    readonly property color barFrame: "#00aaaa"
    readonly property color barAcc: "#ffff55"
    readonly property color barRed: "#ff5555"
    readonly property color barMint: "#55ff55"
    readonly property color barBg: "#0000aa"

    readonly property string family: "Terminus"
    readonly property string style: "Bold"
    readonly property int pixelSize: 14
    readonly property int cw: 8
    readonly property int ch: 14

    function filled(level, cells) {
        return Math.max(0, Math.min(cells, Math.round(level * cells)))
    }
}
