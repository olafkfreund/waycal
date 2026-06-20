pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Toggleable centered overlay listing all unread threads.
OverlayWindow {
    visibleBinding: MailService.overlayOpen
    onRequestClose: MailService.overlayOpen = false
    onRefreshRequested: MailService.refresh()
    namespace: "waycal-mail-overlay"
    heading: "󰇮  Unread mail"
    cardWidth: 620
    cardHeight: 720

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.gap

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
