import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: root

    required property var plasmoidItem
    required property var host
    required property real hourCardWidth
    required property real hourCardSpacing
    required property real chartSectionHeight
    required property real hourStripHeight

    readonly property real hourStep: hourCardWidth + hourCardSpacing
    property bool syncing: false

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    function centerStripOn(index) {
        const maxX = Math.max(0, hourlyReportFlick.contentWidth - hourlyReportFlick.width);
        const targetX = index * hourStep - (hourlyReportFlick.width - hourCardWidth) / 2;
        hourlyReportFlick.contentX = Math.max(0, Math.min(maxX, targetX));
    }

    function scrollSelectedIntoView(item) {
        const index = host.detailIndex("hourly", item);
        if (index >= 0)
            centerStripOn(index);
    }

    function scrollToCurrent() {
        const index = host.activeDetailType === "hourly" ? host.detailIndex("hourly", host.activeDetailItem) : -1;
        centerStripOn(index >= 0 ? index : plasmoidItem.hourlyNowIndex);
    }

    function syncChartFromStrip() {
        if (syncing)
            return;
        syncing = true;
        hourlyChart.setLeadingIndex(hourlyReportFlick.contentX / hourStep);
        syncing = false;
    }

    function syncStripFromChart() {
        if (syncing)
            return;
        syncing = true;
        const maxX = Math.max(0, hourlyReportFlick.contentWidth - hourlyReportFlick.width);
        hourlyReportFlick.contentX = Math.max(0, Math.min(maxX, hourlyChart.leadingIndex * hourStep));
        syncing = false;
    }

    Connections {
        target: root.plasmoidItem

        function onHourlyTimelineChanged() {
            Qt.callLater(root.scrollToCurrent);
        }
    }

    Connections {
        target: hourlyReportFlick

        function onContentXChanged() {
            root.syncChartFromStrip();
        }
    }

    Connections {
        target: hourlyChart.flickable

        function onContentXChanged() {
            root.syncStripFromChart();
        }
    }

    Connections {
        target: hourlyChart

        function onPointSpacingChanged() {
            Qt.callLater(root.syncChartFromStrip);
        }
    }

    ReportSectionHeader {
        title: plasmoidItem.tr("Hourly Report")
        subtitle: plasmoidItem.tr("24 hours")
    }

    SectionCard {
        Layout.fillWidth: true
        Layout.preferredHeight: root.chartSectionHeight

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: plasmoidItem.tr("Temperature")
                font.bold: true
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: plasmoidItem.tr("Rain chance")
                opacity: 0.72
                horizontalAlignment: Text.AlignRight
            }
        }

        ForecastChart {
            id: hourlyChart

            plasmoidItem: root.plasmoidItem
            model: root.plasmoidItem.hourlyTimeline
            nowIndex: root.plasmoidItem.hourlyNowIndex
            chartMode: "hourly"
            visibleCount: 24
            wheelNotchSteps: 3
            windowStart: hourlyReportFlick.contentX / root.hourStep
            windowLength: hourlyReportFlick.width / root.hourStep
            Layout.fillWidth: true
            Layout.fillHeight: true
            onPointActivated: item => root.host.openHourlyDetail(item)
        }
    }

    Flickable {
        id: hourlyReportFlick

        Layout.fillWidth: true
        Layout.preferredHeight: root.hourStripHeight
        clip: true
        contentWidth: hourlyReportRow.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width

        HorizontalWheelHandler {
            flickable: hourlyReportFlick
            snapStep: root.hourStep
        }

        Row {
            id: hourlyReportRow

            height: hourlyReportFlick.height
            spacing: root.hourCardSpacing

            Repeater {
                model: root.plasmoidItem.hourlyTimeline

                delegate: HourlyReportCard {
                    required property int index

                    plasmoidItem: root.plasmoidItem
                    selected: root.host.isSelected("hourly", modelData)
                    past: index < root.plasmoidItem.hourlyNowIndex
                    cardWidth: root.hourCardWidth
                    height: hourlyReportRow.height
                    onActivated: root.host.openHourlyDetail(modelData)
                }
            }
        }
    }
}
