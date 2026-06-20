pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Always-on tasks card, anchored bottom-left.
WidgetWindow {
    anchorBottom: true
    anchorLeft: true
    namespace: "waycal-tasks"
    heading: "󰄬  Tasks"

    visibleBinding: TasksService.widgetVisible
    loading: TasksService.loading
    error: TasksService.error
    needsAuth: TasksService.needsAuth
    count: TasksService.model.count
    emptyText: "All done ✅"

    // header accessory: open count, click to toggle the tasks overlay
    accessory: Component {
        Text {
            text: TasksService.openCount
            color: Theme.subtext
            font.family: Theme.fontFamily
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: TasksService.overlayOpen = !TasksService.overlayOpen
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(440, contentHeight)
        visible: TasksService.model.count > 0
        clip: true
        spacing: Theme.gap
        boundsBehavior: Flickable.StopAtBounds
        model: TasksService.model
        delegate: TaskRow {}
    }
}
