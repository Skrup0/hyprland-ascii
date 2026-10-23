import QtQuick
import Quickshell.Services.Notifications
import qs.config
import qs.services

Box {
    id: root

    required property Notification modelData

    readonly property string appName: modelData?.appName ?? ""
    readonly property string summary: modelData?.summary ?? ""
    readonly property string body: (modelData?.body ?? "").replace(/<[^>]*>/g, "")
        .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&amp;/g, "&")
    readonly property bool critical: modelData?.urgency === NotificationUrgency.Critical
    readonly property alias hovered: hover.hovered

    cols: 42
    rows: 2 + summaryText.lineCount + (bodyText.visible ? bodyText.lineCount : 0)
    title: appName !== "" ? appName.toLowerCase() : "notification"
    frameColor: critical ? Ascii.red : Ascii.frame
    titleColor: critical ? Ascii.red : Ascii.acc

    HoverHandler {
        id: hover
    }

    AsciiText {
        id: summaryText

        x: 2 * Ascii.cw
        y: Ascii.ch
        width: (root.cols - 4) * Ascii.cw
        text: root.summary
        color: Ascii.bright
        font.bold: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }

    AsciiText {
        id: bodyText

        x: 2 * Ascii.cw
        y: Ascii.ch * (1 + summaryText.lineCount)
        width: (root.cols - 4) * Ascii.cw
        visible: root.body !== ""
        text: root.body
        wrapMode: Text.Wrap
        maximumLineCount: 6
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && root.modelData)
                Notifs.activate(root.modelData)
            Notifs.hideToast(root.modelData)
        }
    }
}
