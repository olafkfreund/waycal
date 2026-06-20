import QtQuick
import QtQuick.Layouts

// Shared empty/loading/error/needs-auth message shown inside a widget body.
Item {
    id: root
    property bool loading: false
    property string error: ""
    property bool needsAuth: false
    property int count: 0
    property string emptyText: "Nothing here."

    visible: loading || error.length > 0 || count === 0
    implicitHeight: visible ? label.implicitHeight + 2 * Theme.pad : 0

    Text {
        id: label
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.pad
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.family: Theme.fontFamily
        color: root.error.length ? Theme.danger : Theme.subtext
        text: root.loading ? "Loading…"
            : root.needsAuth ? "🔒 gog needs auth\nset GOG_KEYRING_PASSWORD"
            : root.error.length ? root.error
            : root.emptyText
    }
}
