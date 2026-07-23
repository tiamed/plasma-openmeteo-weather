import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Flickable {
    id: root

    required property var plasmoidItem
    required property var model
    required property string conditionKey
    required property bool hourly
    required property var reportItem
    property real cardWidth: Kirigami.Units.gridUnit * 4.7
    property real cardSpacing: Kirigami.Units.smallSpacing

    signal pointActivated(var item)

    clip: true
    contentWidth: cardRow.implicitWidth
    contentHeight: height
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.DragAndOvershootBounds
    interactive: contentWidth > width
    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 5.8

    function isSelected(item) {
        if (!item || !reportItem)
            return false;
        return hourly ? item.time === reportItem.time : item.date === reportItem.date;
    }

    function titleFor(item) {
        return hourly ? plasmoidItem.hourLabel(item.time) : plasmoidItem.dailyPrimaryLabel(item.date);
    }

    function subtitleFor(item) {
        switch (conditionKey) {
        case "condition":
            return plasmoidItem.weatherDescription(item.weather_code);
        case "sunrise":
            return plasmoidItem.shortTime(item.sunrise);
        case "sunset":
            return plasmoidItem.shortTime(item.sunset);
        default:
            return "";
        }
    }

    function footerFor(item) {
        return hourly ? plasmoidItem.shortTime(item.time) : plasmoidItem.dailySecondaryLabel(item.date);
    }

    function iconFor(item) {
        switch (conditionKey) {
        case "condition":
            return plasmoidItem.weatherIconName(item.weather_code, hourly ? item.is_day !== 0 : true, false);
        case "sunrise":
            return plasmoidItem.metricIconName("sunrise", false);
        case "sunset":
            return plasmoidItem.metricIconName("sunset", false);
        default:
            return "";
        }
    }

    function scrollSelectedIntoView() {
        let index = -1;
        for (let i = 0; i < model.length; i++) {
            if (isSelected(model[i])) {
                index = i;
                break;
            }
        }
        if (index < 0)
            return;
        const step = cardWidth + cardSpacing;
        const maxX = Math.max(0, contentWidth - width);
        const targetX = index * step - (width - cardWidth) / 2;
        contentX = Math.max(0, Math.min(maxX, targetX));
    }

    onReportItemChanged: Qt.callLater(scrollSelectedIntoView)
    onModelChanged: Qt.callLater(scrollSelectedIntoView)
    Component.onCompleted: Qt.callLater(scrollSelectedIntoView)

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
            const maxX = Math.max(0, root.contentWidth - root.width);
            const nextX = Math.max(0, Math.min(maxX, root.contentX - delta));
            if (nextX !== root.contentX) {
                root.cancelFlick();
                root.contentX = nextX;
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }
    }

    Row {
        id: cardRow

        height: root.height
        spacing: root.cardSpacing

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: trendCard

                required property var modelData
                readonly property bool selected: root.isSelected(modelData)
                readonly property string iconSource: root.iconFor(modelData)
                readonly property bool fileIcon: iconSource.startsWith("file:") || iconSource.startsWith("/")

                width: root.cardWidth
                height: cardRow.height
                radius: Kirigami.Units.smallSpacing
                color: selected
                    ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.28)
                    : (cardMouse.containsMouse
                        ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.alternateBackgroundColor, Kirigami.Theme.textColor, 0.07)
                        : Kirigami.Theme.alternateBackgroundColor)
                border.width: cardMouse.activeFocus ? 2 : (selected ? 1 : 0)
                border.color: cardMouse.activeFocus ? Kirigami.Theme.focusColor : Kirigami.Theme.highlightColor

                Behavior on color {
                    ColorAnimation {
                        duration: Kirigami.Units.shortDuration
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 0

                    PlasmaComponents3.Label {
                        text: root.titleFor(trendCard.modelData)
                        font.bold: trendCard.selected
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                        Kirigami.Icon {
                            anchors.fill: parent
                            visible: !trendCard.fileIcon
                            source: trendCard.fileIcon ? "" : trendCard.iconSource
                        }

                        Image {
                            anchors.fill: parent
                            visible: trendCard.fileIcon
                            source: trendCard.fileIcon ? trendCard.iconSource : ""
                            sourceSize.width: Kirigami.Units.iconSizes.smallMedium
                            sourceSize.height: Kirigami.Units.iconSizes.smallMedium
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    PlasmaComponents3.Label {
                        text: root.subtitleFor(trendCard.modelData)
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    PlasmaComponents3.Label {
                        text: root.footerFor(trendCard.modelData)
                        opacity: 0.72
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: cardMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    activeFocusOnTab: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: plasmoidItem.trf("%1, %2", root.titleFor(trendCard.modelData), root.subtitleFor(trendCard.modelData))
                    Accessible.onPressAction: root.pointActivated(trendCard.modelData)
                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Space:
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                        case Qt.Key_Select:
                            root.pointActivated(trendCard.modelData);
                            event.accepted = true;
                            break;
                        }
                    }
                    onPressed: forceActiveFocus()
                    onClicked: root.pointActivated(trendCard.modelData)
                }
            }
        }
    }
}
