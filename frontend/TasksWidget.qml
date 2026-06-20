pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Always-on tasks card, anchored bottom-left by default.
PanelWindow {
    id: win
    visible: TasksService.widgetVisible
    color: "transparent"

    anchors { bottom: true; left: true }
    margins { bottom: 16; left: 16 }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "waycal-tasks"
    exclusiveZone: 0

    implicitWidth: 360
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
                    text: "󰄬  Tasks"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamily

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TasksService.overlayOpen = !TasksService.overlayOpen
                    }
                }
                Text {
                    text: TasksService.openCount
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                }
            }

            StatusBanner {
                Layout.fillWidth: true
                loading: TasksService.loading
                error: TasksService.error
                needsAuth: TasksService.needsAuth
                count: TasksService.model.count
                emptyText: "All done ✅"
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(440, contentHeight)
                visible: TasksService.model.count > 0
                clip: true
                spacing: Theme.gap
                boundsBehavior: Flickable.StopAtBounds
                model: TasksService.model
                delegate: TaskRow {}
            }
        }
    }
}
