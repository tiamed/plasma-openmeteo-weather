import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Representation {
    id: fullRoot

    required property var plasmoidItem
    property string selectedReportType: "hourly"
    property string selectedReportKey: ""
    property var selectedReportItem: ({
    })
    property bool detailViewOpen: false
    readonly property var activeDetailItem: selectedReportKey.length > 0 ? selectedReportItem : (plasmoidItem.hourlyForecast.length > 0 ? plasmoidItem.hourlyForecast[0] : (plasmoidItem.dailyForecast.length > 0 ? plasmoidItem.dailyForecast[0] : ({
    })))
    readonly property string activeDetailType: selectedReportKey.length > 0 ? selectedReportType : (plasmoidItem.hourlyForecast.length > 0 ? "hourly" : "daily")

    function reportKey(type, item) {
        if (!item)
            return "";

        return type === "hourly" ? (item.time || "") : (item.date || "");
    }

    function selectHourly(item) {
        selectedReportType = "hourly";
        selectedReportKey = reportKey("hourly", item);
        selectedReportItem = item || ({
        });
    }

    function selectDaily(item) {
        selectedReportType = "daily";
        selectedReportKey = reportKey("daily", item);
        selectedReportItem = item || ({
        });
    }

    function openHourlyDetail(item) {
        selectHourly(item);
        detailViewOpen = true;
        reportFlick.contentY = 0;
    }

    function openDailyDetail(item) {
        selectDaily(item);
        detailViewOpen = true;
        reportFlick.contentY = 0;
    }

    function closeDetail() {
        detailViewOpen = false;
        reportFlick.contentY = 0;
    }

    function isSelected(type, item) {
        return selectedReportType === type && selectedReportKey === reportKey(type, item);
    }

    function detailTitle(item, type) {
        if (type === "daily")
            return plasmoidItem.dailyPrimaryLabel(item.date);

        return plasmoidItem.hourLabel(item.time);
    }

    function detailSubtitle(item, type) {
        if (type === "daily")
            return i18nc("@info", "%1, %2", plasmoidItem.dailySecondaryLabel(item.date), plasmoidItem.weatherDescription(item.weather_code));

        return i18nc("@info", "%1, %2", plasmoidItem.shortTime(item.time), plasmoidItem.weatherDescription(item.weather_code));
    }

    function detailTemperature(item, type) {
        if (type === "daily")
            return i18nc("@info high and low temperature", "%1 / %2", plasmoidItem.formatTemperature(item.temperature_2m_max, false), plasmoidItem.formatTemperature(item.temperature_2m_min, true));

        return plasmoidItem.formatTemperature(item.temperature_2m, true);
    }

    function detailKindLabel(type) {
        return type === "daily" ? i18nc("@label", "Daily details") : i18nc("@label", "Hourly details");
    }

    function detailModel(type) {
        return type === "daily" ? plasmoidItem.dailyForecast : plasmoidItem.hourlyForecast;
    }

    function detailIndex(type, item) {
        const model = detailModel(type);
        const key = reportKey(type, item);
        for (let index = 0; index < model.length; index++) {
            if (reportKey(type, model[index]) === key)
                return index;

        }
        return -1;
    }

    function canStepDetail(offset) {
        const model = detailModel(activeDetailType);
        const index = detailIndex(activeDetailType, activeDetailItem);
        const nextIndex = index + offset;
        return index >= 0 && nextIndex >= 0 && nextIndex < model.length;
    }

    function stepDetail(offset) {
        const model = detailModel(activeDetailType);
        const index = detailIndex(activeDetailType, activeDetailItem);
        const nextIndex = index + offset;
        if (index < 0 || nextIndex < 0 || nextIndex >= model.length)
            return ;

        if (activeDetailType === "daily")
            selectDaily(model[nextIndex]);
        else
            selectHourly(model[nextIndex]);
        reportFlick.contentY = 0;
    }

    function daylightText(item) {
        return Number(item.is_day) === 0 ? i18nc("@label", "Night") : i18nc("@label", "Day");
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 22
    Layout.preferredWidth: Kirigami.Units.gridUnit * 28
    Layout.preferredHeight: Kirigami.Units.gridUnit * 34
    collapseMarginsHint: true

    Connections {
        function onHourlyForecastChanged() {
            if (fullRoot.selectedReportKey.length === 0 && fullRoot.plasmoidItem.hourlyForecast.length > 0)
                fullRoot.selectHourly(fullRoot.plasmoidItem.hourlyForecast[0]);

        }

        target: fullRoot.plasmoidItem
    }

    contentItem: Item {
        implicitWidth: Kirigami.Units.gridUnit * 28
        implicitHeight: Kirigami.Units.gridUnit * 30

        Flickable {
            id: reportFlick

            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: reportLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.DragAndOvershootBounds
            interactive: contentHeight > height

            ColumnLayout {
                id: reportLayout

                x: Kirigami.Units.largeSpacing
                y: Kirigami.Units.largeSpacing
                width: reportFlick.width - Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.PlaceholderMessage {
                    visible: !fullRoot.plasmoidItem.hasData || fullRoot.plasmoidItem.errorText.length > 0
                    text: fullRoot.plasmoidItem.errorText.length > 0 ? fullRoot.plasmoidItem.errorText : i18n("Waiting for weather data")
                    iconName: fullRoot.plasmoidItem.weatherIcon
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                }

                ColumnLayout {
                    id: detailView

                    readonly property bool hourly: fullRoot.activeDetailType === "hourly"
                    readonly property var reportItem: fullRoot.activeDetailItem

                    visible: fullRoot.plasmoidItem.hasData && fullRoot.plasmoidItem.errorText.length === 0 && fullRoot.detailViewOpen
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-previous-symbolic"
                            text: i18nc("@action", "Back")
                            onClicked: fullRoot.closeDetail()
                        }

                        PlasmaComponents3.Label {
                            text: fullRoot.detailKindLabel(fullRoot.activeDetailType)
                            opacity: 0.72
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-previous-symbolic"
                            text: ""
                            enabled: fullRoot.canStepDetail(-1)
                            Accessible.name: i18nc("@action", "Previous")
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                            onClicked: fullRoot.stepDetail(-1)
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-next-symbolic"
                            text: ""
                            enabled: fullRoot.canStepDetail(1)
                            Accessible.name: i18nc("@action", "Next")
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                            onClicked: fullRoot.stepDetail(1)
                        }

                    }

                    Rectangle {
                        id: detailSummaryCard

                        readonly property int cardPadding: Kirigami.Units.smallSpacing * 2

                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 7.8
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: Kirigami.Units.smallSpacing
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: detailSummaryCard.cardPadding
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.largeSpacing

                                Kirigami.Icon {
                                    source: fullRoot.plasmoidItem.weatherIconName(detailView.reportItem.weather_code, detailView.hourly ? detailView.reportItem.is_day !== 0 : true, false)
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: Kirigami.Units.smallSpacing

                                    PlasmaExtras.Heading {
                                        text: fullRoot.detailTitle(detailView.reportItem, fullRoot.activeDetailType)
                                        level: 2
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    PlasmaComponents3.Label {
                                        text: fullRoot.plasmoidItem.weatherDescription(detailView.reportItem.weather_code)
                                        font.bold: true
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    PlasmaComponents3.Label {
                                        text: detailView.hourly ? fullRoot.plasmoidItem.shortTime(detailView.reportItem.time) : fullRoot.plasmoidItem.dayAndDate(detailView.reportItem.date)
                                        opacity: 0.72
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                }

                                PlasmaExtras.Heading {
                                    text: fullRoot.detailTemperature(detailView.reportItem, fullRoot.activeDetailType)
                                    level: 1
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }

                            }

                        }

                    }

                    Rectangle {
                        visible: detailView.hourly
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5.4
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: Kirigami.Units.smallSpacing
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaExtras.Heading {
                                    text: i18nc("@title:group", "Temperature")
                                    level: 3
                                    Layout.fillWidth: true
                                }

                                PlasmaComponents3.Label {
                                    text: i18nc("@info", "Selected hour")
                                    opacity: 0.72
                                    horizontalAlignment: Text.AlignRight
                                }

                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                columnSpacing: Kirigami.Units.largeSpacing
                                rowSpacing: 0

                                MetricLabel {
                                    label: i18nc("@label", "Actual")
                                    value: fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.temperature_2m, true)
                                    Layout.fillWidth: true
                                }

                                MetricLabel {
                                    label: i18nc("@label", "Feels like")
                                    value: fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.apparent_temperature, true)
                                    Layout.fillWidth: true
                                }

                                MetricLabel {
                                    label: i18nc("@label", "Humidity")
                                    value: fullRoot.plasmoidItem.formatPercent(detailView.reportItem.relative_humidity_2m)
                                    Layout.fillWidth: true
                                }

                            }

                        }

                    }

                    Rectangle {
                        visible: !detailView.hourly
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 7.2
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: Kirigami.Units.smallSpacing
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaExtras.Heading {
                                    text: i18nc("@title:group", "Temperature Range")
                                    level: 3
                                    Layout.fillWidth: true
                                }

                                PlasmaComponents3.Label {
                                    text: i18nc("@info", "Selected day")
                                    opacity: 0.72
                                    horizontalAlignment: Text.AlignRight
                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaComponents3.Label {
                                    text: fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.temperature_2m_min, false)
                                    opacity: 0.72
                                    horizontalAlignment: Text.AlignLeft
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.largeSpacing

                                    Rectangle {
                                        id: detailTemperatureTrack

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: Math.max(4, Kirigami.Units.smallSpacing)
                                        radius: height / 2
                                        color: Kirigami.Theme.disabledTextColor
                                        opacity: 0.18
                                    }

                                    Rectangle {
                                        x: detailTemperatureTrack.width * fullRoot.plasmoidItem.dailyRangeStart(detailView.reportItem)
                                        anchors.verticalCenter: detailTemperatureTrack.verticalCenter
                                        width: Math.max(Kirigami.Units.smallSpacing, detailTemperatureTrack.width * fullRoot.plasmoidItem.dailyRangeWidth(detailView.reportItem))
                                        height: detailTemperatureTrack.height
                                        radius: height / 2
                                        color: Kirigami.Theme.highlightColor
                                    }

                                }

                                PlasmaComponents3.Label {
                                    text: fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.temperature_2m_max, false)
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

                                MetricLabel {
                                    label: i18nc("@label", "Low")
                                    value: fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.temperature_2m_min, true)
                                    Layout.fillWidth: true
                                }

                                MetricLabel {
                                    label: i18nc("@label", "High")
                                    value: fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.temperature_2m_max, true)
                                    Layout.fillWidth: true
                                }

                                MetricLabel {
                                    label: i18nc("@label", "Feels")
                                    value: i18nc("@info high and low temperature", "%1 / %2", fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.apparent_temperature_max, false), fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.apparent_temperature_min, true))
                                    Layout.fillWidth: true
                                }

                            }

                        }

                    }

                    PlasmaExtras.Heading {
                        text: i18nc("@title:group", "Conditions")
                        level: 3
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName("temperature", false)
                            highlighted: true
                            label: detailView.hourly ? i18nc("@label", "Feels like") : i18nc("@label", "Feels range")
                            value: detailView.hourly ? fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.apparent_temperature, true) : i18nc("@info high and low temperature", "%1 / %2", fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.apparent_temperature_max, false), fullRoot.plasmoidItem.formatTemperature(detailView.reportItem.apparent_temperature_min, true))
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName(detailView.hourly ? "humidity" : "rainChance", false)
                            label: detailView.hourly ? i18nc("@label", "Humidity") : i18nc("@label", "Rain chance")
                            value: detailView.hourly ? fullRoot.plasmoidItem.formatPercent(detailView.reportItem.relative_humidity_2m) : fullRoot.plasmoidItem.formatPercent(detailView.reportItem.precipitation_probability_max)
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName(detailView.hourly ? "rainChance" : "rainAmount", false)
                            label: detailView.hourly ? i18nc("@label", "Rain chance") : i18nc("@label", "Rain amount")
                            value: detailView.hourly ? fullRoot.plasmoidItem.formatPercent(detailView.reportItem.precipitation_probability) : fullRoot.plasmoidItem.formatLength(detailView.reportItem.precipitation_sum)
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName(detailView.hourly ? "rainAmount" : "wind", false)
                            label: detailView.hourly ? i18nc("@label", "Rain amount") : i18nc("@label", "Max wind")
                            value: detailView.hourly ? fullRoot.plasmoidItem.formatLength(detailView.reportItem.precipitation) : fullRoot.plasmoidItem.formatWind(detailView.reportItem.wind_speed_10m_max)
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName(detailView.hourly ? "wind" : "uv", false)
                            label: detailView.hourly ? i18nc("@label", "Wind") : i18nc("@label", "UV index")
                            value: detailView.hourly ? fullRoot.plasmoidItem.formatWind(detailView.reportItem.wind_speed_10m) : fullRoot.plasmoidItem.formatUv(detailView.reportItem.uv_index_max)
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName(detailView.hourly ? "uv" : "sunrise", false)
                            label: detailView.hourly ? i18nc("@label", "UV index") : i18nc("@label", "Sunrise")
                            value: detailView.hourly ? fullRoot.plasmoidItem.formatUv(detailView.reportItem.uv_index) : fullRoot.plasmoidItem.shortTime(detailView.reportItem.sunrise)
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.metricIconName(detailView.hourly ? "daylight" : "sunset", detailView.hourly && Number(detailView.reportItem.is_day) === 0)
                            label: detailView.hourly ? i18nc("@label", "Daylight") : i18nc("@label", "Sunset")
                            value: detailView.hourly ? fullRoot.daylightText(detailView.reportItem) : fullRoot.plasmoidItem.shortTime(detailView.reportItem.sunset)
                            Layout.fillWidth: true
                        }

                        DetailMetricCard {
                            iconName: fullRoot.plasmoidItem.weatherIconName(detailView.reportItem.weather_code, detailView.hourly ? detailView.reportItem.is_day !== 0 : true, true)
                            label: i18nc("@label", "Condition")
                            value: fullRoot.plasmoidItem.weatherDescription(detailView.reportItem.weather_code)
                            Layout.fillWidth: true
                        }

                    }

                }

                ColumnLayout {
                    visible: fullRoot.plasmoidItem.hasData && fullRoot.plasmoidItem.errorText.length === 0 && !fullRoot.detailViewOpen
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            source: fullRoot.plasmoidItem.weatherIconName(fullRoot.plasmoidItem.currentWeather.weather_code, fullRoot.plasmoidItem.currentWeather.is_day !== 0, false)
                            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaExtras.Heading {
                                text: fullRoot.plasmoidItem.locationTitle
                                level: 2
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: fullRoot.plasmoidItem.conditionText
                                opacity: 0.72
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: i18nc("@info", "Updated %1", fullRoot.plasmoidItem.updatedText)
                                opacity: 0.72
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                        }

                        PlasmaExtras.Heading {
                            text: fullRoot.plasmoidItem.formatTemperature(fullRoot.plasmoidItem.currentWeather.temperature_2m, true)
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

                        MetricLabel {
                            label: i18nc("@label", "Feels")
                            value: fullRoot.plasmoidItem.feelsLikeText
                        }

                        MetricLabel {
                            label: i18nc("@label", "Humidity")
                            value: fullRoot.plasmoidItem.formatPercent(fullRoot.plasmoidItem.currentWeather.relative_humidity_2m)
                        }

                        MetricLabel {
                            label: i18nc("@label", "Wind")
                            value: fullRoot.plasmoidItem.formatWind(fullRoot.plasmoidItem.currentWeather.wind_speed_10m)
                        }

                        MetricLabel {
                            label: i18nc("@label", "Rain")
                            value: fullRoot.plasmoidItem.formatLength(fullRoot.plasmoidItem.currentWeather.precipitation)
                        }

                        MetricLabel {
                            label: i18nc("@label", "UV")
                            value: fullRoot.plasmoidItem.dailyForecast.length > 0 ? fullRoot.plasmoidItem.formatUv(fullRoot.plasmoidItem.dailyForecast[0].uv_index_max) : "--"
                        }

                        MetricLabel {
                            label: i18nc("@label", "Sun")
                            value: fullRoot.plasmoidItem.dailyForecast.length > 0 ? fullRoot.plasmoidItem.shortTime(fullRoot.plasmoidItem.dailyForecast[0].sunrise) : "--"
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaExtras.Heading {
                            text: i18nc("@title:group", "Hourly Report")
                            level: 3
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.Label {
                            text: i18nc("@info", "24 hours")
                            opacity: 0.72
                            horizontalAlignment: Text.AlignRight
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 10.2
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: Kirigami.Units.smallSpacing
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaComponents3.Label {
                                    text: i18nc("@label", "Temperature")
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                PlasmaComponents3.Label {
                                    text: i18nc("@label", "Rain chance")
                                    opacity: 0.72
                                    horizontalAlignment: Text.AlignRight
                                }

                            }

                            ForecastChart {
                                plasmoidItem: fullRoot.plasmoidItem
                                model: fullRoot.plasmoidItem.hourlyForecast
                                chartMode: "hourly"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                        }

                    }

                    Flickable {
                        id: hourlyReportFlick

                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5.8
                        clip: true
                        contentWidth: hourlyReportRow.implicitWidth
                        contentHeight: height
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        interactive: contentWidth > width

                        Row {
                            id: hourlyReportRow

                            height: hourlyReportFlick.height
                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: fullRoot.plasmoidItem.hourlyForecast

                                delegate: Rectangle {
                                    id: hourReportCard

                                    required property var modelData
                                    readonly property bool selected: fullRoot.isSelected("hourly", modelData)

                                    width: Kirigami.Units.gridUnit * 4.7
                                    height: hourlyReportRow.height
                                    radius: Kirigami.Units.smallSpacing
                                    color: selected ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.28) : Kirigami.Theme.alternateBackgroundColor
                                    border.width: selected ? 1 : 0
                                    border.color: Kirigami.Theme.highlightColor

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Kirigami.Units.smallSpacing
                                        spacing: 0

                                        PlasmaComponents3.Label {
                                            text: fullRoot.plasmoidItem.hourLabel(modelData.time)
                                            font.bold: hourReportCard.selected
                                            horizontalAlignment: Text.AlignHCenter
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Kirigami.Icon {
                                            source: fullRoot.plasmoidItem.weatherIconName(modelData.weather_code, modelData.is_day !== 0, false)
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                        }

                                        PlasmaComponents3.Label {
                                            text: fullRoot.plasmoidItem.formatTemperature(modelData.temperature_2m, false)
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.fillWidth: true
                                        }

                                        PlasmaComponents3.Label {
                                            text: fullRoot.plasmoidItem.formatPercent(modelData.precipitation_probability)
                                            opacity: 0.72
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.fillWidth: true
                                        }

                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: fullRoot.openHourlyDetail(modelData)
                                    }

                                }

                            }

                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaExtras.Heading {
                            text: i18nc("@title:group", "Daily Report")
                            level: 3
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.Label {
                            text: i18nc("@info", "7 days")
                            opacity: 0.72
                            horizontalAlignment: Text.AlignRight
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 10.2
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: Kirigami.Units.smallSpacing
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                PlasmaComponents3.Label {
                                    text: i18nc("@label", "High / low")
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                PlasmaComponents3.Label {
                                    text: i18nc("@label", "Daily rain")
                                    opacity: 0.72
                                    horizontalAlignment: Text.AlignRight
                                }

                            }

                            ForecastChart {
                                plasmoidItem: fullRoot.plasmoidItem
                                model: fullRoot.plasmoidItem.dailyForecast
                                chartMode: "daily"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: fullRoot.plasmoidItem.dailyForecast

                            delegate: Rectangle {
                                id: dailyReportCard

                                required property var modelData
                                readonly property bool selected: fullRoot.isSelected("daily", modelData)
                                readonly property int cardPadding: Kirigami.Units.smallSpacing * 2
                                readonly property real rangeStart: fullRoot.plasmoidItem.dailyRangeStart(modelData)
                                readonly property real rangeWidth: fullRoot.plasmoidItem.dailyRangeWidth(modelData)

                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 5.2
                                radius: Kirigami.Units.smallSpacing
                                color: selected ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.28) : Kirigami.Theme.alternateBackgroundColor
                                border.width: selected ? 1 : 0
                                border.color: Kirigami.Theme.highlightColor

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: dailyReportCard.cardPadding
                                    spacing: Kirigami.Units.smallSpacing

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Kirigami.Units.smallSpacing

                                        ColumnLayout {
                                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.3
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 0

                                            PlasmaComponents3.Label {
                                                text: fullRoot.plasmoidItem.dailyPrimaryLabel(modelData.date)
                                                font.bold: true
                                                maximumLineCount: 1
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            PlasmaComponents3.Label {
                                                text: fullRoot.plasmoidItem.dailySecondaryLabel(modelData.date)
                                                opacity: 0.72
                                                maximumLineCount: 1
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                        }

                                        Kirigami.Icon {
                                            source: fullRoot.plasmoidItem.weatherIconName(modelData.weather_code, true, false)
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 0

                                            PlasmaComponents3.Label {
                                                text: fullRoot.plasmoidItem.weatherDescription(modelData.weather_code)
                                                font.bold: true
                                                maximumLineCount: 1
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            PlasmaComponents3.Label {
                                                text: i18nc("@info", "%1 rain, %2 wind", fullRoot.plasmoidItem.formatPercent(modelData.precipitation_probability_max), fullRoot.plasmoidItem.formatWind(modelData.wind_speed_10m_max))
                                                opacity: 0.72
                                                maximumLineCount: 1
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                        }

                                        PlasmaComponents3.Label {
                                            text: i18nc("@info high and low temperature", "%1 / %2", fullRoot.plasmoidItem.formatTemperature(modelData.temperature_2m_max, false), fullRoot.plasmoidItem.formatTemperature(modelData.temperature_2m_min, true))
                                            font.bold: true
                                            horizontalAlignment: Text.AlignRight
                                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.8
                                        }

                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Kirigami.Units.smallSpacing

                                        Rectangle {
                                            id: dailyReportTrack

                                            anchors.fill: parent
                                            radius: height / 2
                                            color: Kirigami.Theme.disabledTextColor
                                            opacity: 0.18
                                        }

                                        Rectangle {
                                            x: dailyReportTrack.width * dailyReportCard.rangeStart
                                            anchors.verticalCenter: dailyReportTrack.verticalCenter
                                            width: Math.max(Kirigami.Units.smallSpacing, dailyReportTrack.width * dailyReportCard.rangeWidth)
                                            height: dailyReportTrack.height
                                            radius: height / 2
                                            color: Kirigami.Theme.highlightColor
                                        }

                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: fullRoot.openDailyDetail(modelData)
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    footer: PlasmaExtras.PlasmoidHeading {

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                text: i18nc("@action", "Refresh")
                icon.name: "view-refresh"
                enabled: !fullRoot.plasmoidItem.loading
                onClicked: fullRoot.plasmoidItem.refreshWeather()
            }

            PlasmaComponents3.Label {
                text: i18nc("@info", "Open-Meteo")
                opacity: 0.72
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }

        }

    }

}
