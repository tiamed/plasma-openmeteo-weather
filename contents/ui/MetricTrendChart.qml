import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var plasmoidItem
    required property var model
    required property string conditionKey
    required property bool hourly
    required property var reportItem

    signal pointActivated(var item)

    property int hoveredIndex: -1
    readonly property real leftMargin: Kirigami.Units.gridUnit * 2.1
    readonly property real rightMargin: Kirigami.Units.smallSpacing
    readonly property real topMargin: Kirigami.Units.smallSpacing
    readonly property real bottomMargin: Kirigami.Units.gridUnit * 1.35
    readonly property real plotWidth: Math.max(1, width - leftMargin - rightMargin)
    readonly property real plotHeight: Math.max(1, height - topMargin - bottomMargin)
    readonly property real low: minimum()
    readonly property real high: maximum()
    readonly property real paddedLow: low - Math.max(1, (high - low) * 0.12)
    readonly property real paddedHigh: high + Math.max(1, (high - low) * 0.12)
    readonly property var points: chartPoints()
    readonly property var hoveredItem: hoveredIndex >= 0 && hoveredIndex < model.length ? model[hoveredIndex] : null

    function valueFor(item) {
        if (!item)
            return NaN;
        switch (conditionKey) {
        case "feelsLike": return Number(item.apparent_temperature);
        case "humidity": return Number(item.relative_humidity_2m);
        case "rainChance": return Number(hourly ? item.precipitation_probability : item.precipitation_probability_max);
        case "rainAmount": return Number(hourly ? item.precipitation : item.precipitation_sum);
        case "wind": return Number(item.wind_speed_10m);
        case "maxWind": return Number(item.wind_speed_10m_max);
        case "uv": return Number(hourly ? item.uv_index : item.uv_index_max);
        case "airQuality": return Number(item.european_aqi);
        default: return NaN;
        }
    }

    function minimum() {
        let result = Number.POSITIVE_INFINITY;
        for (let index = 0; index < model.length; index++) {
            const value = valueFor(model[index]);
            if (Number.isFinite(value))
                result = Math.min(result, value);
        }
        return Number.isFinite(result) ? result : 0;
    }

    function maximum() {
        let result = Number.NEGATIVE_INFINITY;
        for (let index = 0; index < model.length; index++) {
            const value = valueFor(model[index]);
            if (Number.isFinite(value))
                result = Math.max(result, value);
        }
        return Number.isFinite(result) ? result : 1;
    }

    function xFor(index) {
        return model.length <= 1 ? leftMargin + plotWidth / 2 : leftMargin + plotWidth * index / (model.length - 1);
    }

    function yFor(value) {
        const span = Math.max(1, paddedHigh - paddedLow);
        return topMargin + plotHeight - (value - paddedLow) / span * plotHeight;
    }

    function chartPoints() {
        const points = [];
        const _deps = [width, height, model, conditionKey, hourly, paddedLow, paddedHigh];
        void _deps;
        for (let index = 0; index < model.length; index++) {
            const value = valueFor(model[index]);
            if (Number.isFinite(value))
                points.push(Qt.point(xFor(index), yFor(value)));
        }
        return points;
    }

    function indexAtX(xPos) {
        if (model.length === 0 || xPos < leftMargin || xPos > leftMargin + plotWidth)
            return -1;
        return model.length <= 1 ? 0 : Math.max(0, Math.min(model.length - 1, Math.round((xPos - leftMargin) / plotWidth * (model.length - 1))));
    }

    function selectedIndex() {
        if (!reportItem)
            return -1;
        for (let index = 0; index < model.length; index++) {
            if (hourly ? model[index].time === reportItem.time : model[index].date === reportItem.date)
                return index;
        }
        return -1;
    }

    function labelFor(item, index) {
        if (hourly)
            return index === 0 || index === model.length - 1 || index % 6 === 0 ? plasmoidItem.hourLabel(item.time) : "";
        return plasmoidItem.shortDate(item.date);
    }

    function valueText(item) {
        const value = valueFor(item);
        switch (conditionKey) {
        case "feelsLike": return plasmoidItem.formatTemperature(value, true);
        case "humidity":
        case "rainChance": return plasmoidItem.formatPercent(value);
        case "rainAmount": return plasmoidItem.formatLength(value);
        case "wind":
        case "maxWind": return plasmoidItem.formatWind(value);
        case "uv": return plasmoidItem.formatUv(value);
        case "airQuality": return plasmoidItem.formatAirQuality(value);
        default: return "--";
        }
    }

    implicitHeight: Kirigami.Units.gridUnit * 9
    Accessible.name: plasmoidItem.trf("%1 trend chart", conditionKey)

    Repeater {
        model: 3
        delegate: Item {
            required property int index
            readonly property real value: root.paddedLow + (root.paddedHigh - root.paddedLow) * index / 2
            readonly property real lineY: root.yFor(value)

            Rectangle {
                x: root.leftMargin
                y: lineY
                width: root.plotWidth
                height: 1
                color: Kirigami.Theme.disabledTextColor
                opacity: 0.4
            }

            Text {
                x: 0
                y: lineY - height / 2
                width: root.leftMargin - Kirigami.Units.smallSpacing
                horizontalAlignment: Text.AlignRight
                text: root.valueText({
                    apparent_temperature: value,
                    relative_humidity_2m: value,
                    precipitation_probability: value,
                    precipitation_probability_max: value,
                    precipitation: value,
                    precipitation_sum: value,
                    wind_speed_10m: value,
                    wind_speed_10m_max: value,
                    uv_index: value,
                    uv_index_max: value
                })
                color: Kirigami.Theme.textColor
                opacity: 0.64
                font: Kirigami.Theme.smallFont
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 2
            strokeColor: Kirigami.Theme.highlightColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline { path: root.points }
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
            y: root.height - root.bottomMargin + Kirigami.Units.smallSpacing / 2
            text: label
            color: Kirigami.Theme.textColor
            opacity: root.hoveredIndex === index || root.selectedIndex() === index ? 1 : 0.72
            font: Kirigami.Theme.smallFont
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Rectangle {
        visible: root.selectedIndex() >= 0
        x: root.xFor(root.selectedIndex()) - width / 2
        y: root.yFor(root.valueFor(root.model[root.selectedIndex()])) - height / 2
        width: Kirigami.Units.smallSpacing * 2
        height: width
        radius: width / 2
        color: Kirigami.Theme.highlightColor
        border.width: 1
        border.color: Kirigami.Theme.backgroundColor
        z: 3
    }

    Rectangle {
        visible: root.hoveredItem !== null
        x: Math.max(0, Math.min(root.width - width, root.xFor(root.hoveredIndex) - width / 2))
        y: Math.max(0, root.yFor(root.valueFor(root.hoveredItem)) - height - Kirigami.Units.smallSpacing)
        width: tooltipLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
        height: tooltipLabel.implicitHeight + Kirigami.Units.smallSpacing
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.Theme.highlightColor
        z: 4

        Text {
            id: tooltipLabel
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            text: root.hoveredItem ? root.valueText(root.hoveredItem) : ""
            color: Kirigami.Theme.textColor
            font: Kirigami.Theme.smallFont
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.hoveredIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPositionChanged: mouse => root.hoveredIndex = root.indexAtX(mouse.x)
        onExited: root.hoveredIndex = -1
        onClicked: mouse => {
            const index = root.indexAtX(mouse.x);
            if (index >= 0)
                root.pointActivated(root.model[index]);
        }
    }
}
