import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    required property string label
    required property string value
    property string iconName: ""
    property bool highlighted: false
    readonly property bool fileIcon: iconName.startsWith("file:") || iconName.startsWith("/")

    implicitWidth: Kirigami.Units.gridUnit * 10
    implicitHeight: Kirigami.Units.gridUnit * 3.4
    color: highlighted ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.18) : Kirigami.Theme.alternateBackgroundColor
    radius: Kirigami.Units.smallSpacing
    border.width: highlighted ? 1 : 0
    border.color: Kirigami.Theme.highlightColor

    RowLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 1.5
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            visible: root.iconName.length > 0 && !root.fileIcon
            source: root.fileIcon ? "" : root.iconName
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }

        Image {
            visible: root.iconName.length > 0 && root.fileIcon
            source: root.fileIcon ? root.iconName : ""
            sourceSize.width: Kirigami.Units.iconSizes.smallMedium
            sourceSize.height: Kirigami.Units.iconSizes.smallMedium
            fillMode: Image.PreserveAspectFit
            smooth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            PlasmaComponents3.Label {
                text: root.value
                font.bold: true
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: root.label
                opacity: 0.72
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

        }

    }

}
