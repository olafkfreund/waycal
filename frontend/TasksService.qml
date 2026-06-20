pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Google Tasks state shared by the tasks widget and its overlay.
Singleton {
    id: root

    property bool widgetVisible: true
    property bool overlayOpen: false

    readonly property GogModel tasks: GogModel {
        args: ["tasks"]
        pollInterval: 300000
    }

    readonly property var model: tasks.model
    readonly property bool loading: tasks.loading
    readonly property string error: tasks.error
    readonly property bool needsAuth: tasks.needsAuth
    readonly property int openCount: tasks.model.count

    function refresh() {
        tasks.refresh();
    }

    // The one mutating path: complete a task, then refresh the list.
    function complete(listId, taskId) {
        doneProc.command = ["waycal-fetch", "task-done", String(listId), String(taskId)];
        doneProc.running = true;
    }

    Process {
        id: doneProc
        running: false
        onExited: (code, status) => root.refresh()
    }
}
