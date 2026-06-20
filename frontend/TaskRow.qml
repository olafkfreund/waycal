pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// One task. The whole model row is taken as `model` because one of its roles is
// "id", which collides with QML's reserved `id` attribute. Checkbox completes it.
Rectangle {
    id: row
    required property var model

    width: ListView.view ? ListView.view.width : 360
    radius: Theme.radius - 4
    color: Theme.surface
    implicitHeight: body.implicitHeight + 2 * Theme.pad

    function fmtDue(s) {
        if (!s)
            return "";
        let d = new Date(s);
        if (isNaN(d.getTime()))
            return String(s);
        return Qt.formatDate(d, "d MMM");
    }

    RowLayout {
        id: body
        x: Theme.pad
        y: Theme.pad
        width: parent.width - 2 * Theme.pad
        spacing: Theme.gap

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 20
            height: 20
            radius: 6
            color: "transparent"
            border.color: Theme.outline
            border.width: 2

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: TasksService.complete(row.model.listId, row.model.id)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: row.model.title
                color: Theme.text
                elide: Text.ElideRight
                font.family: Theme.fontFamily
            }
            RowLayout {
                spacing: Theme.gap
                visible: dueLabel.visible || listLabel.visible
                Text {
                    id: dueLabel
                    visible: row.model.due !== null && String(row.model.due).length > 0
                    text: "󰃭 " + row.fmtDue(row.model.due)
                    color: Theme.warning
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
                Text {
                    id: listLabel
                    visible: String(row.model.list).length > 0
                    text: row.model.list
                    color: Theme.subtext
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }
        }
    }
}
