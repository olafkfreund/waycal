pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Always-on unread-mail card, anchored bottom-right by default.
PanelWindow {
    id: win
    visible: MailService.widgetVisible
    color: "transparent"

    anchors { bottom: true; right: true }
    margins { bottom: 16; right: 16 }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "waycal-mail"
    exclusiveZone: 0

    implicitWidth: 380
    implicitHeight: frame.implicitHeight

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.alpha(Theme.background, 0.92)
        border.color: Theme.outline
        border.width: 1
        implicitHeight: layout.implicitHeight + 2 * Theme.pad

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.pad
            spacing: Theme.gap

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "󰇮  Inbox"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                }
                Rectangle {
                    visible: MailService.unreadCount > 0
                    radius: height / 2
                    color: Theme.primary
                    implicitWidth: badge.implicitWidth + 12
                    implicitHeight: badge.implicitHeight + 4
                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: MailService.unreadCount
                        color: Theme.background
                        font.bold: true
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MailService.overlayOpen = !MailService.overlayOpen
                    }
                }
            }

            StatusBanner {
                Layout.fillWidth: true
                loading: MailService.loading
                error: MailService.error
                needsAuth: MailService.needsAuth
                count: MailService.model.count
                emptyText: "Inbox zero ✨"
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(440, contentHeight)
                visible: MailService.model.count > 0
                clip: true
                spacing: Theme.gap
                boundsBehavior: Flickable.StopAtBounds
                model: MailService.model
                delegate: MailRow {}
            }
        }
    }
}
