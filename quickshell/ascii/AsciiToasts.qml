import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    screen: [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifs.toasts.length > 0 && !Notifs.historyOpen

    anchors {
        top: true
        right: true
    }
    margins {
        top: 9
        right: 9
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "asciibar-toasts"

    implicitWidth: 42 * Ascii.cw
    implicitHeight: Math.max(1, column.implicitHeight)

    Column {
        id: column

        spacing: Ascii.ch / 2

        Repeater {
            model: ScriptModel {
                values: Notifs.toasts
            }

            delegate: AsciiCard {
                id: card

                Timer {
                    running: !card.critical && !card.hovered
                    interval: (card.modelData?.expireTimeout ?? 0) > 0 ? card.modelData.expireTimeout * 1000 : 6000
                    onTriggered: Notifs.hideToast(card.modelData)
                }
            }
        }
    }
}
