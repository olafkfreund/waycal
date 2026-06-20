pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Shared chrome for the always-on desktop cards (agenda, mail, tasks). An
// anchored, non-space-reserving layer-shell card with a title row, a built-in
// StatusBanner, and a content slot. Each widget only supplies its anchors,
// namespace, title, status bindings, optional header accessory, and body.
PanelWindow {
    id: win

    // body goes into the column below the header/banner
    default property alias content: body.data

    // placement
    property bool anchorTop: false
    property bool anchorBottom: false
    property bool anchorLeft: false
    property bool anchorRight: false
    property string namespace: "waycal"

    // header
    property string heading: ""
    property Component accessory: null

    // status (forwarded to StatusBanner)
    property bool visibleBinding: true
    property bool loading: false
    property string error: ""
    property bool needsAuth: false
    property int count: 0
    property string emptyText: "Nothing here."

    visible: visibleBinding
    color: "transparent"

    anchors {
        top: win.anchorTop
        bottom: win.anchorBottom
        left: win.anchorLeft
        right: win.anchorRight
    }
    margins { top: 16; bottom: 16; left: 16; right: 16 }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: win.namespace
    exclusiveZone: 0

    implicitWidth: 380
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
                    text: win.heading
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                }
                Loader {
                    active: win.accessory !== null
                    sourceComponent: win.accessory
                }
            }

            StatusBanner {
                Layout.fillWidth: true
                loading: win.loading
                error: win.error
                needsAuth: win.needsAuth
                count: win.count
                emptyText: win.emptyText
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: Theme.gap
            }
        }
    }
}
