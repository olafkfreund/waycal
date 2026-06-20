pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Always-on unread-mail card, anchored bottom-right.
WidgetWindow {
    anchorBottom: true
    anchorRight: true
    namespace: "waycal-mail"
    heading: "󰇮  Inbox"

    visibleBinding: MailService.widgetVisible
    loading: MailService.loading
    error: MailService.error
    needsAuth: MailService.needsAuth
    count: MailService.model.count
    emptyText: "Inbox zero ✨"

    // header accessory: unread badge, click to toggle the mail overlay
    accessory: Component {
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
