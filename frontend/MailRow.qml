pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// One unread Gmail thread. Click opens it in the browser (link from gog).
Rectangle {
    id: row
    required property string from
    required property string subject
    required property string snippet
    required property string date
    required property bool unread
    required property string link

    width: ListView.view ? ListView.view.width : 360
    radius: Theme.radius - 4
    color: Theme.surface
    implicitHeight: body.implicitHeight + 2 * Theme.pad

    function fmtDate(s) {
        if (!s)
            return "";
        // gog may emit RFC3339 or a ms-epoch internalDate
        let d = new Date(isNaN(s) ? s : Number(s));
        if (isNaN(d.getTime()))
            return s;
        let now = new Date();
        if (d.toDateString() === now.toDateString())
            return d.toLocaleTimeString(Qt.locale(), "hh:mm");
        return d.toLocaleDateString(Qt.locale(), "d MMM");
    }

    ColumnLayout {
        id: body
        x: Theme.pad
        y: Theme.pad
        width: parent.width - 2 * Theme.pad
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 8; height: 8; radius: 4
                color: Theme.primary
                visible: row.unread
            }
            Text {
                Layout.fillWidth: true
                text: row.from
                color: Theme.text
                font.bold: row.unread
                elide: Text.ElideRight
                font.family: Theme.fontFamily
            }
            Text {
                text: row.fmtDate(row.date)
                color: Theme.subtext
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }
        Text {
            Layout.fillWidth: true
            text: row.subject
            color: Theme.subtext
            elide: Text.ElideRight
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (row.link.length > 0) Qt.openUrlExternally(row.link)
    }
}
