pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Toggleable full-month overlay. Fullscreen scrim + centered card; click-away or
// Esc closes. Opening (or changing month) triggers a `waycal-fetch month` load.
PanelWindow {
    id: win
    visible: CalendarService.dashboardOpen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "waycal-dashboard"
    focusable: true
    color: Theme.scrim

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() + 1
    property string selectedDate: ""

    onVisibleChanged: if (visible) {
        resetToToday();
        CalendarService.loadMonth(viewYear, viewMonth);
    }

    function resetToToday() {
        let n = new Date();
        viewYear = n.getFullYear();
        viewMonth = n.getMonth() + 1;
        selectedDate = "";
    }
    function shiftMonth(delta) {
        let m = viewMonth - 1 + delta;          // 0-based
        viewYear += Math.floor(m / 12);
        viewMonth = ((m % 12) + 12) % 12 + 1;
        selectedDate = "";
        CalendarService.loadMonth(viewYear, viewMonth);
    }

    // filtered events for the right pane (selected day, or whole month)
    ListModel { id: filtered }
    function rebuildFiltered() {
        filtered.clear();
        let m = CalendarService.monthModel;
        for (let i = 0; i < m.count; i++) {
            let e = m.get(i);
            if (selectedDate.length === 0 || String(e.start).slice(0, 10) === selectedDate)
                filtered.append(e);
        }
    }
    Connections {
        target: CalendarService.monthModel
        function onCountChanged() { win.rebuildFiltered(); }
    }
    onSelectedDateChanged: rebuildFiltered()

    // click-away + Esc to close (inner card swallows its own clicks)
    MouseArea {
        anchors.fill: parent
        onClicked: CalendarService.dashboardOpen = false
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: CalendarService.dashboardOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 980
        height: 680
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.outline
        border.width: 1

        MouseArea { anchors.fill: parent }   // swallow clicks

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad * 2
            spacing: Theme.pad * 2

            // left: navigation + month grid
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.6
                Layout.fillHeight: true
                spacing: Theme.pad

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "‹"
                        color: Theme.text
                        font.pixelSize: 26
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.shiftMonth(-1)
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDate(new Date(win.viewYear, win.viewMonth - 1, 1), "MMMM yyyy")
                        color: Theme.text
                        font.bold: true
                        font.pixelSize: 20
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "›"
                        color: Theme.text
                        font.pixelSize: 26
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.shiftMonth(1)
                        }
                    }
                }

                MonthGrid {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    year: win.viewYear
                    month: win.viewMonth
                    eventsModel: CalendarService.monthModel
                    selectedDate: win.selectedDate
                    onDaySelected: (d) => win.selectedDate = (win.selectedDate === d ? "" : d)
                }
            }

            // right: events for the selected day / month
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.gap

                Text {
                    text: win.selectedDate.length > 0
                        ? Qt.formatDate(new Date(win.selectedDate), "dddd, d MMMM")
                        : "This month"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                }

                StatusBanner {
                    Layout.fillWidth: true
                    loading: CalendarService.monthFetch.loading
                    error: CalendarService.monthFetch.error
                    needsAuth: CalendarService.monthFetch.needsAuth
                    count: filtered.count
                    emptyText: "No events"
                }

                EventList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceModel: filtered
                }
            }
        }
    }
}
