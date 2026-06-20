pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Always-on agenda: next few days of events, anchored top-right.
WidgetWindow {
    anchorTop: true
    anchorRight: true
    namespace: "waycal-agenda"
    heading: "󰃭  Agenda"

    visibleBinding: CalendarService.widgetVisible
    loading: CalendarService.loading
    error: CalendarService.error
    needsAuth: CalendarService.needsAuth
    count: CalendarService.model.count
    emptyText: "Your schedule is clear 🎉"

    // header accessory: today's date, click to toggle the month dashboard
    accessory: Component {
        Text {
            text: Qt.formatDate(new Date(), "ddd d MMM")
            color: Theme.subtext
            font.family: Theme.fontFamily
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: CalendarService.dashboardOpen = !CalendarService.dashboardOpen
            }
        }
    }

    EventList {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(440, contentHeight)
        visible: CalendarService.model.count > 0
        sourceModel: CalendarService.model
    }
}
