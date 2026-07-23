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

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    function scrollSelectedIntoView(item) {
        const index = host.detailIndex("hourly", item);
        if (index < 0)
            return;
        const step = hourCardWidth + hourCardSpacing;
        const maxX = Math.max(0, hourlyReportFlick.contentWidth - hourlyReportFlick.width);
        const targetX = index * step - (hourlyReportFlick.width - hourCardWidth) / 2;
        hourlyReportFlick.contentX = Math.max(0, Math.min(maxX, targetX));
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
            plasmoidItem: root.plasmoidItem
            model: root.plasmoidItem.hourlyForecast
            chartMode: "hourly"
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
        boundsBehavior: Flickable.DragAndOvershootBounds
        interactive: contentWidth > width

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const isShift = (event.modifiers & Qt.ShiftModifier) !== 0;
                const horizontalDelta = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.angleDelta.x;
                const verticalDelta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y;
                let delta = 0;
                if (horizontalDelta !== 0)
                    delta = horizontalDelta;
                else if (isShift && verticalDelta !== 0)
                    delta = verticalDelta;
                else {
                    event.accepted = false;
                    return;
                }
                const maxX = Math.max(0, hourlyReportFlick.contentWidth - hourlyReportFlick.width);
                const nextX = Math.max(0, Math.min(maxX, hourlyReportFlick.contentX - delta));
                if (nextX !== hourlyReportFlick.contentX) {
                    hourlyReportFlick.cancelFlick();
                    hourlyReportFlick.contentX = nextX;
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
        }

        Row {
            id: hourlyReportRow

            height: hourlyReportFlick.height
            spacing: root.hourCardSpacing

            Repeater {
                model: root.plasmoidItem.hourlyForecast

                delegate: HourlyReportCard {
                    plasmoidItem: root.plasmoidItem
                    selected: root.host.isSelected("hourly", modelData)
                    cardWidth: root.hourCardWidth
                    height: hourlyReportRow.height
                    onActivated: root.host.openHourlyDetail(modelData)
                }
            }
        }
    }
}
