pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpu: 0
    property real temp: NaN

    property var lastCpu: null

    function parseStat(text) {
        const lines = text.split("\n")
        const fields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number)
        const idle = fields[3] + fields[4]
        const total = fields.reduce((a, b) => a + b, 0)
        if (lastCpu && total > lastCpu.total)
            cpu = Math.min(1, Math.max(0, 1 - (idle - lastCpu.idle) / (total - lastCpu.total)))
        lastCpu = { idle, total }
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            stat.reload()
            sensors.running = true
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    Process {
        id: sensors
        command: ["sensors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const chips = JSON.parse(text || "{}")
                const cpu = Object.keys(chips).find(name => /^(k10temp|coretemp|zenpower)-/.test(name))
                const sensor = cpu ? Object.values(chips[cpu]).find(v => typeof v === "object") : {}
                root.temp = Object.entries(sensor).find(([key]) => key.endsWith("_input"))?.[1] ?? NaN
            }
        }
    }
}
