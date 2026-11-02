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
    property int keyboardIndex: -1
    readonly property int selectedIndex: host.selectedReportType === "hourly" ? host.detailIndex("hourly", host.selectedReportItem) : -1
    readonly property int tabIndex: keyboardIndex >= 0 ? keyboardIndex : (selectedIndex >= 0 ? selectedIndex : plasmoidItem.hourlyNowIndex)

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

    function resetToNow() {
        keyboardIndex = -1;
        centerStripOn(plasmoidItem.hourlyNowIndex);
    }

    function scrollToCurrent() {
        const index = host.activeDetailType === "hourly" ? host.detailIndex("hourly", host.activeDetailItem) : -1;
        centerStripOn(index >= 0 ? index : plasmoidItem.hourlyNowIndex);
    }

    function ensureCardVisible(index) {
        const left = index * hourStep;
        const right = left + hourCardWidth;
        if (left < hourlyReportFlick.contentX)
            hourlyReportFlick.contentX = left;
        else if (right > hourlyReportFlick.contentX + hourlyReportFlick.width)
            hourlyReportFlick.contentX = right - hourlyReportFlick.width;
    }

    function navigateCards(from, offset) {
        const count = plasmoidItem.hourlyTimeline.length;
        if (count === 0)
            return;
        const target = offset === 0 ? plasmoidItem.hourlyNowIndex : Math.max(0, Math.min(count - 1, from + offset));
        const card = hourlyCards.itemAt(target);
        if (card)
            card.takeFocus();
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
            root.keyboardIndex = -1;
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
                id: hourlyCards

                model: root.plasmoidItem.hourlyTimeline

                delegate: HourlyReportCard {
                    required property int index

                    plasmoidItem: root.plasmoidItem
                    selected: root.host.isSelected("hourly", modelData)
                    past: index < root.plasmoidItem.hourlyNowIndex
                    tabStop: index === root.tabIndex
                    cardWidth: root.hourCardWidth
                    height: hourlyReportRow.height
                    onActivated: root.host.openHourlyDetail(modelData)
                    onNavigated: offset => root.navigateCards(index, offset)
                    onFocused: {
                        root.keyboardIndex = index;
                        root.ensureCardVisible(index);
                    }
                }
            }
        }
    }
}
