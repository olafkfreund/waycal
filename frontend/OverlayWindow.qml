pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Shared chrome for the toggleable overlays (month dashboard, mail, tasks). A
// fullscreen scrim with Esc / click-away close and a centered card. An optional
// title row (with a refresh button) is shown when `title` is set; everything
// else goes into the content slot.
PanelWindow {
    id: win

    default property alias content: slot.data

    property bool visibleBinding: false
    property string namespace: "waycal-overlay"
    property int cardWidth: 600
    property int cardHeight: 720
    property string heading: ""

    signal requestClose()
    signal refreshRequested()
    signal opened()

    visible: visibleBinding
    onVisibleChanged: if (visible) win.opened()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: win.namespace
    focusable: true
    color: Theme.scrim

    MouseArea {
        anchors.fill: parent
        onClicked: win.requestClose()
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.requestClose()
    }

    Rectangle {
        anchors.centerIn: parent
        width: win.cardWidth
        height: win.cardHeight
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.outline
        border.width: 1

        MouseArea { anchors.fill: parent }   // swallow clicks so they don't close

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad * 2
            spacing: Theme.gap

            RowLayout {
                Layout.fillWidth: true
                visible: win.heading.length > 0
                Text {
                    Layout.fillWidth: true
                    text: win.heading
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Theme.fontFamily
                }
                Text {
                    text: "↻"
                    color: Theme.subtext
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.refreshRequested()
                    }
                }
            }

            Item {
                id: slot
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
