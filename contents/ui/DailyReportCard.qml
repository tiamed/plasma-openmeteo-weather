import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    required property var plasmoidItem
    required property var modelData
    required property bool selected
    signal activated()

    readonly property int cardPadding: Kirigami.Units.smallSpacing * 2
    readonly property real rangeStart: plasmoidItem.dailyRangeStart(modelData)
    readonly property real rangeWidth: plasmoidItem.dailyRangeWidth(modelData)

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 5.2
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
        anchors.margins: root.cardPadding
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.3
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                PlasmaComponents3.Label {
                    text: root.plasmoidItem.dailyPrimaryLabel(root.modelData.date)
                    font.bold: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: root.plasmoidItem.dailySecondaryLabel(root.modelData.date)
                    opacity: 0.72
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Kirigami.Icon {
                source: root.plasmoidItem.weatherIconName(root.modelData.weather_code, true, false)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                PlasmaComponents3.Label {
                    text: root.plasmoidItem.weatherDescription(root.modelData.weather_code)
                    font.bold: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: plasmoidItem.trf("%1 rain, %2 wind", root.plasmoidItem.formatPercent(root.modelData.precipitation_probability_max), root.plasmoidItem.formatWind(root.modelData.wind_speed_10m_max))
                    opacity: 0.72
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            PlasmaComponents3.Label {
                text: plasmoidItem.trf("%1 / %2", root.plasmoidItem.formatTemperature(root.modelData.temperature_2m_max, false), root.plasmoidItem.formatTemperature(root.modelData.temperature_2m_min, true))
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.8
            }
        }

        TemperatureRangeBar {
            rangeStart: root.rangeStart
            rangeWidth: root.rangeWidth
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.smallSpacing
        }
    }

    MouseArea {
        id: cardMouse

        anchors.fill: parent
        hoverEnabled: true
        activeFocusOnTab: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: plasmoidItem.trf("%1, %2, high %3, low %4", root.plasmoidItem.dailyPrimaryLabel(root.modelData.date), root.plasmoidItem.weatherDescription(root.modelData.weather_code), root.plasmoidItem.formatTemperature(root.modelData.temperature_2m_max, true), root.plasmoidItem.formatTemperature(root.modelData.temperature_2m_min, true))
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
