import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config

PopupWindow {
    id: root

    required property var barWindow

    property var player: null
    property real anchorX: 0
    property real anchorWidth: 0

    readonly property int cols: 40
    readonly property int lineCells: cols - 16
    readonly property bool timed: !!player && player.positionSupported && player.lengthSupported && player.length > 0
    readonly property int done: timed ? Math.round(Math.min(1, player.position / player.length) * (lineCells - 1)) : 0
    readonly property bool gone: !player || ![...Mpris.players.values].includes(player)
        || player.playbackState === MprisPlaybackState.Stopped

    onGoneChanged: if (gone) visible = false

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    function toggle(mprisPlayer, label) {
        if (visible) {
            visible = false
            return
        }
        player = mprisPlayer
        anchorX = label.mapToItem(null, 0, 0).x
        anchorWidth = label.width
        visible = true
        box.forceActiveFocus()
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

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    Box {
        id: box

        cols: root.cols
        rows: 8
        title: (root.player?.identity ?? "").toLowerCase().replace(/^mozilla /, "")
        focus: true
        Keys.onEscapePressed: root.visible = false
        Keys.onSpacePressed: root.player?.togglePlaying()

        AsciiText {
            x: 2 * Ascii.cw
            y: Ascii.ch
            width: (root.cols - 4) * Ascii.cw
            elide: Text.ElideRight
            text: root.player?.trackTitle || "untitled"
            color: Ascii.bright
            font.bold: true
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: 2 * Ascii.ch
            width: (root.cols - 4) * Ascii.cw
            elide: Text.ElideRight
            text: root.player?.trackArtist ?? ""
            color: Ascii.dim
        }

        Row {
            x: 2 * Ascii.cw
            y: 4 * Ascii.ch
            visible: root.timed

            AsciiText {
                text: root.clock(root.player?.position ?? 0).padStart(5) + " "
                color: Ascii.dim
            }

            Item {
                width: root.lineCells * Ascii.cw
                height: Ascii.ch

                Row {
                    AsciiText {
                        text: "━".repeat(root.done) + "●"
                        color: Ascii.acc
                    }

                    AsciiText {
                        text: "─".repeat(root.lineCells - 1 - root.done)
                        color: Ascii.line
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canSeek ?? false
                    onClicked: mouse => root.player.position = mouse.x / width * root.player.length
                }
            }

            AsciiText {
                text: " " + root.clock(root.player?.length ?? 0)
                color: Ascii.dim
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6 * Ascii.ch
            spacing: 6 * Ascii.cw

            Control {
                text: "|◀"
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }

            Control {
                text: root.player?.isPlaying ? "||" : "▶"
                enabled: root.player?.canTogglePlaying ?? false
                tint: Ascii.acc
                onClicked: root.player.togglePlaying()
            }

            Control {
                text: "▶|"
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }
    }

    component Control: AsciiText {
        id: control

        signal clicked()

        property color tint: Ascii.fg

        width: 2 * Ascii.cw
        horizontalAlignment: Text.AlignHCenter
        color: !enabled ? Ascii.frame : hover.containsMouse ? Ascii.acc : tint

        MouseArea {
            id: hover

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            onClicked: control.clicked()
        }
    }
}
