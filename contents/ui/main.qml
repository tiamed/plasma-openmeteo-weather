import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "Formatter.js" as Formatter
import "WeatherCode.js" as WeatherCode
import "UiLocale.js" as UiLocale

PlasmoidItem {
    id: root

    WeatherService {
        id: weatherService
    }

    readonly property bool inPanel: [PlasmaCore.Types.TopEdge, PlasmaCore.Types.RightEdge, PlasmaCore.Types.BottomEdge, PlasmaCore.Types.LeftEdge].includes(Plasmoid.location)
    readonly property alias hasData: weatherService.hasData
    readonly property alias refreshIntervalMinutes: weatherService.refreshIntervalMinutes
    readonly property string unitSymbol: Plasmoid.configuration.temperatureUnit === "fahrenheit" ? "F" : "C"
    readonly property string iconStyle: Plasmoid.configuration.iconStyle || "meteocons-fill"
    readonly property string uiLanguage: UiLocale.resolveLanguage(Plasmoid.configuration.uiLanguage)
    readonly property var uiLocale: Qt.locale(UiLocale.localeName(uiLanguage))
    readonly property string tempText: formatTemperature(currentWeather.temperature_2m, false)
    readonly property string feelsLikeText: formatTemperature(currentWeather.apparent_temperature, true)
    readonly property string conditionText: weatherDescription(currentWeather.weather_code)
    readonly property string weatherIcon: weatherIconName(currentWeather.weather_code, currentWeather.is_day !== 0, inPanel)
    readonly property string locationTitle: Plasmoid.configuration.locationName || tr("Weather")
    readonly property string updatedText: lastUpdated.getTime() > 0 ? Qt.formatTime(lastUpdated, uiLocale.timeFormat(Locale.ShortFormat)) : tr("Never")
    readonly property alias currentWeather: weatherService.currentWeather
    readonly property alias currentUnits: weatherService.currentUnits
    readonly property alias hourlyForecast: weatherService.hourlyForecast
    readonly property alias dailyForecast: weatherService.dailyForecast
    readonly property alias lastUpdated: weatherService.lastUpdated
    readonly property alias loading: weatherService.loading
    readonly property alias errorText: weatherService.errorText
    readonly property alias configError: weatherService.configError

    function tr(msgid) {
        return UiLocale.translate(uiLanguage, msgid);
    }

    function trf(msgid) {
        let text = UiLocale.translate(uiLanguage, msgid);
        for (let index = 1; index < arguments.length; index++)
            text = text.split("%" + index).join(String(arguments[index]));
        return text;
    }

    function trcp(singular, plural, count) {
        return UiLocale.translatePlural(uiLanguage, singular, plural, count);
    }

    function formatWithLocale(dateValue, format) {
        // Prefer Locale.toString so weekday/AMPM follow uiLanguage, not process locale.
        if (uiLocale && typeof uiLocale.toString === "function")
            return uiLocale.toString(dateValue, format);

        return format.indexOf("H") >= 0 || format.indexOf("h") >= 0 || format.indexOf("m") >= 0 || format.indexOf("A") >= 0 || format.indexOf("a") >= 0
            ? Qt.formatTime(dateValue, format)
            : Qt.formatDate(dateValue, format);
    }

    function shouldRefresh() {
        return weatherService.shouldRefresh();
    }

    function refreshWeather() {
        weatherService.refreshWeather();
    }

    function formatTemperature(value, withUnit) {
        return Formatter.formatTemperature(value, withUnit, unitSymbol);
    }

    function formatPercent(value) {
        return Formatter.formatPercent(value);
    }

    function formatWind(value) {
        return Formatter.formatWind(value);
    }

    function formatLength(value) {
        return Formatter.formatLength(value);
    }

    function formatUv(value) {
        return Formatter.formatUv(value);
    }

    function formatAqi(value) {
        return Formatter.formatAqi(value);
    }

    function formatPm25(value) {
        return Formatter.formatPm25(value);
    }

    function airQualityLevel(value) {
        const key = Formatter.aqiLevelKey(value);
        return key ? tr(key) : "";
    }

    function formatAirQuality(value) {
        const aqi = Formatter.formatAqi(value);
        if (aqi === "--")
            return "--";
        return trf("%1 · %2", aqi, airQualityLevel(value));
    }

    function shortDate(isoDate) {
        if (!isoDate)
            return "";

        return formatWithLocale(new Date(isoDate + "T00:00:00"), "ddd");
    }

    function shortTime(isoDateTime) {
        if (!isoDateTime)
            return "--";

        return formatWithLocale(new Date(isoDateTime), uiLocale.timeFormat(Locale.ShortFormat));
    }

    function dayAndDate(isoDate) {
        if (!isoDate)
            return "";

        const date = new Date(isoDate + "T00:00:00");
        if (UiLocale.usesChineseDateFormat(uiLanguage))
            return formatWithLocale(date, "M月d日 ddd");

        return formatWithLocale(date, "ddd M/d");
    }

    function isToday(isoDate) {
        return Formatter.isToday(isoDate);
    }

    function dailyPrimaryLabel(isoDate) {
        if (!isoDate)
            return "";

        const date = new Date(isoDate + "T00:00:00");
        const today = new Date();
        const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
        if (Formatter.isToday(isoDate))
            return tr("Today");

        if (Formatter.isSameCalendarDay(date, tomorrow))
            return tr("Tomorrow");

        return formatWithLocale(date, "ddd");
    }

    function dailySecondaryLabel(isoDate) {
        if (!isoDate)
            return "";

        const date = new Date(isoDate + "T00:00:00");
        if (UiLocale.usesChineseDateFormat(uiLanguage))
            return formatWithLocale(date, "M月d日");

        return formatWithLocale(date, "M/d");
    }

    function dailyRangeStart(day) {
        return Formatter.dailyRangeStart(dailyForecast, day);
    }

    function dailyRangeWidth(day) {
        return Formatter.dailyRangeWidth(dailyForecast, day);
    }

    function hourLabel(isoDateTime) {
        if (!isoDateTime)
            return "--";

        if (Formatter.isCurrentHour(isoDateTime, 45 * 60 * 1000))
            return tr("Now");

        if (UiLocale.usesChineseDateFormat(uiLanguage))
            return formatWithLocale(new Date(isoDateTime), "H:mm");

        return formatWithLocale(new Date(isoDateTime), "h AP");
    }

    function weatherDescription(code) {
        switch (WeatherCode.descriptionKey(code)) {
        case "clear":
            return tr("Clear");
        case "mostlyClear":
            return tr("Mostly clear");
        case "partlyCloudy":
            return tr("Partly cloudy");
        case "overcast":
            return tr("Overcast");
        case "fog":
            return tr("Fog");
        case "drizzle":
            return tr("Drizzle");
        case "freezingDrizzle":
            return tr("Freezing drizzle");
        case "rain":
            return tr("Rain");
        case "freezingRain":
            return tr("Freezing rain");
        case "snow":
            return tr("Snow");
        case "snowGrains":
            return tr("Snow grains");
        case "rainShowers":
            return tr("Rain showers");
        case "snowShowers":
            return tr("Snow showers");
        case "thunderstorm":
            return tr("Thunderstorm");
        case "thunderstormHail":
            return tr("Thunderstorm with hail");
        default:
            return tr("Weather unavailable");
        }
    }

    function meteoconsIconUrl(name) {
        return Qt.resolvedUrl("../icons/meteocons/" + WeatherCode.meteoconsStyleName(iconStyle) + "/" + name + ".svg").toString();
    }

    function meteoconsRasterIconUrl(name) {
        return Qt.resolvedUrl("../icons/meteocons/" + WeatherCode.meteoconsStyleName(iconStyle) + "/" + name + ".png").toString();
    }

    function weatherIconName(code, isDay, symbolic) {
        if (iconStyle === "system")
            return WeatherCode.systemWeatherIconName(code, isDay, symbolic);

        return meteoconsIconUrl(WeatherCode.meteoconsWeatherIconName(code, isDay));
    }

    function metricIconName(metric, night) {
        if (iconStyle === "system") {
            const icon = WeatherCode.systemMetricIconName(metric, night);
            if (icon === "uv-raster")
                return meteoconsRasterIconUrl("uv-index");

            return icon;
        }
        const name = WeatherCode.meteoconsMetricIconName(metric, night);
        if (WeatherCode.isMeteoconsMetricRaster(metric))
            return meteoconsRasterIconUrl(name);

        return meteoconsIconUrl(name);
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 12
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.busy: loading
    Plasmoid.icon: weatherIcon
    Plasmoid.status: errorText.length > 0 ? PlasmaCore.Types.NeedsAttentionStatus : (hasData ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus)
    Plasmoid.title: trf("%1 Weather", locationTitle)
    toolTipMainText: hasData ? trf("%1: %2", locationTitle, formatTemperature(currentWeather.temperature_2m, true)) : tr("Weather")
    toolTipSubText: errorText.length > 0 ? errorText : (hasData ? trf("%1, feels like %2", conditionText, feelsLikeText) : tr("No weather data yet"))
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    Component.onCompleted: refreshWeather()
    onExpandedChanged: {
        if (root.expanded && shouldRefresh())
            refreshWeather();
    }
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.tr("Refresh Weather")
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
        target: Plasmoid.configuration

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
    }

    compactRepresentation: CompactRepresentation {
        plasmoidItem: root
    }

    fullRepresentation: FullRepresentation {
        plasmoidItem: root
    }

}
