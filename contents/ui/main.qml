import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property bool inPanel: [PlasmaCore.Types.TopEdge, PlasmaCore.Types.RightEdge, PlasmaCore.Types.BottomEdge, PlasmaCore.Types.LeftEdge].includes(Plasmoid.location)
    readonly property bool hasData: currentWeather && Object.keys(currentWeather).length > 0
    readonly property int refreshIntervalMinutes: Math.max(5, Plasmoid.configuration.refreshMinutes || 30)
    readonly property string unitSymbol: Plasmoid.configuration.temperatureUnit === "fahrenheit" ? "F" : "C"
    readonly property string iconStyle: Plasmoid.configuration.iconStyle || "meteocons-fill"
    readonly property string tempText: formatTemperature(currentWeather.temperature_2m, false)
    readonly property string feelsLikeText: formatTemperature(currentWeather.apparent_temperature, true)
    readonly property string conditionText: weatherDescription(currentWeather.weather_code)
    readonly property string weatherIcon: weatherIconName(currentWeather.weather_code, currentWeather.is_day !== 0, inPanel)
    readonly property string locationTitle: Plasmoid.configuration.locationName || i18n("Weather")
    readonly property string updatedText: lastUpdated.getTime() > 0 ? Qt.formatTime(lastUpdated, Qt.locale().timeFormat(Locale.ShortFormat)) : i18n("Never")
    property var currentWeather: ({
    })
    property var currentUnits: ({
    })
    property var hourlyForecast: []
    property var dailyForecast: []
    property date lastUpdated: new Date(0)
    property bool loading: false
    property string errorText: ""

    function shouldRefresh() {
        if (!hasData)
            return true;

        return Date.now() - lastUpdated.getTime() > refreshIntervalMinutes * 60 * 1000;
    }

    function forecastUrl() {
        const latitude = Number(Plasmoid.configuration.latitude);
        const longitude = Number(Plasmoid.configuration.longitude);
        const unit = Plasmoid.configuration.temperatureUnit === "fahrenheit" ? "fahrenheit" : "celsius";
        const parameters = ["latitude=" + encodeURIComponent(latitude.toFixed(4)), "longitude=" + encodeURIComponent(longitude.toFixed(4)), "current=" + encodeURIComponent("temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day"), "hourly=" + encodeURIComponent("temperature_2m,apparent_temperature,relative_humidity_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m,uv_index,is_day"), "daily=" + encodeURIComponent("weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,uv_index_max,sunrise,sunset"), "timezone=auto", "forecast_days=7", "temperature_unit=" + unit, "wind_speed_unit=kmh"];
        return "https://api.open-meteo.com/v1/forecast?" + parameters.join("&");
    }

    function refreshWeather() {
        const latitude = Number(Plasmoid.configuration.latitude);
        const longitude = Number(Plasmoid.configuration.longitude);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            errorText = i18n("Latitude or longitude is invalid.");
            return ;
        }
        loading = true;
        errorText = "";
        const request = new XMLHttpRequest();
        request.open("GET", forecastUrl());
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return ;

            loading = false;
            if (request.status !== 200) {
                errorText = i18nc("@info", "Open-Meteo request failed (%1).", request.status);
                return ;
            }
            try {
                const response = JSON.parse(request.responseText);
                currentWeather = response.current || {
                };
                currentUnits = response.current_units || {
                };
                hourlyForecast = buildHourlyForecast(response.hourly || {
                });
                dailyForecast = buildDailyForecast(response.daily || {
                });
                lastUpdated = new Date();
                errorText = "";
            } catch (error) {
                errorText = i18n("Could not read the Open-Meteo response.");
            }
        };
        request.send();
    }

    function buildHourlyForecast(hourly) {
        const hours = [];
        const times = hourly.time || [];
        let startIndex = 0;
        const cutoff = Date.now() - 30 * 60 * 1000;
        for (let index = 0; index < times.length; index++) {
            if (new Date(times[index]).getTime() >= cutoff) {
                startIndex = index;
                break;
            }
        }
        for (let index = startIndex; index < Math.min(times.length, startIndex + 24); index++) {
            hours.push({
                "time": times[index],
                "temperature_2m": valueAt(hourly.temperature_2m, index),
                "apparent_temperature": valueAt(hourly.apparent_temperature, index),
                "relative_humidity_2m": valueAt(hourly.relative_humidity_2m, index),
                "precipitation_probability": valueAt(hourly.precipitation_probability, index),
                "precipitation": valueAt(hourly.precipitation, index),
                "weather_code": valueAt(hourly.weather_code, index),
                "wind_speed_10m": valueAt(hourly.wind_speed_10m, index),
                "uv_index": valueAt(hourly.uv_index, index),
                "is_day": valueAt(hourly.is_day, index)
            });
        }
        return hours;
    }

    function buildDailyForecast(daily) {
        const days = [];
        const dates = daily.time || [];
        for (let index = 0; index < dates.length; index++) {
            days.push({
                "date": dates[index],
                "weather_code": valueAt(daily.weather_code, index),
                "temperature_2m_max": valueAt(daily.temperature_2m_max, index),
                "temperature_2m_min": valueAt(daily.temperature_2m_min, index),
                "apparent_temperature_max": valueAt(daily.apparent_temperature_max, index),
                "apparent_temperature_min": valueAt(daily.apparent_temperature_min, index),
                "precipitation_probability_max": valueAt(daily.precipitation_probability_max, index),
                "precipitation_sum": valueAt(daily.precipitation_sum, index),
                "wind_speed_10m_max": valueAt(daily.wind_speed_10m_max, index),
                "uv_index_max": valueAt(daily.uv_index_max, index),
                "sunrise": valueAt(daily.sunrise, index),
                "sunset": valueAt(daily.sunset, index)
            });
        }
        return days;
    }

    function valueAt(values, index) {
        return values && values.length > index ? values[index] : undefined;
    }

    function formatTemperature(value, withUnit) {
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

    function shortDate(isoDate) {
        if (!isoDate)
            return "";

        return Qt.formatDate(new Date(isoDate + "T00:00:00"), "ddd");
    }

    function shortTime(isoDateTime) {
        if (!isoDateTime)
            return "--";

        return Qt.formatTime(new Date(isoDateTime), Qt.locale().timeFormat(Locale.ShortFormat));
    }

    function dayAndDate(isoDate) {
        if (!isoDate)
            return "";

        return Qt.formatDate(new Date(isoDate + "T00:00:00"), "ddd M/d");
    }

    function isToday(isoDate) {
        if (!isoDate)
            return false;

        const date = new Date(isoDate + "T00:00:00");
        const today = new Date();
        return date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate();
    }

    function dailyPrimaryLabel(isoDate) {
        if (!isoDate)
            return "";

        const date = new Date(isoDate + "T00:00:00");
        const today = new Date();
        const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
        if (isToday(isoDate))
            return i18nc("@label current day", "Today");

        if (date.getFullYear() === tomorrow.getFullYear() && date.getMonth() === tomorrow.getMonth() && date.getDate() === tomorrow.getDate())
            return i18nc("@label next day", "Tomorrow");

        return Qt.formatDate(date, "ddd");
    }

    function dailySecondaryLabel(isoDate) {
        if (!isoDate)
            return "";

        return Qt.formatDate(new Date(isoDate + "T00:00:00"), "M/d");
    }

    function dailyTemperatureLimit(fieldName, fallback) {
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

    function dailyRangeStart(day) {
        const weekLow = dailyTemperatureLimit("temperature_2m_min", Number.POSITIVE_INFINITY);
        const weekHigh = dailyTemperatureLimit("temperature_2m_max", Number.NEGATIVE_INFINITY);
        const low = Number(day.temperature_2m_min);
        if (!Number.isFinite(low))
            return 0;

        return Math.max(0, Math.min(1, (low - weekLow) / Math.max(1, weekHigh - weekLow)));
    }

    function dailyRangeWidth(day) {
        const weekLow = dailyTemperatureLimit("temperature_2m_min", Number.POSITIVE_INFINITY);
        const weekHigh = dailyTemperatureLimit("temperature_2m_max", Number.NEGATIVE_INFINITY);
        const low = Number(day.temperature_2m_min);
        const high = Number(day.temperature_2m_max);
        if (!Number.isFinite(low) || !Number.isFinite(high))
            return 0;

        const span = Math.max(1, weekHigh - weekLow);
        const start = dailyRangeStart(day);
        const width = Math.max(0.08, (high - low) / span);
        return Math.max(0, Math.min(1 - start, width));
    }

    function hourLabel(isoDateTime) {
        if (!isoDateTime)
            return "--";

        const date = new Date(isoDateTime);
        const now = new Date();
        if (Math.abs(date.getTime() - now.getTime()) < 45 * 60 * 1000)
            return i18nc("@label current hour", "Now");

        return Qt.formatTime(date, "h AP");
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

    function weatherDescription(code) {
        switch (Number(code)) {
        case 0:
            return i18n("Clear");
        case 1:
            return i18n("Mostly clear");
        case 2:
            return i18n("Partly cloudy");
        case 3:
            return i18n("Overcast");
        case 45:
        case 48:
            return i18n("Fog");
        case 51:
        case 53:
        case 55:
            return i18n("Drizzle");
        case 56:
        case 57:
            return i18n("Freezing drizzle");
        case 61:
        case 63:
        case 65:
            return i18n("Rain");
        case 66:
        case 67:
            return i18n("Freezing rain");
        case 71:
        case 73:
        case 75:
            return i18n("Snow");
        case 77:
            return i18n("Snow grains");
        case 80:
        case 81:
        case 82:
            return i18n("Rain showers");
        case 85:
        case 86:
            return i18n("Snow showers");
        case 95:
            return i18n("Thunderstorm");
        case 96:
        case 99:
            return i18n("Thunderstorm with hail");
        default:
            return i18n("Weather unavailable");
        }
    }

    function isMeteoconsStyle(style) {
        return ["meteocons-fill", "meteocons-flat", "meteocons-line", "meteocons-monochrome"].includes(style);
    }

    function meteoconsStyleName() {
        return isMeteoconsStyle(iconStyle) ? iconStyle.substring("meteocons-".length) : "fill";
    }

    function meteoconsIconUrl(name) {
        return Qt.resolvedUrl("../icons/meteocons/" + meteoconsStyleName() + "/" + name + ".svg").toString();
    }

    function meteoconsRasterIconUrl(name) {
        return Qt.resolvedUrl("../icons/meteocons/" + meteoconsStyleName() + "/" + name + ".png").toString();
    }

    function systemWeatherIconName(code, isDay, symbolic) {
        let icon = "weather-none-available";
        switch (Number(code)) {
        case 0:
            icon = isDay ? "weather-clear" : "weather-clear-night";
            break;
        case 1:
        case 2:
            icon = isDay ? "weather-few-clouds" : "weather-few-clouds-night";
            break;
        case 3:
            icon = "weather-overcast";
            break;
        case 45:
        case 48:
            icon = "weather-fog";
            break;
        case 51:
        case 53:
        case 55:
        case 80:
        case 81:
        case 82:
            icon = isDay ? "weather-showers-day" : "weather-showers-night";
            break;
        case 56:
        case 57:
        case 66:
        case 67:
            icon = "weather-freezing-rain";
            break;
        case 61:
        case 63:
        case 65:
            icon = "weather-showers";
            break;
        case 71:
        case 73:
        case 75:
        case 77:
            icon = "weather-snow";
            break;
        case 85:
        case 86:
            icon = isDay ? "weather-snow-day" : "weather-snow-night";
            break;
        case 95:
            icon = isDay ? "weather-storm" : "weather-storm-night";
            break;
        case 96:
        case 99:
            icon = "weather-hail";
            break;
        }
        return symbolic ? icon + "-symbolic" : icon;
    }

    function meteoconsWeatherIconName(code, isDay) {
        switch (Number(code)) {
        case 0:
            return isDay ? "clear-day" : "clear-night";
        case 1:
            return isDay ? "mostly-clear-day" : "mostly-clear-night";
        case 2:
            return isDay ? "partly-cloudy-day" : "partly-cloudy-night";
        case 3:
            return isDay ? "overcast-day" : "overcast-night";
        case 45:
        case 48:
            return isDay ? "fog-day" : "fog-night";
        case 51:
        case 53:
        case 55:
            return "drizzle";
        case 56:
        case 57:
        case 66:
        case 67:
            return "sleet";
        case 61:
        case 63:
        case 65:
        case 80:
        case 81:
        case 82:
            return "rain";
        case 71:
        case 73:
        case 75:
        case 77:
            return "snow";
        case 85:
        case 86:
            return isDay ? "overcast-day-snow" : "overcast-night-snow";
        case 95:
            return isDay ? "thunderstorms-day" : "thunderstorms-night";
        case 96:
        case 99:
            return isDay ? "thunderstorms-day-hail" : "thunderstorms-night-hail";
        default:
            return "not-available";
        }
    }

    function weatherIconName(code, isDay, symbolic) {
        if (iconStyle === "system")
            return systemWeatherIconName(code, isDay, symbolic);

        return meteoconsIconUrl(meteoconsWeatherIconName(code, isDay));
    }

    function metricIconName(metric, night) {
        if (iconStyle === "system") {
            switch (metric) {
            case "humidity":
                return "weather-fog-symbolic";
            case "rainChance":
            case "rainAmount":
                return "weather-showers-symbolic";
            case "wind":
                return "weather-windy-symbolic";
            case "uv":
                return meteoconsRasterIconUrl("uv-index");
            case "sunrise":
                return "daytime-sunrise-symbolic";
            case "daylight":
                return night ? "weather-clear-night-symbolic" : "weather-clear-symbolic";
            case "sunset":
                return "daytime-sunset-symbolic";
            default:
                return "weather-clear-symbolic";
            }
        }
        switch (metric) {
        case "temperature":
            return meteoconsIconUrl("thermometer");
        case "humidity":
            return meteoconsIconUrl("humidity");
        case "rainChance":
            return meteoconsIconUrl("raindrops");
        case "rainAmount":
            return meteoconsIconUrl("raindrop");
        case "wind":
            return meteoconsIconUrl("wind");
        case "uv":
            return meteoconsRasterIconUrl("uv-index");
        case "sunrise":
            return meteoconsRasterIconUrl("sunrise");
        case "sunset":
            return meteoconsRasterIconUrl("sunset");
        case "daylight":
            return meteoconsIconUrl(night ? "clear-night" : "clear-day");
        default:
            return meteoconsIconUrl("not-available");
        }
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 12
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.busy: loading
    Plasmoid.icon: weatherIcon
    Plasmoid.status: hasData ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.title: i18nc("@title", "%1 Weather", locationTitle)
    toolTipMainText: hasData ? i18nc("@info:tooltip", "%1: %2", locationTitle, formatTemperature(currentWeather.temperature_2m, true)) : i18n("Weather")
    toolTipSubText: errorText.length > 0 ? errorText : (hasData ? i18nc("@info:tooltip", "%1, feels like %2", conditionText, feelsLikeText) : i18n("No weather data yet"))
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    Component.onCompleted: refreshWeather()
    onExpandedChanged: {
        if (root.expanded && shouldRefresh())
            refreshWeather();

    }
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action", "Refresh Weather")
            icon.name: "view-refresh"
            enabled: !root.loading
            onTriggered: root.refreshWeather()
        }
    ]

    Timer {
        id: refreshTimer

        interval: root.refreshIntervalMinutes * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refreshWeather()
    }

    Timer {
        id: configRefreshTimer

        interval: 500
        repeat: false
        onTriggered: root.refreshWeather()
    }

    Connections {
        function onLocationNameChanged() {
            configRefreshTimer.restart();
        }

        function onLatitudeChanged() {
            configRefreshTimer.restart();
        }

        function onLongitudeChanged() {
            configRefreshTimer.restart();
        }

        function onTemperatureUnitChanged() {
            configRefreshTimer.restart();
        }

        function onRefreshMinutesChanged() {
            refreshTimer.restart();
        }

        target: Plasmoid.configuration
    }

    compactRepresentation: CompactRepresentation {
        plasmoidItem: root
    }

    fullRepresentation: FullRepresentation {
        plasmoidItem: root
    }

}
