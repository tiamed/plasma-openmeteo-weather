.pragma library

function descriptionKey(code) {
    switch (Number(code)) {
    case 0:
        return "clear";
    case 1:
        return "mostlyClear";
    case 2:
        return "partlyCloudy";
    case 3:
        return "overcast";
    case 45:
    case 48:
        return "fog";
    case 51:
    case 53:
    case 55:
        return "drizzle";
    case 56:
    case 57:
        return "freezingDrizzle";
    case 61:
    case 63:
    case 65:
        return "rain";
    case 66:
    case 67:
        return "freezingRain";
    case 71:
    case 73:
    case 75:
        return "snow";
    case 77:
        return "snowGrains";
    case 80:
    case 81:
    case 82:
        return "rainShowers";
    case 85:
    case 86:
        return "snowShowers";
    case 95:
        return "thunderstorm";
    case 96:
    case 99:
        return "thunderstormHail";
    default:
        return "unavailable";
    }
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

function systemMetricIconName(metric, night) {
    switch (metric) {
    case "humidity":
        return "weather-fog-symbolic";
    case "rainChance":
    case "rainAmount":
        return "weather-showers-symbolic";
    case "wind":
        return "weather-windy-symbolic";
    case "uv":
        return "uv-raster";
    case "airQuality":
        return "sensors-symbolic";
    case "sunrise":
        return "daytime-sunrise-symbolic";
    case "sunset":
        return "daytime-sunset-symbolic";
    default:
        return "weather-clear-symbolic";
    }
}

function meteoconsMetricIconName(metric, night) {
    switch (metric) {
    case "temperature":
        return "thermometer";
    case "humidity":
        return "humidity";
    case "rainChance":
        return "raindrops";
    case "rainAmount":
        return "raindrop";
    case "wind":
        return "wind";
    case "uv":
        return "uv-index";
    case "airQuality":
        return "fog";
    case "sunrise":
        return "sunrise";
    case "sunset":
        return "sunset";
    default:
        return "not-available";
    }
}

function isMeteoconsMetricRaster(metric) {
    return metric === "uv" || metric === "sunrise" || metric === "sunset";
}

function isMeteoconsStyle(style) {
    return ["meteocons-fill", "meteocons-flat", "meteocons-line", "meteocons-monochrome"].includes(style);
}

function meteoconsStyleName(style) {
    return isMeteoconsStyle(style) ? style.substring("meteocons-".length) : "fill";
}
