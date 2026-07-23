import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

RowLayout {
    id: root

    required property string title
    property string subtitle: ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    PlasmaExtras.Heading {
        text: root.title
        level: 3
        Layout.fillWidth: true
    }

    PlasmaComponents3.Label {
        visible: root.subtitle.length > 0
        text: root.subtitle
        opacity: 0.72
        horizontalAlignment: Text.AlignRight
    }
}
