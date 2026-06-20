pragma Singleton

import QtQuick
import Quickshell

// Calendar state shared by the agenda widget and the month dashboard.
Singleton {
    id: root

    // UI state, flipped by the "calendar" IpcHandler in shell.qml
    property bool widgetVisible: true
    property bool dashboardOpen: false

    // agenda (next N days) — always polling
    readonly property GogModel agenda: GogModel {
        args: ["agenda"]
        pollInterval: 300000
    }

    // month grid — fetched on demand when the dashboard opens / month changes
    readonly property GogModel monthFetch: GogModel {
        autostart: false
        pollInterval: 600000
    }

    // convenience pass-throughs for the agenda widget
    readonly property var model: agenda.model
    readonly property bool loading: agenda.loading
    readonly property string error: agenda.error
    readonly property bool needsAuth: agenda.needsAuth

    readonly property var monthModel: monthFetch.model

    function refresh() {
        agenda.refresh();
    }

    function loadMonth(year, month) {
        // month is 1-12
        monthFetch.args = ["month", String(year), String(month)];
        monthFetch.refresh();
    }
}
