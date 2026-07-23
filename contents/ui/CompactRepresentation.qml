import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

MouseArea {
    id: compactRoot

    required property var plasmoidItem

    readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool showText: horizontalPanel && Plasmoid.configuration.showPanelText
    readonly property int iconSize: Math.max(Kirigami.Units.iconSizes.small, Math.min(Kirigami.Units.iconSizes.smallMedium, height - Kirigami.Units.smallSpacing))
    readonly property bool loading: plasmoidItem.loading
    property bool refreshFlash: false

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    activeFocusOnTab: true

    Layout.minimumWidth: horizontalPanel ? Kirigami.Units.gridUnit * 3 : Kirigami.Units.iconSizes.small
    Layout.preferredWidth: showText ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.iconSizes.smallMedium
    Layout.maximumWidth: showText ? Kirigami.Units.gridUnit * 7 : Kirigami.Units.iconSizes.medium
    Layout.minimumHeight: verticalPanel ? width : Kirigami.Units.iconSizes.small
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

    Accessible.name: Plasmoid.title
    Accessible.description: plasmoidItem.toolTipSubText
    Accessible.role: Accessible.Button

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            compactRoot.plasmoidItem.expanded = !compactRoot.plasmoidItem.expanded;
            event.accepted = true;
            break;
        }
    }

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            plasmoidItem.expanded = !plasmoidItem.expanded;
        } else if (mouse.button === Qt.MiddleButton) {
            compactRoot.refreshFlash = true;
            refreshFlashTimer.restart();
            plasmoidItem.refreshWeather();
        }
    }

    Timer {
        id: refreshFlashTimer

        interval: Kirigami.Units.humanMoment
        onTriggered: compactRoot.refreshFlash = false
    }

    SequentialAnimation {
        id: loadingPulse

        loops: Animation.Infinite
        running: compactRoot.loading
        onRunningChanged: {
            if (!running)
                weatherIcon.opacity = 1;
        }

        NumberAnimation {
            target: weatherIcon
            property: "opacity"
            from: 1
            to: 0.35
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: weatherIcon
            property: "opacity"
            from: 0.35
            to: 1
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.highlightColor
        opacity: compactRoot.refreshFlash ? 0.35 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }
    }

    RowLayout {
        id: content

        anchors.centerIn: parent
        width: Math.min(parent.width, implicitWidth)
        height: parent.height
        spacing: Math.max(2, Kirigami.Units.smallSpacing)

        Kirigami.Icon {
            id: weatherIcon

            source: compactRoot.plasmoidItem.weatherIcon
            active: compactRoot.containsMouse
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: compactRoot.iconSize
            Layout.preferredHeight: compactRoot.iconSize
        }

        PlasmaComponents3.Label {
            visible: compactRoot.showText
            text: compactRoot.plasmoidItem.hasData ? compactRoot.plasmoidItem.tempText : "--"
            font.bold: true
            maximumLineCount: 1
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
            Layout.maximumWidth: compactRoot.width - compactRoot.iconSize - content.spacing
        }
    }
}
