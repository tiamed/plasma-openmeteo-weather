import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

ColumnLayout {
    id: root

    required property var plasmoidItem
    required property var host
    required property var reportItem
    required property bool hourly
    required property string conditionKey

    readonly property var trendModel: hourly ? plasmoidItem.hourlyForecast : plasmoidItem.dailyForecast
    readonly property string heroIcon: metricIcon(reportItem)
    readonly property bool heroFileIcon: heroIcon.startsWith("file:") || heroIcon.startsWith("/")
    readonly property bool numericMetric: ["feelsLike", "humidity", "rainChance", "rainAmount", "wind", "maxWind", "uv", "airQuality"].includes(conditionKey)
    readonly property real seriesMax: seriesExtreme(true)
    readonly property real seriesMin: seriesExtreme(false)
    readonly property real seriesAverage: seriesAvg()

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing
    opacity: 0
    Component.onCompleted: if (visible)
        conditionFadeIn.restart()
    onVisibleChanged: if (visible)
        conditionFadeIn.restart()

    NumberAnimation {
        id: conditionFadeIn

        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Kirigami.Units.shortDuration
    }

    function selectTrendItem(item) {
        if (!item)
            return;
        if (hourly)
            host.selectHourly(item);
        else
            host.selectDaily(item);
    }

    function rowLabel(item) {
        if (!hourly)
            return plasmoidItem.dailyPrimaryLabel(item.date);

        const date = new Date(item.time);
        const today = new Date();
        const sameDay = date.getFullYear() === today.getFullYear()
            && date.getMonth() === today.getMonth()
            && date.getDate() === today.getDate();
        return sameDay ? plasmoidItem.tr("Today") : Qt.formatDate(date, "ddd M/d");
    }

    function itemTimeLabel(item) {
        return hourly ? plasmoidItem.trf("%1 %2", rowLabel(item), plasmoidItem.shortTime(item.time)) : plasmoidItem.dayAndDate(item.date);
    }

    function peakItem() {
        let peak = null;
        let peakValue = Number.NEGATIVE_INFINITY;
        for (let index = 0; index < trendModel.length; index++) {
            const value = numericRaw(trendModel[index]);
            if (Number.isFinite(value) && value > peakValue) {
                peak = trendModel[index];
                peakValue = value;
            }
        }
        return peak;
    }

    function totalRain() {
        let total = 0;
        let count = 0;
        for (let index = 0; index < trendModel.length; index++) {
            const value = Number(hourly ? trendModel[index].precipitation : trendModel[index].precipitation_sum);
            if (!Number.isFinite(value))
                continue;
            total += value;
            count += 1;
        }
        return count > 0 ? total : NaN;
    }

    function uvLevel(value) {
        if (value < 3)
            return plasmoidItem.tr("low risk");
        if (value < 6)
            return plasmoidItem.tr("moderate risk");
        if (value < 8)
            return plasmoidItem.tr("high risk");
        if (value < 11)
            return plasmoidItem.tr("very high risk");
        return plasmoidItem.tr("extreme risk");
    }

    function metricSummary() {
        const peak = peakItem();
        switch (conditionKey) {
        case "feelsLike":
            if (hourly && Number.isFinite(Number(reportItem.temperature_2m)) && Number.isFinite(Number(reportItem.apparent_temperature)))
                return plasmoidItem.trf("Actual %1 · feels %2", plasmoidItem.formatTemperature(reportItem.temperature_2m, true), plasmoidItem.formatTemperature(reportItem.apparent_temperature, true));
            return plasmoidItem.tr("Feels-like range for the selected day");
        case "feelsRange":
            return plasmoidItem.tr("Feels-like high and low for the selected day");
        case "rainChance":
            return peak ? plasmoidItem.trf("Highest chance: %1 at %2", plasmoidItem.formatPercent(numericRaw(peak)), itemTimeLabel(peak)) : "";
        case "humidity":
            return plasmoidItem.trf("Forecast range: %1–%2", plasmoidItem.formatPercent(seriesMin), plasmoidItem.formatPercent(seriesMax));
        case "rainAmount": {
            const total = totalRain();
            return Number.isFinite(total) ? plasmoidItem.trf("Total forecast: %1", plasmoidItem.formatLength(total)) : "";
        }
        case "wind":
        case "maxWind":
            return peak ? plasmoidItem.trf("Strongest forecast: %1 at %2", root.metricValue(peak), itemTimeLabel(peak)) : "";
        case "uv":
            return peak ? plasmoidItem.trf("Peak UV: %1 (%2) at %3", plasmoidItem.formatUv(numericRaw(peak)), uvLevel(numericRaw(peak)), itemTimeLabel(peak)) : "";
        case "airQuality": {
            const aqi = Number(reportItem.european_aqi);
            const pm = Number(reportItem.pm2_5);
            if (Number.isFinite(aqi)) {
                let text = plasmoidItem.trf("European AQI %1 (%2)", plasmoidItem.formatAqi(aqi), plasmoidItem.airQualityLevel(aqi));
                if (Number.isFinite(pm))
                    text = plasmoidItem.trf("%1 · PM2.5 %2", text, plasmoidItem.formatPm25(pm));
                return text;
            }
            return peak ? plasmoidItem.trf("Peak AQI: %1 (%2) at %3", plasmoidItem.formatAqi(numericRaw(peak)), plasmoidItem.airQualityLevel(numericRaw(peak)), itemTimeLabel(peak)) : "";
        }
        case "sunrise":
        case "sunset":
            return plasmoidItem.tr("Sun times across the next 7 days");
        case "condition":
            return plasmoidItem.trf("Weather changes across the next %1", hourly ? plasmoidItem.tr("24 hours") : plasmoidItem.tr("7 days"));
        default:
            return "";
        }
    }

    function metricIcon(item) {
        switch (conditionKey) {
        case "feelsLike":
        case "feelsRange":
            return plasmoidItem.metricIconName("temperature", false);
        case "humidity":
            return plasmoidItem.metricIconName("humidity", false);
        case "rainChance":
            return plasmoidItem.metricIconName("rainChance", false);
        case "rainAmount":
            return plasmoidItem.metricIconName("rainAmount", false);
        case "wind":
        case "maxWind":
            return plasmoidItem.metricIconName("wind", false);
        case "uv":
            return plasmoidItem.metricIconName("uv", false);
        case "airQuality":
            return plasmoidItem.metricIconName("airQuality", false);
        case "sunrise":
            return plasmoidItem.metricIconName("sunrise", false);
        case "sunset":
            return plasmoidItem.metricIconName("sunset", false);
        case "condition":
            return plasmoidItem.weatherIconName(item.weather_code, hourly ? item.is_day !== 0 : true, false);
        default:
            return "";
        }
    }

    function metricLabel() {
        switch (conditionKey) {
        case "feelsLike":
            return plasmoidItem.tr("Feels like");
        case "feelsRange":
            return plasmoidItem.tr("Feels range");
        case "humidity":
            return plasmoidItem.tr("Humidity");
        case "rainChance":
            return plasmoidItem.tr("Rain chance");
        case "rainAmount":
            return plasmoidItem.tr("Rain amount");
        case "wind":
            return plasmoidItem.tr("Wind");
        case "maxWind":
            return plasmoidItem.tr("Max wind");
        case "uv":
            return plasmoidItem.tr("UV index");
        case "airQuality":
            return plasmoidItem.tr("Air quality");
        case "sunrise":
            return plasmoidItem.tr("Sunrise");
        case "sunset":
            return plasmoidItem.tr("Sunset");
        case "condition":
            return plasmoidItem.tr("Condition");
        default:
            return "";
        }
    }

    function metricValue(item) {
        switch (conditionKey) {
        case "feelsLike":
            return plasmoidItem.formatTemperature(item.apparent_temperature, true);
        case "feelsRange":
            return plasmoidItem.trf("%1 / %2", plasmoidItem.formatTemperature(item.apparent_temperature_max, false), plasmoidItem.formatTemperature(item.apparent_temperature_min, true));
        case "humidity":
            return plasmoidItem.formatPercent(item.relative_humidity_2m);
        case "rainChance":
            return hourly ? plasmoidItem.formatPercent(item.precipitation_probability) : plasmoidItem.formatPercent(item.precipitation_probability_max);
        case "rainAmount":
            return hourly ? plasmoidItem.formatLength(item.precipitation) : plasmoidItem.formatLength(item.precipitation_sum);
        case "wind":
            return plasmoidItem.formatWind(item.wind_speed_10m);
        case "maxWind":
            return plasmoidItem.formatWind(item.wind_speed_10m_max);
        case "uv":
            return hourly ? plasmoidItem.formatUv(item.uv_index) : plasmoidItem.formatUv(item.uv_index_max);
        case "airQuality":
            return plasmoidItem.formatAirQuality(item.european_aqi);
        case "sunrise":
            return plasmoidItem.shortTime(item.sunrise);
        case "sunset":
            return plasmoidItem.shortTime(item.sunset);
        case "condition":
            return plasmoidItem.weatherDescription(item.weather_code);
        default:
            return "--";
        }
    }

    function numericRaw(item) {
        switch (conditionKey) {
        case "feelsLike":
            return Number(item.apparent_temperature);
        case "humidity":
            return Number(item.relative_humidity_2m);
        case "rainChance":
            return Number(hourly ? item.precipitation_probability : item.precipitation_probability_max);
        case "rainAmount":
            return Number(hourly ? item.precipitation : item.precipitation_sum);
        case "wind":
            return Number(item.wind_speed_10m);
        case "maxWind":
            return Number(item.wind_speed_10m_max);
        case "uv":
            return Number(hourly ? item.uv_index : item.uv_index_max);
        case "airQuality":
            return Number(item.european_aqi);
        default:
            return NaN;
        }
    }

    function formatRaw(value) {
        switch (conditionKey) {
        case "feelsLike":
            return plasmoidItem.formatTemperature(value, true);
        case "humidity":
        case "rainChance":
            return plasmoidItem.formatPercent(value);
        case "rainAmount":
            return plasmoidItem.formatLength(value);
        case "wind":
        case "maxWind":
            return plasmoidItem.formatWind(value);
        case "uv":
            return plasmoidItem.formatUv(value);
        case "airQuality":
            return plasmoidItem.formatAirQuality(value);
        default:
            return "--";
        }
    }

    function seriesExtreme(wantMax) {
        let result = wantMax ? Number.NEGATIVE_INFINITY : Number.POSITIVE_INFINITY;
        for (let index = 0; index < trendModel.length; index++) {
            const value = numericRaw(trendModel[index]);
            if (!Number.isFinite(value))
                continue;
            result = wantMax ? Math.max(result, value) : Math.min(result, value);
        }
        return Number.isFinite(result) ? result : 0;
    }

    function seriesAvg() {
        let sum = 0;
        let count = 0;
        for (let index = 0; index < trendModel.length; index++) {
            const value = numericRaw(trendModel[index]);
            if (!Number.isFinite(value))
                continue;
            sum += value;
            count += 1;
        }
        return count > 0 ? sum / count : 0;
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            icon.name: "draw-arrow-back"
            text: plasmoidItem.tr("Back")
            onClicked: root.host.closeConditionDetail()
        }

        PlasmaComponents3.Label {
            text: plasmoidItem.tr("Metric details")
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

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge

                Kirigami.Icon {
                    anchors.fill: parent
                    visible: !root.heroFileIcon
                    source: root.heroFileIcon ? "" : root.heroIcon
                }

                Image {
                    anchors.fill: parent
                    visible: root.heroFileIcon
                    source: root.heroFileIcon ? root.heroIcon : ""
                    sourceSize.width: Kirigami.Units.iconSizes.huge
                    sourceSize.height: Kirigami.Units.iconSizes.huge
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.Heading {
                    text: root.metricLabel()
                    level: 2
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: root.conditionKey === "condition" ? root.plasmoidItem.weatherDescription(root.reportItem.weather_code) : root.metricSummary()
                    font.bold: true
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
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
                text: root.conditionKey === "condition" ? "" : root.metricValue(root.reportItem)
                visible: root.conditionKey !== "condition"
                level: 1
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    PlasmaComponents3.Label {
        visible: root.numericMetric
        text: root.hourly ? plasmoidItem.tr("Next 24 hours") : plasmoidItem.tr("Next 7 days")
        opacity: 0.72
        Layout.fillWidth: true
    }

    GridLayout {
        visible: root.numericMetric
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        MetricLabel {
            label: plasmoidItem.tr("Low")
            value: root.formatRaw(root.seriesMin)
        }

        MetricLabel {
            label: plasmoidItem.tr("Average")
            value: root.formatRaw(root.seriesAverage)
        }

        MetricLabel {
            label: plasmoidItem.tr("High")
            value: root.formatRaw(root.seriesMax)
        }
    }

    ReportSectionHeader {
        title: plasmoidItem.tr("Trend")
        subtitle: root.hourly ? plasmoidItem.tr("24 hours") : plasmoidItem.tr("7 days")
    }

    SectionCard {
        visible: root.numericMetric
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10.5

        MetricTrendChart {
            plasmoidItem: root.plasmoidItem
            model: root.trendModel
            conditionKey: root.conditionKey
            hourly: root.hourly
            reportItem: root.reportItem
            Layout.fillWidth: true
            Layout.fillHeight: true
            onPointActivated: item => root.selectTrendItem(item)
        }
    }

    ConditionTimeline {
        visible: !root.numericMetric
        plasmoidItem: root.plasmoidItem
        model: root.trendModel
        conditionKey: root.conditionKey
        hourly: root.hourly
        reportItem: root.reportItem
        cardWidth: root.host.hourCardWidth
        cardSpacing: root.host.hourCardSpacing
        Layout.preferredHeight: root.host.hourStripHeight
        onPointActivated: item => root.selectTrendItem(item)
    }
}
