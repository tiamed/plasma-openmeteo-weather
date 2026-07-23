import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    required property var plasmoidItem
    required property var modelData
    required property bool selected
    required property real cardWidth
    signal activated()

    width: cardWidth
    radius: Kirigami.Units.smallSpacing
    color: selected
        ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.28)
        : (cardMouse.containsMouse
            ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.alternateBackgroundColor, Kirigami.Theme.textColor, 0.07)
            : Kirigami.Theme.alternateBackgroundColor)
    border.width: cardMouse.activeFocus ? 2 : (selected ? 1 : 0)
    border.color: cardMouse.activeFocus ? Kirigami.Theme.focusColor : Kirigami.Theme.highlightColor

    Behavior on color {
        ColorAnimation {
            duration: Kirigami.Units.shortDuration
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: 0

        PlasmaComponents3.Label {
            text: root.plasmoidItem.hourLabel(root.modelData.time)
            font.bold: root.selected
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Kirigami.Icon {
            source: root.plasmoidItem.weatherIconName(root.modelData.weather_code, root.modelData.is_day !== 0, false)
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }

        PlasmaComponents3.Label {
            text: root.plasmoidItem.formatTemperature(root.modelData.temperature_2m, false)
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        PlasmaComponents3.Label {
            text: root.plasmoidItem.formatPercent(root.modelData.precipitation_probability)
            opacity: 0.72
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: cardMouse

        anchors.fill: parent
        hoverEnabled: true
        activeFocusOnTab: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: plasmoidItem.trf("%1, %2, %3", root.plasmoidItem.hourLabel(root.modelData.time), root.plasmoidItem.weatherDescription(root.modelData.weather_code), root.plasmoidItem.formatTemperature(root.modelData.temperature_2m, true))
        Accessible.onPressAction: root.activated()
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Select:
                root.activated();
                event.accepted = true;
                break;
            }
        }
        onPressed: forceActiveFocus()
        onClicked: root.activated()
    }
}
