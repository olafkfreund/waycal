pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// A 6x7 month grid (Monday-first). Highlights today, dots days that have events,
// and emits daySelected when a day is clicked.
Item {
    id: grid

    property int year
    property int month            // 1-12
    property var eventsModel
    property string selectedDate: ""   // "YYYY-MM-DD"
    signal daySelected(string date)

    readonly property int startDow: ((new Date(year, month - 1, 1).getDay()) + 6) % 7  // Mon=0
    readonly property int daysInMonth: new Date(year, month, 0).getDate()

    property var activeDays: ({})
    function dateKey(iso) {
        return iso ? String(iso).slice(0, 10) : "";
    }
    function rebuildActive() {
        let a = {};
        if (grid.eventsModel) {
            for (let i = 0; i < grid.eventsModel.count; i++) {
                let k = grid.dateKey(grid.eventsModel.get(i).start);
                if (k.length > 0)
                    a[k] = true;
            }
        }
        grid.activeDays = a;
    }
    Component.onCompleted: rebuildActive()
    Connections {
        target: grid.eventsModel
        function onCountChanged() { grid.rebuildActive(); }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.gap

        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.subtext
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            interactive: false
            cellWidth: width / 7
            cellHeight: height / 6
            model: 42

            delegate: Item {
                id: cell
                required property int index

                readonly property int dayNum: index - grid.startDow + 1
                readonly property bool inMonth: dayNum >= 1 && dayNum <= grid.daysInMonth
                readonly property string dateStr: inMonth
                    ? grid.year + "-" + String(grid.month).padStart(2, "0") + "-" + String(dayNum).padStart(2, "0")
                    : ""
                readonly property bool isToday: dateStr.length > 0 && dateStr === Qt.formatDate(new Date(), "yyyy-MM-dd")
                readonly property bool hasEvents: inMonth && grid.activeDays[dateStr] === true
                readonly property bool selected: dateStr.length > 0 && dateStr === grid.selectedDate

                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    visible: cell.inMonth
                    width: Math.min(parent.width, parent.height) - 8
                    height: width
                    radius: width / 2
                    color: cell.selected ? Theme.primary
                        : cell.isToday ? Theme.surfaceAlt
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: cell.inMonth ? cell.dayNum : ""
                        color: cell.selected ? Theme.background : Theme.text
                        font.family: Theme.fontFamily
                    }
                    Rectangle {
                        visible: cell.hasEvents && !cell.selected
                        width: 5; height: 5; radius: 2.5
                        color: Theme.accent
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: cell.inMonth
                        cursorShape: Qt.PointingHandCursor
                        onClicked: grid.daySelected(cell.dateStr)
                    }
                }
            }
        }
    }
}
