import QtQuick

// Scrollable list of EventCards bound to a calendar ListModel.
ListView {
    id: list
    property var sourceModel

    model: sourceModel
    spacing: Theme.gap
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    implicitHeight: contentHeight

    delegate: EventCard {}
}
