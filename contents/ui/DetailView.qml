import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

ColumnLayout {
    id: root

    required property var plasmoidItem
    required property var host
    readonly property bool hourly: host.activeDetailType === "hourly"
    readonly property var reportItem: host.activeDetailItem

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing
    opacity: 0
    Component.onCompleted: if (visible)
        detailFadeIn.restart()
    onVisibleChanged: if (visible)
        detailFadeIn.restart()

    NumberAnimation {
        id: detailFadeIn

        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Kirigami.Units.shortDuration
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            icon.name: "draw-arrow-back"
            text: plasmoidItem.tr("Back")
            onClicked: root.host.closeDetail()
        }

        PlasmaComponents3.Label {
            text: root.host.detailKindLabel(root.host.activeDetailType)
            opacity: 0.72
            maximumLineCount: 1
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents3.ToolButton {
            icon.name: "go-previous-symbolic"
            text: ""
            enabled: root.host.canStepDetail(-1)
            Accessible.name: plasmoidItem.tr("Previous")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
            onClicked: root.host.stepDetail(-1)
        }

        PlasmaComponents3.ToolButton {
            icon.name: "go-next-symbolic"
            text: ""
            enabled: root.host.canStepDetail(1)
            Accessible.name: plasmoidItem.tr("Next")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
            onClicked: root.host.stepDetail(1)
        }
    }

    SectionCard {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 7.8

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: root.plasmoidItem.weatherIconName(root.reportItem.weather_code, root.hourly ? root.reportItem.is_day !== 0 : true, false)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.Heading {
                    text: root.host.detailTitle(root.reportItem, root.host.activeDetailType)
                    level: 2
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: root.plasmoidItem.weatherDescription(root.reportItem.weather_code)
                    font.bold: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: root.hourly ? root.plasmoidItem.shortTime(root.reportItem.time) : root.plasmoidItem.dayAndDate(root.reportItem.date)
                    opacity: 0.72
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            PlasmaExtras.Heading {
                text: root.host.detailTemperature(root.reportItem, root.host.activeDetailType)
                level: 1
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    SectionCard {
        visible: root.hourly
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5.4

        ReportSectionHeader {
            title: plasmoidItem.tr("Temperature")
            subtitle: plasmoidItem.tr("Selected hour")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: 0
            uniformCellWidths: true

            MetricLabel {
                label: plasmoidItem.tr("Actual")
                value: root.plasmoidItem.formatTemperature(root.reportItem.temperature_2m, true)
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }

            MetricLabel {
                label: plasmoidItem.tr("Feels like")
                value: root.plasmoidItem.formatTemperature(root.reportItem.apparent_temperature, true)
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }

            MetricLabel {
                label: plasmoidItem.tr("Humidity")
                value: root.plasmoidItem.formatPercent(root.reportItem.relative_humidity_2m)
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }
        }
    }

    SectionCard {
        visible: !root.hourly
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 7.2

        ReportSectionHeader {
            title: plasmoidItem.tr("Temperature Range")
            subtitle: plasmoidItem.tr("Selected day")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: root.plasmoidItem.formatTemperature(root.reportItem.temperature_2m_min, false)
                opacity: 0.72
                horizontalAlignment: Text.AlignLeft
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            }

            TemperatureRangeBar {
                rangeStart: root.plasmoidItem.dailyRangeStart(root.reportItem)
                rangeWidth: root.plasmoidItem.dailyRangeWidth(root.reportItem)
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.largeSpacing
            }

            PlasmaComponents3.Label {
                text: root.plasmoidItem.formatTemperature(root.reportItem.temperature_2m_max, false)
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: 0
            uniformCellWidths: true

            MetricLabel {
                label: plasmoidItem.tr("Low")
                value: root.plasmoidItem.formatTemperature(root.reportItem.temperature_2m_min, true)
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }

            MetricLabel {
                label: plasmoidItem.tr("High")
                value: root.plasmoidItem.formatTemperature(root.reportItem.temperature_2m_max, true)
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }

            MetricLabel {
                label: plasmoidItem.tr("Feels")
                value: plasmoidItem.trf("%1 / %2", root.plasmoidItem.formatTemperature(root.reportItem.apparent_temperature_max, false), root.plasmoidItem.formatTemperature(root.reportItem.apparent_temperature_min, true))
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }
        }
    }

    PlasmaExtras.Heading {
        text: plasmoidItem.tr("Conditions")
        level: 3
        Layout.fillWidth: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName("temperature", false)
            highlighted: true
            conditionKey: root.hourly ? "feelsLike" : "feelsRange"
            label: root.hourly ? plasmoidItem.tr("Feels like") : plasmoidItem.tr("Feels range")
            value: root.hourly ? root.plasmoidItem.formatTemperature(root.reportItem.apparent_temperature, true) : plasmoidItem.trf("%1 / %2", root.plasmoidItem.formatTemperature(root.reportItem.apparent_temperature_max, false), root.plasmoidItem.formatTemperature(root.reportItem.apparent_temperature_min, true))
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName(root.hourly ? "humidity" : "rainChance", false)
            conditionKey: root.hourly ? "humidity" : "rainChance"
            label: root.hourly ? plasmoidItem.tr("Humidity") : plasmoidItem.tr("Rain chance")
            value: root.hourly ? root.plasmoidItem.formatPercent(root.reportItem.relative_humidity_2m) : root.plasmoidItem.formatPercent(root.reportItem.precipitation_probability_max)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName(root.hourly ? "rainChance" : "rainAmount", false)
            conditionKey: root.hourly ? "rainChance" : "rainAmount"
            label: root.hourly ? plasmoidItem.tr("Rain chance") : plasmoidItem.tr("Rain amount")
            value: root.hourly ? root.plasmoidItem.formatPercent(root.reportItem.precipitation_probability) : root.plasmoidItem.formatLength(root.reportItem.precipitation_sum)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName(root.hourly ? "rainAmount" : "wind", false)
            conditionKey: root.hourly ? "rainAmount" : "maxWind"
            label: root.hourly ? plasmoidItem.tr("Rain amount") : plasmoidItem.tr("Max wind")
            value: root.hourly ? root.plasmoidItem.formatLength(root.reportItem.precipitation) : root.plasmoidItem.formatWind(root.reportItem.wind_speed_10m_max)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName(root.hourly ? "wind" : "uv", false)
            conditionKey: root.hourly ? "wind" : "uv"
            label: root.hourly ? plasmoidItem.tr("Wind") : plasmoidItem.tr("UV index")
            value: root.hourly ? root.plasmoidItem.formatWind(root.reportItem.wind_speed_10m) : root.plasmoidItem.formatUv(root.reportItem.uv_index_max)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName(root.hourly ? "uv" : "sunrise", false)
            conditionKey: root.hourly ? "uv" : "sunrise"
            label: root.hourly ? plasmoidItem.tr("UV index") : plasmoidItem.tr("Sunrise")
            value: root.hourly ? root.plasmoidItem.formatUv(root.reportItem.uv_index) : root.plasmoidItem.shortTime(root.reportItem.sunrise)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.metricIconName(root.hourly ? "airQuality" : "sunset", false)
            conditionKey: root.hourly ? "airQuality" : "sunset"
            label: root.hourly ? plasmoidItem.tr("Air quality") : plasmoidItem.tr("Sunset")
            value: root.hourly ? root.plasmoidItem.formatAirQuality(root.reportItem.european_aqi) : root.plasmoidItem.shortTime(root.reportItem.sunset)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }

        DetailMetricCard {
            iconName: root.plasmoidItem.weatherIconName(root.reportItem.weather_code, root.hourly ? root.reportItem.is_day !== 0 : true, true)
            conditionKey: "condition"
            label: plasmoidItem.tr("Condition")
            value: root.plasmoidItem.weatherDescription(root.reportItem.weather_code)
            Layout.fillWidth: true
            onActivated: root.host.openConditionDetail(conditionKey)
        }
    }
}
