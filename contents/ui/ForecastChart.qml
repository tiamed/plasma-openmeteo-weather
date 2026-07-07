import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var plasmoidItem
    property var model: []
    property string chartMode: "hourly"

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

    function minTemperature() {
        const values = temperatureValues();
        let result = Number.POSITIVE_INFINITY;
        for (let index = 0; index < values.length; index++) {
            result = Math.min(result, values[index]);
        }
        return Number.isFinite(result) ? result : 0;
    }

    function maxTemperature() {
        const values = temperatureValues();
        let result = Number.NEGATIVE_INFINITY;
        for (let index = 0; index < values.length; index++) {
            result = Math.max(result, values[index]);
        }
        return Number.isFinite(result) ? result : 1;
    }

    function yFor(value, top, chartHeight, minValue, maxValue) {
        const range = Math.max(1, maxValue - minValue);
        return top + chartHeight - ((value - minValue) / range) * chartHeight;
    }

    function xFor(index, left, chartWidth) {
        if (model.length <= 1)
            return left + chartWidth / 2;

        return left + chartWidth * index / (model.length - 1);
    }

    function labelFor(item, index) {
        if (chartMode === "daily")
            return plasmoidItem.shortDate(item.date);

        if (index === 0 || index === model.length - 1 || index % 6 === 0)
            return plasmoidItem.hourLabel(item.time);

        return "";
    }

    function precipitationFor(item) {
        const probability = numberAt(item, chartMode === "daily" ? "precipitation_probability_max" : "precipitation_probability");
        return Number.isFinite(probability) ? Math.max(0, Math.min(100, probability)) : 0;
    }

    implicitHeight: Kirigami.Units.gridUnit * 8
    onModelChanged: chart.requestPaint()
    onChartModeChanged: chart.requestPaint()
    onWidthChanged: chart.requestPaint()
    onHeightChanged: chart.requestPaint()

    Canvas {
        id: chart

        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            const widthPx = width;
            const heightPx = height;
            const top = Kirigami.Units.smallSpacing;
            const left = Kirigami.Units.gridUnit * 1.7;
            const right = Kirigami.Units.smallSpacing;
            const labelHeight = Kirigami.Units.gridUnit * 1.25;
            const bottom = labelHeight + Kirigami.Units.smallSpacing;
            const chartWidth = Math.max(1, widthPx - left - right);
            const chartHeight = Math.max(1, heightPx - top - bottom);
            const low = root.minTemperature();
            const high = root.maxTemperature();
            const paddedLow = low - Math.max(1, (high - low) * 0.12);
            const paddedHigh = high + Math.max(1, (high - low) * 0.12);
            ctx.clearRect(0, 0, widthPx, heightPx);
            ctx.lineWidth = 1;
            ctx.strokeStyle = Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.78);
            ctx.fillStyle = Kirigami.Theme.textColor;
            ctx.globalAlpha = 0.62;
            ctx.font = Math.max(10, Kirigami.Units.gridUnit * 0.58) + "px sans-serif";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            for (let step = 0; step < 3; step++) {
                const value = paddedLow + (paddedHigh - paddedLow) * step / 2;
                const y = yFor(value, top, chartHeight, paddedLow, paddedHigh);
                ctx.beginPath();
                ctx.moveTo(left, y);
                ctx.lineTo(left + chartWidth, y);
                ctx.stroke();
                ctx.fillText(root.plasmoidItem.formatTemperature(value, false), left - Kirigami.Units.smallSpacing, y);
            }
            ctx.globalAlpha = 0.18;
            ctx.fillStyle = Kirigami.Theme.highlightColor;
            for (let index = 0; index < root.model.length; index++) {
                const precipitation = precipitationFor(root.model[index]);
                const barWidth = Math.max(3, chartWidth / Math.max(8, root.model.length) * 0.42);
                const barHeight = chartHeight * precipitation / 100;
                const x = xFor(index, left, chartWidth) - barWidth / 2;
                ctx.fillRect(x, top + chartHeight - barHeight, barWidth, barHeight);
            }
            if (root.chartMode === "daily") {
                ctx.globalAlpha = 0.22;
                ctx.fillStyle = Kirigami.Theme.highlightColor;
                ctx.beginPath();
                for (let index = 0; index < root.model.length; index++) {
                    const highValue = numberAt(root.model[index], "temperature_2m_max");
                    const x = xFor(index, left, chartWidth);
                    const y = yFor(highValue, top, chartHeight, paddedLow, paddedHigh);
                    if (index === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                for (let index = root.model.length - 1; index >= 0; index--) {
                    const lowValue = numberAt(root.model[index], "temperature_2m_min");
                    const x = xFor(index, left, chartWidth);
                    const y = yFor(lowValue, top, chartHeight, paddedLow, paddedHigh);
                    ctx.lineTo(x, y);
                }
                ctx.closePath();
                ctx.fill();
            }
            const drawLine = function drawLine(fieldName, color, alpha) {
                ctx.globalAlpha = alpha;
                ctx.strokeStyle = color;
                ctx.lineWidth = 2;
                ctx.beginPath();
                let hasPoint = false;
                for (let index = 0; index < root.model.length; index++) {
                    const value = numberAt(root.model[index], fieldName);
                    if (!Number.isFinite(value))
                        continue;

                    const x = xFor(index, left, chartWidth);
                    const y = yFor(value, top, chartHeight, paddedLow, paddedHigh);
                    if (!hasPoint) {
                        ctx.moveTo(x, y);
                        hasPoint = true;
                    } else {
                        ctx.lineTo(x, y);
                    }
                }
                ctx.stroke();
            };
            if (root.chartMode === "daily") {
                drawLine("temperature_2m_max", Kirigami.Theme.highlightColor, 0.95);
                drawLine("temperature_2m_min", Kirigami.Theme.textColor, 0.42);
            } else {
                drawLine("temperature_2m", Kirigami.Theme.highlightColor, 0.95);
            }
            ctx.globalAlpha = 0.72;
            ctx.fillStyle = Kirigami.Theme.textColor;
            ctx.font = Math.max(10, Kirigami.Units.gridUnit * 0.58) + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "top";
            for (let index = 0; index < root.model.length; index++) {
                const label = labelFor(root.model[index], index);
                if (label.length === 0)
                    continue;

                ctx.fillText(label, xFor(index, left, chartWidth), heightPx - labelHeight);
            }
        }
    }

}
