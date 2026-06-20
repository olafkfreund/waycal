pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Toggleable full-month overlay. Uses OverlayWindow for the scrim/card/close
// chrome and supplies its own month navigation, grid, and day-filtered list.
OverlayWindow {
    id: win
    visibleBinding: CalendarService.dashboardOpen
    onRequestClose: CalendarService.dashboardOpen = false
    namespace: "waycal-dashboard"
    cardWidth: 980
    cardHeight: 680
    // no built-in title row; this overlay has its own month navigation header

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() + 1
    property string selectedDate: ""

    onOpened: {
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
        let m = viewMonth - 1 + delta;
        viewYear += Math.floor(m / 12);
        viewMonth = ((m % 12) + 12) % 12 + 1;
        selectedDate = "";
        CalendarService.loadMonth(viewYear, viewMonth);
    }

    // events for the right pane (selected day, or whole month)
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

    RowLayout {
        anchors.fill: parent
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
