.pragma library

function formatTemperature(value, withUnit, unitSymbol) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    return Math.round(number) + "\u00b0" + (withUnit ? unitSymbol : "");
}

function formatPercent(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    return Math.round(number) + "%";
}

function formatWind(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    return Math.round(number) + " km/h";
}

function formatLength(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    if (number < 1)
        return number.toFixed(1) + " mm";

    return Math.round(number) + " mm";
}

function formatUv(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    return Math.round(number).toString();
}

function formatAqi(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    return Math.round(number).toString();
}

function formatPm25(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "--";

    return Math.round(number) + " µg/m³";
}

function aqiLevelKey(value) {
    const number = Number(value);
    if (!Number.isFinite(number))
        return "";
    if (number <= 20)
        return "Good";
    if (number <= 40)
        return "Fair";
    if (number <= 60)
        return "Moderate";
    if (number <= 80)
        return "Poor";
    if (number <= 100)
        return "Very poor";
    return "Extremely poor";
}

function valueAt(values, index) {
    return values && values.length > index ? values[index] : undefined;
}

function dailyTemperatureLimit(dailyForecast, fieldName, fallback) {
    let result = fallback;
    for (let index = 0; index < dailyForecast.length; index++) {
        const value = Number(dailyForecast[index][fieldName]);
        if (!Number.isFinite(value))
            continue;

        if (!Number.isFinite(result))
            result = value;
        else if (fieldName === "temperature_2m_min")
            result = Math.min(result, value);
        else
            result = Math.max(result, value);
    }
    return Number.isFinite(result) ? result : 0;
}

function dailyRangeStart(dailyForecast, day) {
    const weekLow = dailyTemperatureLimit(dailyForecast, "temperature_2m_min", Number.POSITIVE_INFINITY);
    const weekHigh = dailyTemperatureLimit(dailyForecast, "temperature_2m_max", Number.NEGATIVE_INFINITY);
    const low = Number(day.temperature_2m_min);
    if (!Number.isFinite(low))
        return 0;

    return Math.max(0, Math.min(1, (low - weekLow) / Math.max(1, weekHigh - weekLow)));
}

function dailyRangeWidth(dailyForecast, day) {
    const weekLow = dailyTemperatureLimit(dailyForecast, "temperature_2m_min", Number.POSITIVE_INFINITY);
    const weekHigh = dailyTemperatureLimit(dailyForecast, "temperature_2m_max", Number.NEGATIVE_INFINITY);
    const low = Number(day.temperature_2m_min);
    const high = Number(day.temperature_2m_max);
    if (!Number.isFinite(low) || !Number.isFinite(high))
        return 0;

    const span = Math.max(1, weekHigh - weekLow);
    const start = dailyRangeStart(dailyForecast, day);
    const width = Math.max(0.08, (high - low) / span);
    return Math.max(0, Math.min(1 - start, width));
}

function isSameCalendarDay(date, other) {
    return date.getFullYear() === other.getFullYear()
        && date.getMonth() === other.getMonth()
        && date.getDate() === other.getDate();
}

function isToday(isoDate) {
    if (!isoDate)
        return false;

    return isSameCalendarDay(new Date(isoDate + "T00:00:00"), new Date());
}

function isCurrentHour(isoDateTime, windowMs) {
    if (!isoDateTime)
        return false;

    return Math.abs(new Date(isoDateTime).getTime() - Date.now()) < windowMs;
}
