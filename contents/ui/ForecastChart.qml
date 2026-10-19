import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: root

    required property var plasmoidItem
    property var model: []
    property string chartMode: "hourly"
    property int hoveredIndex: -1
    property int nowIndex: -1
    property int visibleCount: model.length
    property int wheelNotchSteps: 1
    property bool followNow: false
    property real windowStart: -1
    property real windowLength: 0
    readonly property alias flickable: plotFlick

    signal pointActivated(var item)

    readonly property real chartTop: Kirigami.Units.smallSpacing
    readonly property real chartLeft: Kirigami.Units.gridUnit * 1.7
    readonly property real chartRight: Kirigami.Units.smallSpacing
    readonly property real labelHeight: Kirigami.Units.gridUnit * 1.25
    readonly property real chartBottom: labelHeight + Kirigami.Units.smallSpacing
    readonly property real plotWidth: Math.max(1, width - chartLeft - chartRight)
    readonly property real plotHeight: Math.max(1, height - chartTop - chartBottom)
    readonly property real edgePad: Kirigami.Units.gridUnit
    readonly property int shownCount: Math.max(1, Math.min(visibleCount, model.length))
    readonly property real pointSpacing: shownCount > 1 ? Math.max(1, plotWidth - edgePad * 2) / (shownCount - 1) : 0
    readonly property real leadingIndex: pointSpacing > 0 ? plotFlick.contentX / pointSpacing : 0
    readonly property int pastEnd: nowIndex > 0 ? nowIndex : -1
    readonly property int futureStart: Math.max(0, nowIndex)
    readonly property real minTemp: computeMinTemperature()
    readonly property real maxTemp: computeMaxTemperature()
    readonly property real paddedLow: minTemp - Math.max(1, (maxTemp - minTemp) * 0.12)
    readonly property real paddedHigh: maxTemp + Math.max(1, (maxTemp - minTemp) * 0.12)
    readonly property real labelFontSize: Math.max(10, Kirigami.Units.gridUnit * 0.58)
    readonly property var hoveredItem: hoveredIndex >= 0 && hoveredIndex < model.length ? model[hoveredIndex] : null

    readonly property var pastHighPoints: pointsForField("temperature_2m_max", 0, pastEnd)
    readonly property var highPoints: pointsForField("temperature_2m_max", futureStart, model.length - 1)
    readonly property var pastLowPoints: pointsForField("temperature_2m_min", 0, pastEnd)
    readonly property var lowPoints: pointsForField("temperature_2m_min", futureStart, model.length - 1)
    readonly property var pastHourlyPoints: pointsForField("temperature_2m", 0, pastEnd)
    readonly property var hourlyPoints: pointsForField("temperature_2m", futureStart, model.length - 1)
    readonly property string pastBandSvg: bandSvgPath(0, pastEnd)
    readonly property string bandSvg: bandSvgPath(futureStart, model.length - 1)

    function numberAt(item, fieldName) {
        const value = Number(item ? item[fieldName] : undefined);
        return Number.isFinite(value) ? value : undefined;
    }

    function temperatureValues() {
        const values = [];
        for (let index = 0; index < model.length; index++) {
            if (chartMode === "daily") {
                const low = numberAt(model[index], "temperature_2m_min");
                const high = numberAt(model[index], "temperature_2m_max");
                if (Number.isFinite(low))
                    values.push(low);
                if (Number.isFinite(high))
                    values.push(high);
            } else {
                const value = numberAt(model[index], "temperature_2m");
                if (Number.isFinite(value))
                    values.push(value);
            }
        }
        return values;
    }

    function computeMinTemperature() {
        const values = temperatureValues();
        let result = Number.POSITIVE_INFINITY;
        for (let index = 0; index < values.length; index++)
            result = Math.min(result, values[index]);
        return Number.isFinite(result) ? result : 0;
    }

    function computeMaxTemperature() {
        const values = temperatureValues();
        let result = Number.NEGATIVE_INFINITY;
        for (let index = 0; index < values.length; index++)
            result = Math.max(result, values[index]);
        return Number.isFinite(result) ? result : 1;
    }

    function yFor(value) {
        const range = Math.max(1, paddedHigh - paddedLow);
        return chartTop + plotHeight - ((value - paddedLow) / range) * plotHeight;
    }

    // Content coordinates inside plotFlick.
    function xFor(index) {
        if (model.length <= 1)
            return plotWidth / 2;

        return edgePad + pointSpacing * index;
    }

    function viewX(index) {
        return chartLeft + xFor(index) - plotFlick.contentX;
    }

    function isPast(index) {
        return nowIndex >= 0 && index < nowIndex;
    }

    function setLeadingIndex(index) {
        const maxX = Math.max(0, plotFlick.contentWidth - plotFlick.width);
        plotFlick.contentX = Math.max(0, Math.min(maxX, index * pointSpacing));
    }

    function scrollToNow() {
        if (nowIndex >= 0)
            setLeadingIndex(nowIndex);
    }

    onModelChanged: if (followNow)
        Qt.callLater(scrollToNow)
    onPointSpacingChanged: if (followNow)
        Qt.callLater(scrollToNow)

    function markerY(index) {
        if (index < 0 || index >= model.length)
            return chartTop + plotHeight / 2;
        if (chartMode === "daily") {
            const high = numberAt(model[index], "temperature_2m_max");
            return Number.isFinite(high) ? yFor(high) : chartTop + plotHeight / 2;
        }
        const value = numberAt(model[index], "temperature_2m");
        return Number.isFinite(value) ? yFor(value) : chartTop + plotHeight / 2;
    }

    function labelFor(item, index) {
        if (chartMode === "daily")
            return index === nowIndex ? plasmoidItem.dailyPrimaryLabel(item.date) : plasmoidItem.shortDate(item.date);

        if (index === nowIndex)
            return plasmoidItem.hourLabel(item.time);
        if (nowIndex >= 0 && Math.abs(index - nowIndex) < 3)
            return "";

        const hour = new Date(item.time).getHours();
        if (hour === 0)
            return plasmoidItem.dailySecondaryLabel(String(item.time).slice(0, 10));
        if (hour % 6 === 0)
            return plasmoidItem.hourLabel(item.time);

        return "";
    }

    function precipitationFor(item) {
        const probability = numberAt(item, chartMode === "daily" ? "precipitation_probability_max" : "precipitation_probability");
        return Number.isFinite(probability) ? Math.max(0, Math.min(100, probability)) : 0;
    }

    function tooltipTitle(item) {
        if (!item)
            return "";
        if (chartMode === "daily")
            return plasmoidItem.trf("%1, %2", plasmoidItem.dailyPrimaryLabel(item.date), plasmoidItem.dailySecondaryLabel(item.date));
        const hour = plasmoidItem.hourLabel(item.time);
        return isPast(hoveredIndex) || hoveredIndex - nowIndex >= 24
            ? plasmoidItem.trf("%1, %2", plasmoidItem.dailySecondaryLabel(String(item.time).slice(0, 10)), hour)
            : hour;
    }

    function tooltipWeatherDescription(item) {
        return item ? plasmoidItem.weatherDescription(item.weather_code) : "";
    }

    function tooltipTempValue(item) {
        if (!item)
            return "";
        if (chartMode === "daily")
            return plasmoidItem.trf("%1 / %2", plasmoidItem.formatTemperature(item.temperature_2m_max, false), plasmoidItem.formatTemperature(item.temperature_2m_min, true));
        return plasmoidItem.formatTemperature(item.temperature_2m, true);
    }

    function tooltipHighValue(item) {
        if (!item)
            return "";
        return plasmoidItem.formatTemperature(item.temperature_2m_max, true);
    }

    function tooltipLowValue(item) {
        if (!item)
            return "";
        return plasmoidItem.formatTemperature(item.temperature_2m_min, true);
    }

    function tooltipRainValue(item) {
        if (!item)
            return "";
        const probability = item[chartMode === "daily" ? "precipitation_probability_max" : "precipitation_probability"];
        return plasmoidItem.formatPercent(probability);
    }

    function indexAtX(contentPos) {
        if (model.length === 0)
            return -1;
        if (model.length === 1 || pointSpacing <= 0)
            return 0;
        return Math.max(0, Math.min(model.length - 1, Math.round((contentPos - edgePad) / pointSpacing)));
    }

    function pointsForField(fieldName, from, to) {
        const _deps = [width, height, model, chartMode, paddedLow, paddedHigh, pointSpacing];
        void _deps;
        const points = [];
        for (let index = Math.max(0, from); index <= to && index < model.length; index++) {
            const value = numberAt(model[index], fieldName);
            if (!Number.isFinite(value))
                continue;
            points.push(Qt.point(xFor(index), yFor(value)));
        }
        return points;
    }

    function bandSvgPath(from, to) {
        const _deps = [width, height, model, chartMode, paddedLow, paddedHigh, pointSpacing];
        void _deps;
        from = Math.max(0, from);
        to = Math.min(model.length - 1, to);
        if (chartMode !== "daily" || to < from)
            return "";

        let path = "";
        for (let index = from; index <= to; index++) {
            const highValue = numberAt(model[index], "temperature_2m_max");
            path += (index === from ? "M " : " L ") + xFor(index) + " " + yFor(highValue);
        }
        for (let index = to; index >= from; index--) {
            const lowValue = numberAt(model[index], "temperature_2m_min");
            path += " L " + xFor(index) + " " + yFor(lowValue);
        }
        return path + " Z";
    }

    implicitHeight: Kirigami.Units.gridUnit * 8

    Repeater {
        model: 3

        delegate: Item {
            required property int index
            readonly property real value: root.paddedLow + (root.paddedHigh - root.paddedLow) * index / 2
            readonly property real lineY: root.yFor(value)

            Rectangle {
                x: root.chartLeft
                y: lineY
                width: root.plotWidth
                height: 1
                color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.78)
                opacity: 0.62
            }

            Text {
                x: 0
                y: lineY - height / 2
                width: root.chartLeft - Kirigami.Units.smallSpacing
                horizontalAlignment: Text.AlignRight
                text: root.plasmoidItem.formatTemperature(value, false)
                color: Kirigami.Theme.textColor
                opacity: 0.62
                font.pixelSize: root.labelFontSize
            }
        }
    }

    Flickable {
        id: plotFlick

        x: root.chartLeft
        width: root.plotWidth
        height: root.height
        clip: true
        contentWidth: root.model.length > 1 ? root.edgePad * 2 + root.pointSpacing * (root.model.length - 1) : width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        onContentXChanged: root.hoveredIndex = -1

        HorizontalWheelHandler {
            flickable: plotFlick
            snapStep: root.pointSpacing
            notchSteps: root.wheelNotchSteps
        }

        Rectangle {
            visible: root.windowStart >= 0 && root.windowLength > 0
            x: root.xFor(root.windowStart) - root.pointSpacing / 2
            y: root.chartTop
            width: root.windowLength * root.pointSpacing
            height: root.plotHeight
            radius: Kirigami.Units.smallSpacing
            color: Qt.alpha(Kirigami.Theme.highlightColor, 0.08)
        }

        Repeater {
            model: root.model

            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property real precipitation: root.precipitationFor(modelData)
                readonly property real barWidth: Math.max(3, root.pointSpacing * 0.42)
                readonly property real barHeight: root.plotHeight * precipitation / 100

                x: root.xFor(index) - barWidth / 2
                y: root.chartTop + root.plotHeight - barHeight
                width: barWidth
                height: barHeight
                color: Kirigami.Theme.highlightColor
                opacity: (root.hoveredIndex === index ? 0.32 : 0.18) * (root.isPast(index) ? 0.55 : 1)
            }
        }

        Rectangle {
            visible: root.chartMode === "hourly" && root.nowIndex >= 0 && root.nowIndex < root.model.length
            x: root.xFor(root.nowIndex)
            y: root.chartTop
            width: 1
            height: root.plotHeight
            color: Kirigami.Theme.textColor
            opacity: 0.35
        }

        Shape {
            width: plotFlick.contentWidth
            height: plotFlick.height
            visible: root.chartMode === "daily"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(Kirigami.Theme.textColor, 0.08)
                strokeWidth: -1

                PathSvg {
                    path: root.pastBandSvg
                }
            }

            ShapePath {
                fillColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.22)
                strokeWidth: -1

                PathSvg {
                    path: root.bandSvg
                }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.38)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: root.pastHighPoints
                }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.22)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: root.pastLowPoints
                }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.95)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: root.highPoints
                }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.42)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: root.lowPoints
                }
            }
        }

        Shape {
            width: plotFlick.contentWidth
            height: plotFlick.height
            visible: root.chartMode === "hourly"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.38)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: root.pastHourlyPoints
                }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Kirigami.Theme.highlightColor, 0.95)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: root.hourlyPoints
                }
            }
        }

        Repeater {
            model: root.model

            delegate: Text {
                required property var modelData
                required property int index
                readonly property string label: root.labelFor(modelData, index)

                visible: label.length > 0
                x: root.xFor(index) - width / 2
                y: root.height - root.labelHeight
                text: label
                color: Kirigami.Theme.textColor
                opacity: root.hoveredIndex === index ? 1 : (root.isPast(index) ? 0.45 : 0.72)
                font.pixelSize: root.labelFontSize
                font.bold: root.hoveredIndex === index || index === root.nowIndex
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            visible: root.hoveredIndex >= 0
            x: root.xFor(root.hoveredIndex) - width / 2
            y: root.markerY(root.hoveredIndex) - height / 2
            width: Math.max(6, Kirigami.Units.smallSpacing * 1.8)
            height: width
            radius: width / 2
            color: Kirigami.Theme.highlightColor
            border.width: 1
            border.color: Kirigami.Theme.backgroundColor
            z: 2
        }

        MouseArea {
            width: plotFlick.contentWidth
            height: plotFlick.height
            hoverEnabled: true
            cursorShape: root.hoveredIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPositionChanged: mouse => {
                root.hoveredIndex = root.indexAtX(mouse.x);
            }
            onExited: root.hoveredIndex = -1
            onClicked: mouse => {
                const index = root.indexAtX(mouse.x);
                if (index >= 0)
                    root.pointActivated(root.model[index]);
            }
        }
    }

    Rectangle {
        id: tooltipCard

        readonly property int padH: Kirigami.Units.smallSpacing * 2
        readonly property int padV: Kirigami.Units.smallSpacing
        readonly property real maxWidth: root.width

        Kirigami.Theme.colorSet: Kirigami.Theme.Tooltip
        Kirigami.Theme.inherit: false
        visible: root.hoveredIndex >= 0 && root.hoveredItem
        z: 10
        width: Math.min(maxWidth, tooltipLabel.implicitWidth + padH * 2)
        height: tooltipLabel.implicitHeight + padV * 2
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.4)
        // Keep entirely inside the chart so it cannot sit under the hour strip below.
        x: {
            if (root.hoveredIndex < 0)
                return 0;
            const raw = root.viewX(root.hoveredIndex) - width / 2;
            return Math.max(0, Math.min(root.width - width, raw));
        }
        y: {
            if (root.hoveredIndex < 0)
                return 0;
            const gap = Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2));
            const marker = root.markerY(root.hoveredIndex);
            let preferred = marker - height - gap;
            if (preferred < 0)
                preferred = marker + gap;
            return Math.max(0, Math.min(root.height - height, preferred));
        }

        PlasmaComponents3.Label {
            id: tooltipLabel

            anchors.fill: parent
            anchors.leftMargin: tooltipCard.padH
            anchors.rightMargin: tooltipCard.padH
            anchors.topMargin: tooltipCard.padV
            anchors.bottomMargin: tooltipCard.padV
            text: {
                const item = root.hoveredItem;
                if (!item)
                    return "";
                const lines = [root.tooltipTitle(item), root.tooltipWeatherDescription(item)];
                if (root.chartMode === "daily") {
                    lines.push(plasmoidItem.trf("High %1", root.tooltipHighValue(item)));
                    lines.push(plasmoidItem.trf("Low %1", root.tooltipLowValue(item)));
                } else {
                    lines.push(plasmoidItem.trf("Temp %1", root.tooltipTempValue(item)));
                }
                lines.push(plasmoidItem.trf("Rain %1", root.tooltipRainValue(item)));
                return lines.join("\n");
            }
            font: Kirigami.Theme.smallFont
            wrapMode: Text.Wrap
            clip: true
            elide: Text.ElideRight
            maximumLineCount: 6
            lineHeight: 1.2
            lineHeightMode: Text.ProportionalHeight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
