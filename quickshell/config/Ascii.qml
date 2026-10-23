pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg: "#101010"
    readonly property color fg: "#ffffff"
    readonly property color bright: "#ffffff"
    readonly property color dim: "#707070"
    readonly property color frame: "#505050"
    readonly property color line: "#282828"
    readonly property color acc: "#ffc799"
    readonly property color red: "#ff8080"
    readonly property color mint: "#99ffe4"

    readonly property string family: "JetBrainsMono NFM"
    readonly property int pixelSize: 15
    readonly property int cw: 9
    readonly property int ch: 18

    function filled(level, cells) {
        return Math.max(0, Math.min(cells, Math.round(level * cells)))
    }

    function spark(values) {
        return values.map(v => "▁▂▃▄▅▆▇█"[Math.max(0, Math.min(7, Math.floor(v * 8)))]).join("")
    }

    readonly property var digitFont: ({
        "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
        "8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
        ":": ["0", "1", "0", "1", "0"]
    })

    function bigText(s) {
        const rows = []
        for (let r = 0; r < 5; r++)
            rows.push([...s].map(c => (digitFont[c] ?? ["000", "000", "000", "000", "000"])[r]
                .replace(/1/g, "██").replace(/0/g, "  ")).join("  "))
        return rows.join("\n")
    }
}
