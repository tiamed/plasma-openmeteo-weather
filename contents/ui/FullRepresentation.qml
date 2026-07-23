import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmaExtras.Representation {
    id: fullRoot

    required property var plasmoidItem
    property string selectedReportType: "hourly"
    property string selectedReportKey: ""
    property var selectedReportItem: ({
    })
    property bool detailViewOpen: false
    property bool conditionDetailOpen: false
    property string selectedConditionKey: ""
    property real savedContentY: 0
    property real savedConditionContentY: 0

    readonly property real hourCardWidth: Kirigami.Units.gridUnit * 4.7
    readonly property real hourCardSpacing: Kirigami.Units.smallSpacing
    readonly property real chartSectionHeight: Kirigami.Units.gridUnit * 10.2
    readonly property real hourStripHeight: Kirigami.Units.gridUnit * 5.8

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
        savedContentY = reportFlick.contentY;
        selectHourly(item);
        conditionDetailOpen = false;
        selectedConditionKey = "";
        detailViewOpen = true;
        reportFlick.contentY = 0;
    }

    function openDailyDetail(item) {
        savedContentY = reportFlick.contentY;
        selectDaily(item);
        conditionDetailOpen = false;
        selectedConditionKey = "";
        detailViewOpen = true;
        reportFlick.contentY = 0;
    }

    function openConditionDetail(key) {
        if (!key || key.length === 0)
            return;
        savedConditionContentY = reportFlick.contentY;
        selectedConditionKey = key;
        conditionDetailOpen = true;
        reportFlick.contentY = 0;
    }

    function closeConditionDetail() {
        conditionDetailOpen = false;
        selectedConditionKey = "";
        Qt.callLater(function() {
            reportFlick.contentY = Math.max(0, Math.min(Math.max(0, reportFlick.contentHeight - reportFlick.height), savedConditionContentY));
        });
    }

    function closeDetail() {
        conditionDetailOpen = false;
        selectedConditionKey = "";
        detailViewOpen = false;
        Qt.callLater(function() {
            reportFlick.contentY = Math.max(0, Math.min(Math.max(0, reportFlick.contentHeight - reportFlick.height), savedContentY));
            if (selectedReportType === "hourly" && selectedReportKey.length > 0)
                scrollSelectedHourlyCardIntoView();
        });
    }

    function scrollSelectedHourlyCardIntoView() {
        if (selectedReportType !== "hourly" || selectedReportKey.length === 0)
            return;
        overviewView.scrollSelectedHourlyIntoView(selectedReportItem);
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
            return plasmoidItem.trf("%1, %2", plasmoidItem.dailySecondaryLabel(item.date), plasmoidItem.weatherDescription(item.weather_code));

        return plasmoidItem.trf("%1, %2", plasmoidItem.shortTime(item.time), plasmoidItem.weatherDescription(item.weather_code));
    }

    function detailTemperature(item, type) {
        if (type === "daily")
            return plasmoidItem.trf("%1 / %2", plasmoidItem.formatTemperature(item.temperature_2m_max, false), plasmoidItem.formatTemperature(item.temperature_2m_min, true));

        return plasmoidItem.formatTemperature(item.temperature_2m, true);
    }

    function detailKindLabel(type) {
        return type === "daily" ? plasmoidItem.tr("Daily details") : plasmoidItem.tr("Hourly details");
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
            return;

        if (activeDetailType === "daily")
            selectDaily(model[nextIndex]);
        else
            selectHourly(model[nextIndex]);
        reportFlick.contentY = 0;
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 22
    Layout.preferredWidth: Kirigami.Units.gridUnit * 28
    Layout.preferredHeight: Kirigami.Units.gridUnit * 34
    collapseMarginsHint: true

    Kirigami.Action {
        id: retryAction

        text: plasmoidItem.tr("Retry")
        icon.name: "view-refresh"
        onTriggered: fullRoot.plasmoidItem.refreshWeather()
    }

    Kirigami.Action {
        id: configureAction

        text: plasmoidItem.tr("Configure…")
        icon.name: "configure"
        onTriggered: Plasmoid.internalAction("configure").trigger()
    }

    Shortcut {
        enabled: fullRoot.detailViewOpen && !fullRoot.conditionDetailOpen
        sequence: "Left"
        onActivated: {
            if (fullRoot.canStepDetail(-1))
                fullRoot.stepDetail(-1);
        }
    }

    Shortcut {
        enabled: fullRoot.detailViewOpen && !fullRoot.conditionDetailOpen
        sequence: "Right"
        onActivated: {
            if (fullRoot.canStepDetail(1))
                fullRoot.stepDetail(1);
        }
    }

    Shortcut {
        enabled: fullRoot.detailViewOpen
        sequences: ["Backspace", StandardKey.Back]
        onActivated: {
            if (fullRoot.conditionDetailOpen)
                fullRoot.closeConditionDetail();
            else
                fullRoot.closeDetail();
        }
    }

    Connections {
        target: fullRoot.plasmoidItem

        function onHourlyForecastChanged() {
            if (fullRoot.selectedReportKey.length === 0 && fullRoot.plasmoidItem.hourlyForecast.length > 0)
                fullRoot.selectHourly(fullRoot.plasmoidItem.hourlyForecast[0]);
        }
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

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y;
                    const maxY = Math.max(0, reportFlick.contentHeight - reportFlick.height);
                    reportFlick.cancelFlick();
                    reportFlick.contentY = Math.max(0, Math.min(maxY, reportFlick.contentY - delta));
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: reportLayout

                x: Kirigami.Units.largeSpacing
                y: Kirigami.Units.largeSpacing
                width: reportFlick.width - Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.PlaceholderMessage {
                    visible: !fullRoot.plasmoidItem.hasData
                    text: fullRoot.plasmoidItem.errorText.length > 0 ? fullRoot.plasmoidItem.errorText : plasmoidItem.tr("Waiting for weather data")
                    iconName: fullRoot.plasmoidItem.errorText.length > 0 ? "emblem-warning" : fullRoot.plasmoidItem.weatherIcon
                    helpfulAction: fullRoot.plasmoidItem.errorText.length > 0 ? (fullRoot.plasmoidItem.configError ? configureAction : retryAction) : null
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                }

                Rectangle {
                    visible: fullRoot.plasmoidItem.hasData && fullRoot.plasmoidItem.errorText.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? Kirigami.Units.gridUnit * 1.8 : 0
                    color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.negativeTextColor, 0.15)
                    radius: Kirigami.Units.smallSpacing

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: "emblem-warning"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }

                        PlasmaComponents3.Label {
                            text: plasmoidItem.trf("Update failed: %1", fullRoot.plasmoidItem.errorText)
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                DetailView {
                    visible: fullRoot.plasmoidItem.hasData && fullRoot.detailViewOpen && !fullRoot.conditionDetailOpen
                    plasmoidItem: fullRoot.plasmoidItem
                    host: fullRoot
                }

                ConditionDetailView {
                    visible: fullRoot.plasmoidItem.hasData && fullRoot.detailViewOpen && fullRoot.conditionDetailOpen
                    plasmoidItem: fullRoot.plasmoidItem
                    host: fullRoot
                    reportItem: fullRoot.activeDetailItem
                    hourly: fullRoot.activeDetailType === "hourly"
                    conditionKey: fullRoot.selectedConditionKey
                }

                OverviewView {
                    id: overviewView

                    visible: fullRoot.plasmoidItem.hasData && !fullRoot.detailViewOpen
                    plasmoidItem: fullRoot.plasmoidItem
                    host: fullRoot
                    hourCardWidth: fullRoot.hourCardWidth
                    hourCardSpacing: fullRoot.hourCardSpacing
                    chartSectionHeight: fullRoot.chartSectionHeight
                    hourStripHeight: fullRoot.hourStripHeight
                }
            }
        }
    }

    footer: PlasmaExtras.PlasmoidHeading {
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                text: plasmoidItem.tr("Refresh")
                icon.name: "view-refresh"
                enabled: !fullRoot.plasmoidItem.loading
                onClicked: fullRoot.plasmoidItem.refreshWeather()
            }

            PlasmaComponents3.Label {
                text: plasmoidItem.tr("Open-Meteo")
                opacity: 0.72
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
        }
    }
}
