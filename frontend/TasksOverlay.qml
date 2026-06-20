pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Toggleable centered overlay listing all open tasks.
OverlayWindow {
    visibleBinding: TasksService.overlayOpen
    onRequestClose: TasksService.overlayOpen = false
    onRefreshRequested: TasksService.refresh()
    namespace: "waycal-tasks-overlay"
    heading: "󰄬  Tasks"
    cardWidth: 560
    cardHeight: 720

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.gap

        StatusBanner {
            Layout.fillWidth: true
            loading: TasksService.loading
            error: TasksService.error
            needsAuth: TasksService.needsAuth
            count: TasksService.model.count
            emptyText: "All done ✅"
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.gap
            boundsBehavior: Flickable.StopAtBounds
            model: TasksService.model
            delegate: TaskRow {}
        }
    }
}
