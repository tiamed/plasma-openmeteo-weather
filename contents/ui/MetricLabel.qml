import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: root

    required property string label
    required property string value

    spacing: 0

    PlasmaComponents3.Label {
        text: root.value
        font.bold: true
        maximumLineCount: 1
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }

    PlasmaComponents3.Label {
        text: root.label
        opacity: 0.72
        maximumLineCount: 1
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }
}
