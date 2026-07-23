import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property real rangeStart
    required property real rangeWidth

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: Kirigami.Theme.disabledTextColor
        opacity: 0.18
    }

    Rectangle {
        x: track.width * root.rangeStart
        anchors.verticalCenter: track.verticalCenter
        width: Math.max(Kirigami.Units.smallSpacing, track.width * root.rangeWidth)
        height: track.height
        radius: height / 2
        color: Kirigami.Theme.highlightColor
    }
}
