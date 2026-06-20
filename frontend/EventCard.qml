pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// One calendar event. As a ListView delegate, the required properties below are
// auto-bound to the matching model roles (Qt 6 + ComponentBehavior: Bound).
Rectangle {
    id: card

    required property string title
    required property string start
    required property string end
    required property string description
    required property bool allDay
    required property string location
    required property string link

    property bool expanded: false

    width: ListView.view ? ListView.view.width : 360
    radius: Theme.radius - 4
    color: Theme.surface
    implicitHeight: body.implicitHeight + 2 * Theme.pad
    Behavior on implicitHeight { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    function fmtTime(iso, allday) {
        if (allday)
            return "All day";
        if (!iso)
            return "";
        let d = new Date(iso);
        if (isNaN(d.getTime()))
            return iso;
        return d.toLocaleTimeString(Qt.locale(), "hh:mm");
    }

    ColumnLayout {
        id: body
        x: Theme.pad
        y: Theme.pad
        width: parent.width - 2 * Theme.pad
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            Rectangle {
                Layout.preferredWidth: 4
                Layout.fillHeight: true
                Layout.minimumHeight: 16
                radius: 2
                color: card.allDay ? Theme.accent : Theme.primary
            }
            Text {
                text: card.fmtTime(card.start, card.allDay)
                color: Theme.primary
                font.bold: true
                font.family: Theme.fontFamily
            }
            Text {
                Layout.fillWidth: true
                text: card.title
                color: Theme.text
                elide: Text.ElideRight
                font.family: Theme.fontFamily
            }
        }

        Text {
            visible: card.expanded && (card.description.length > 0 || card.location.length > 0)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.subtext
            font.family: Theme.fontFamily
            text: (card.location.length > 0 ? "📍 " + card.location + (card.description.length ? "\n" : "") : "")
                + card.description
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.expanded = !card.expanded
        onDoubleClicked: if (card.link.length > 0) Qt.openUrlExternally(card.link)
    }
}
