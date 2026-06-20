pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Always-on agenda: a floating layer-shell card anchored top-right showing the
// next few days of events. Does not reserve screen space (exclusiveZone: 0).
PanelWindow {
    id: win
    visible: CalendarService.widgetVisible
    color: "transparent"

    anchors { top: true; right: true }
    margins { top: 16; right: 16 }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "waycal-agenda"
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
                    text: "󰃭  Agenda"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                }
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

            StatusBanner {
                Layout.fillWidth: true
                loading: CalendarService.loading
                error: CalendarService.error
                needsAuth: CalendarService.needsAuth
                count: CalendarService.model.count
                emptyText: "Your schedule is clear 🎉"
            }

            EventList {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(440, contentHeight)
                visible: CalendarService.model.count > 0
                sourceModel: CalendarService.model
            }
        }
    }
}
