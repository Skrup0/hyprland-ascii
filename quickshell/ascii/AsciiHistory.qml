import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    readonly property int cols: 46
    readonly property int maxRows: 30
    readonly property var items: [...Notifs.list.values].reverse()

    function pick(notification, open) {
        if (!notification)
            return
        if (open) {
            Notifs.activate(notification)
            visible = false
        }
        notification.dismiss()
    }

    function toggle() {
        if (visible) {
            visible = false
            return
        }
        screen = [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        list.currentIndex = 0
        list.positionViewAtBeginning()
        visible = true
        box.forceActiveFocus()
    }

    visible: false
    onVisibleChanged: Notifs.historyOpen = visible
    anchors {
        top: true
        right: true
    }
    margins {
        top: 4
        right: 9
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "asciibar-history"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: box.width
    implicitHeight: box.height

    Connections {
        target: Notifs
        function onHistoryRequested() { root.toggle() }
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    Box {
        id: box

        readonly property int listRows: Math.max(1, Math.min(root.maxRows, Math.ceil(list.contentHeight / Ascii.ch)))

        cols: root.cols
        rows: listRows + 4
        title: "notifications " + root.items.length
        focus: true
        Keys.onEscapePressed: root.visible = false
        Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
        Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
        Keys.onReturnPressed: root.pick(root.items[list.currentIndex], true)
        Keys.onEnterPressed: root.pick(root.items[list.currentIndex], true)
        Keys.onSpacePressed: root.pick(root.items[list.currentIndex], false)

        ListView {
            id: list

            x: Ascii.cw
            y: Ascii.ch
            width: (root.cols - 2) * Ascii.cw
            height: box.listRows * Ascii.ch
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            model: ScriptModel {
                values: root.items
            }

            delegate: Item {
                id: entry

                required property var modelData
                required property int index

                readonly property string appName: modelData?.appName ?? ""
                readonly property string summary: modelData?.summary ?? ""
                readonly property string body: (modelData?.body ?? "").replace(/<[^>]*>/g, "")
                    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&amp;/g, "&")
                readonly property bool critical: modelData?.urgency === NotificationUrgency.Critical
                readonly property var time: Notifs.times[modelData?.id]

                width: list.width
                height: (2 + summaryText.lineCount + (bodyText.visible ? bodyText.lineCount : 0)) * Ascii.ch

                Rectangle {
                    width: parent.width
                    height: parent.height - Ascii.ch
                    visible: entry.ListView.isCurrentItem
                    color: Ascii.line
                }

                AsciiText {
                    x: Ascii.cw
                    width: parent.width - 9 * Ascii.cw
                    elide: Text.ElideRight
                    text: entry.appName !== "" ? entry.appName.toLowerCase() : "notification"
                    color: entry.critical ? Ascii.red : Ascii.acc
                }

                AsciiText {
                    x: parent.width - 6 * Ascii.cw
                    text: entry.time ? Qt.formatTime(entry.time, "hh:mm") : ""
                    color: Ascii.dim
                }

                AsciiText {
                    id: summaryText

                    x: Ascii.cw
                    y: Ascii.ch
                    width: parent.width - 2 * Ascii.cw
                    text: entry.summary
                    color: Ascii.bright
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                AsciiText {
                    id: bodyText

                    x: Ascii.cw
                    y: Ascii.ch * (1 + summaryText.lineCount)
                    width: parent.width - 2 * Ascii.cw
                    visible: entry.body !== ""
                    text: entry.body
                    color: Ascii.dim
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                MouseArea {
                    width: parent.width
                    height: parent.height - Ascii.ch
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: list.currentIndex = entry.index
                    onClicked: mouse => root.pick(entry.modelData, mouse.button === Qt.LeftButton)
                }
            }
        }

        AsciiText {
            x: 2 * Ascii.cw
            y: Ascii.ch
            visible: root.items.length === 0
            text: "nothing here"
            color: Ascii.dim
        }

        Separator {
            y: (box.listRows + 1) * Ascii.ch
            cols: root.cols
        }

        Row {
            x: 2 * Ascii.cw
            y: (box.listRows + 2) * Ascii.ch
            spacing: 3 * Ascii.cw

            FooterButton {
                text: "clear all"
                onClicked: Notifs.clear()
            }

            FooterButton {
                text: Notifs.dnd ? "dnd on" : "dnd off"
                onClicked: Notifs.dnd = !Notifs.dnd
            }
        }

        FooterButton {
            x: (root.cols - 5) * Ascii.cw
            y: (box.listRows + 2) * Ascii.ch
            text: "esc"
            onClicked: root.visible = false
        }
    }

    component FooterButton: AsciiText {
        id: button

        signal clicked()

        color: hover.containsMouse ? Ascii.acc : Ascii.dim

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }
}
