import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

ColumnLayout {
    id: root

    required property var plasmoidItem
    required property var host
    required property real hourCardWidth
    required property real hourCardSpacing
    required property real chartSectionHeight
    required property real hourStripHeight

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing
    opacity: 0
    Component.onCompleted: if (visible)
        overviewFadeIn.restart()
    onVisibleChanged: if (visible)
        overviewFadeIn.restart()

    function scrollSelectedHourlyIntoView(item) {
        hourlyReportSection.scrollSelectedIntoView(item);
    }

    NumberAnimation {
        id: overviewFadeIn

        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Kirigami.Units.shortDuration
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: root.plasmoidItem.weatherIconName(root.plasmoidItem.currentWeather.weather_code, root.plasmoidItem.currentWeather.is_day !== 0, false)
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.Heading {
                text: root.plasmoidItem.locationTitle
                level: 2
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: root.plasmoidItem.conditionText
                opacity: 0.72
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: plasmoidItem.trf("Updated %1", root.plasmoidItem.updatedText)
                opacity: 0.72
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        PlasmaExtras.Heading {
            text: root.plasmoidItem.formatTemperature(root.plasmoidItem.currentWeather.temperature_2m, true)
            level: 1
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing
        uniformCellWidths: true

        MetricLabel {
            label: plasmoidItem.tr("Feels")
            value: root.plasmoidItem.feelsLikeText
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }

        MetricLabel {
            label: plasmoidItem.tr("Humidity")
            value: root.plasmoidItem.formatPercent(root.plasmoidItem.currentWeather.relative_humidity_2m)
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }

        MetricLabel {
            label: plasmoidItem.tr("Wind")
            value: root.plasmoidItem.formatWind(root.plasmoidItem.currentWeather.wind_speed_10m)
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }

        MetricLabel {
            label: plasmoidItem.tr("Rain")
            value: root.plasmoidItem.formatLength(root.plasmoidItem.currentWeather.precipitation)
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }

        MetricLabel {
            label: plasmoidItem.tr("UV")
            value: root.plasmoidItem.dailyForecast.length > 0 ? root.plasmoidItem.formatUv(root.plasmoidItem.dailyForecast[0].uv_index_max) : "--"
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }

        MetricLabel {
            label: plasmoidItem.tr("Sun")
            value: root.plasmoidItem.dailyForecast.length > 0
                ? plasmoidItem.trf("%1 / %2", root.plasmoidItem.shortTime(root.plasmoidItem.dailyForecast[0].sunrise), root.plasmoidItem.shortTime(root.plasmoidItem.dailyForecast[0].sunset))
                : "--"
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }
    }

    HourlyReportSection {
        id: hourlyReportSection

        plasmoidItem: root.plasmoidItem
        host: root.host
        hourCardWidth: root.hourCardWidth
        hourCardSpacing: root.hourCardSpacing
        chartSectionHeight: root.chartSectionHeight
        hourStripHeight: root.hourStripHeight
    }

    DailyReportSection {
        plasmoidItem: root.plasmoidItem
        host: root.host
        chartSectionHeight: root.chartSectionHeight
    }
}
