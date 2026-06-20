pragma Singleton

import QtQuick
import Quickshell

// Unread Gmail state shared by the mail widget and its detail overlay.
Singleton {
    id: root

    property bool widgetVisible: true
    property bool overlayOpen: false

    readonly property GogModel mail: GogModel {
        args: ["mail"]
        pollInterval: 180000   // 3 minutes
    }

    readonly property var model: mail.model
    readonly property bool loading: mail.loading
    readonly property string error: mail.error
    readonly property bool needsAuth: mail.needsAuth
    readonly property int unreadCount: mail.model.count

    function refresh() {
        mail.refresh();
    }
}
