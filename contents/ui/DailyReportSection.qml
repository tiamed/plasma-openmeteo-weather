import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: root

    required property var plasmoidItem
    required property var host
    required property real chartSectionHeight

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    ReportSectionHeader {
        title: plasmoidItem.tr("Daily Report")
        subtitle: plasmoidItem.tr("7 days")
    }

    SectionCard {
        Layout.fillWidth: true
        Layout.preferredHeight: root.chartSectionHeight

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                text: plasmoidItem.tr("High / low")
                font.bold: true
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: plasmoidItem.tr("Daily rain")
                opacity: 0.72
                horizontalAlignment: Text.AlignRight
            }
        }

        ForecastChart {
            plasmoidItem: root.plasmoidItem
            model: root.plasmoidItem.dailyForecast
            chartMode: "daily"
            Layout.fillWidth: true
            Layout.fillHeight: true
            onPointActivated: item => root.host.openDailyDetail(item)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: root.plasmoidItem.dailyForecast

            delegate: DailyReportCard {
                plasmoidItem: root.plasmoidItem
                selected: root.host.isSelected("daily", modelData)
                onActivated: root.host.openDailyDetail(modelData)
            }
        }
    }
}
