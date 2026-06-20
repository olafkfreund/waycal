pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Reusable bridge: runs `waycal-fetch <args>`, parses the JSON it prints, and
// exposes the result as a ListModel plus loading/error state. A Timer re-runs it
// on an interval. This is the single point where QML touches the backend.
Item {
    id: root

    // --- inputs ---
    property var args: []              // e.g. ["agenda", "--days", "7"]
    property int pollInterval: 300000  // 5 minutes
    property bool autostart: true

    // --- outputs ---
    readonly property alias model: _model
    property bool loading: false
    property string error: ""
    property bool needsAuth: false
    property var lastData: []

    signal updated(var items)

    function refresh() {
        proc.running = true;
    }

    ListModel {
        id: _model
    }

    function _apply(items) {
        _model.clear();
        for (let i = 0; i < items.length; i++)
            _model.append(items[i]);
        root.lastData = items;
        root.updated(items);
    }

    Process {
        id: proc
        command: ["waycal-fetch"].concat(root.args)
        running: false

        onRunningChanged: if (running) root.loading = true

        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.loading = false;
                let text = collector.text.trim();
                if (text.length === 0) {
                    root.error = "no output from waycal-fetch";
                    return;
                }
                try {
                    let parsed = JSON.parse(text);
                    if (parsed && !Array.isArray(parsed) && parsed.error !== undefined) {
                        root.error = String(parsed.error);
                        root.needsAuth = parsed.needsAuth === true;
                        return;
                    }
                    root.error = "";
                    root.needsAuth = false;
                    root._apply(Array.isArray(parsed) ? parsed : []);
                } catch (e) {
                    root.error = "parse error: " + e;
                }
            }
        }

        stderr: StdioCollector {
            id: errCollector
            onStreamFinished: {
                if (errCollector.text.trim().length > 0)
                    console.warn("waycal-fetch stderr:", errCollector.text.trim());
            }
        }
    }

    Timer {
        interval: root.pollInterval
        running: root.autostart
        repeat: true
        triggeredOnStart: true   // fetch immediately, then every interval
        onTriggered: proc.running = true
    }
}
