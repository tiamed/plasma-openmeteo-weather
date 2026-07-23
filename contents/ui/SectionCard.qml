import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    default property alias contentData: contentLayout.data
    property int contentMargins: Kirigami.Units.smallSpacing * 2
    property real contentSpacing: Kirigami.Units.smallSpacing
    property bool highlighted: false

    color: highlighted
        ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.18)
        : Kirigami.Theme.alternateBackgroundColor
    radius: Kirigami.Units.smallSpacing
    border.width: highlighted ? 1 : 0
    border.color: Kirigami.Theme.highlightColor

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        anchors.margins: root.contentMargins
        spacing: root.contentSpacing
    }
}
