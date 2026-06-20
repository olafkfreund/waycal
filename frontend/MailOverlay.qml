pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Toggleable centered overlay listing all unread threads.
PanelWindow {
    id: win
    visible: MailService.overlayOpen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "waycal-mail-overlay"
    focusable: true
    color: Theme.scrim

    MouseArea {
        anchors.fill: parent
        onClicked: MailService.overlayOpen = false
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: MailService.overlayOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 620
        height: 720
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.outline
        border.width: 1

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad * 2
            spacing: Theme.gap

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "󰇮  Unread mail"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Theme.fontFamily
                }
                Text {
                    text: "↻"
                    color: Theme.subtext
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MailService.refresh()
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
                Layout.fillHeight: true
                clip: true
                spacing: Theme.gap
                boundsBehavior: Flickable.StopAtBounds
                model: MailService.model
                delegate: MailRow {}
            }
        }
    }
}
