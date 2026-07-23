import QtQuick
import org.kde.plasma.plasmoid
import "Formatter.js" as Formatter
import "UiLocale.js" as UiLocale

QtObject {
    id: service

    property var currentWeather: ({
    })
    property var currentUnits: ({
    })
    property var hourlyForecast: []
    property var dailyForecast: []
    property date lastUpdated: new Date(0)
    property bool loading: false
    property string errorText: ""
    property var activeRequest: null
    property var activeAirRequest: null
    property bool configError: false

    readonly property int refreshIntervalMinutes: Math.max(5, Plasmoid.configuration.refreshMinutes || 30)
    readonly property bool hasData: currentWeather && Object.keys(currentWeather).length > 0
    readonly property string uiLanguage: UiLocale.resolveLanguage(Plasmoid.configuration.uiLanguage)

    function tr(msgid) {
        return UiLocale.translate(uiLanguage, msgid);
    }

    function trf(msgid) {
        let text = UiLocale.translate(uiLanguage, msgid);
        for (let index = 1; index < arguments.length; index++)
            text = text.split("%" + index).join(String(arguments[index]));
        return text;
    }

    function shouldRefresh() {
        if (!hasData)
            return true;

        return Date.now() - lastUpdated.getTime() > refreshIntervalMinutes * 60 * 1000;
    }

    function forecastUrl() {
        const latitude = Number(Plasmoid.configuration.latitude);
        const longitude = Number(Plasmoid.configuration.longitude);
        const unit = Plasmoid.configuration.temperatureUnit === "fahrenheit" ? "fahrenheit" : "celsius";
        const parameters = [
            "latitude=" + encodeURIComponent(latitude.toFixed(4)),
            "longitude=" + encodeURIComponent(longitude.toFixed(4)),
            "current=" + encodeURIComponent("temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day"),
            "hourly=" + encodeURIComponent("temperature_2m,apparent_temperature,relative_humidity_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m,uv_index,is_day"),
            "daily=" + encodeURIComponent("weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,uv_index_max,sunrise,sunset"),
            "timezone=auto",
            "forecast_days=7",
            "temperature_unit=" + unit,
            "wind_speed_unit=kmh"
        ];
        return "https://api.open-meteo.com/v1/forecast?" + parameters.join("&");
    }

    function airQualityUrl() {
        const latitude = Number(Plasmoid.configuration.latitude);
        const longitude = Number(Plasmoid.configuration.longitude);
        const parameters = [
            "latitude=" + encodeURIComponent(latitude.toFixed(4)),
            "longitude=" + encodeURIComponent(longitude.toFixed(4)),
            "current=" + encodeURIComponent("european_aqi,us_aqi,pm2_5"),
            "hourly=" + encodeURIComponent("european_aqi,us_aqi,pm2_5"),
            "timezone=auto",
            "forecast_days=2"
        ];
        return "https://air-quality-api.open-meteo.com/v1/air-quality?" + parameters.join("&");
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
                "temperature_2m": Formatter.valueAt(hourly.temperature_2m, index),
                "apparent_temperature": Formatter.valueAt(hourly.apparent_temperature, index),
                "relative_humidity_2m": Formatter.valueAt(hourly.relative_humidity_2m, index),
                "precipitation_probability": Formatter.valueAt(hourly.precipitation_probability, index),
                "precipitation": Formatter.valueAt(hourly.precipitation, index),
                "weather_code": Formatter.valueAt(hourly.weather_code, index),
                "wind_speed_10m": Formatter.valueAt(hourly.wind_speed_10m, index),
                "uv_index": Formatter.valueAt(hourly.uv_index, index),
                "is_day": Formatter.valueAt(hourly.is_day, index),
                "european_aqi": undefined,
                "us_aqi": undefined,
                "pm2_5": undefined
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
                "weather_code": Formatter.valueAt(daily.weather_code, index),
                "temperature_2m_max": Formatter.valueAt(daily.temperature_2m_max, index),
                "temperature_2m_min": Formatter.valueAt(daily.temperature_2m_min, index),
                "apparent_temperature_max": Formatter.valueAt(daily.apparent_temperature_max, index),
                "apparent_temperature_min": Formatter.valueAt(daily.apparent_temperature_min, index),
                "precipitation_probability_max": Formatter.valueAt(daily.precipitation_probability_max, index),
                "precipitation_sum": Formatter.valueAt(daily.precipitation_sum, index),
                "wind_speed_10m_max": Formatter.valueAt(daily.wind_speed_10m_max, index),
                "uv_index_max": Formatter.valueAt(daily.uv_index_max, index),
                "sunrise": Formatter.valueAt(daily.sunrise, index),
                "sunset": Formatter.valueAt(daily.sunset, index)
            });
        }
        return days;
    }

    function mergeAirQuality(response) {
        const current = response.current || {
        };
        currentWeather = Object.assign({}, currentWeather, {
            "european_aqi": current.european_aqi,
            "us_aqi": current.us_aqi,
            "pm2_5": current.pm2_5
        });

        const hourly = response.hourly || {
        };
        const times = hourly.time || [];
        const byTime = {
        };
        for (let index = 0; index < times.length; index++) {
            byTime[times[index]] = {
                "european_aqi": Formatter.valueAt(hourly.european_aqi, index),
                "us_aqi": Formatter.valueAt(hourly.us_aqi, index),
                "pm2_5": Formatter.valueAt(hourly.pm2_5, index)
            };
        }

        const merged = [];
        for (let index = 0; index < hourlyForecast.length; index++) {
            const hour = hourlyForecast[index];
            const air = byTime[hour.time] || {
            };
            merged.push(Object.assign({}, hour, air));
        }
        hourlyForecast = merged;
    }

    function abortActiveRequest() {
        if (activeRequest) {
            activeRequest.onreadystatechange = function() {};
            activeRequest.abort();
            activeRequest = null;
        }
        if (activeAirRequest) {
            activeAirRequest.onreadystatechange = function() {};
            activeAirRequest.abort();
            activeAirRequest = null;
        }
    }

    function refreshAirQuality() {
        if (activeAirRequest) {
            activeAirRequest.onreadystatechange = function() {};
            activeAirRequest.abort();
            activeAirRequest = null;
        }
        const request = new XMLHttpRequest();
        activeAirRequest = request;
        request.open("GET", airQualityUrl());
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            if (activeAirRequest === request)
                activeAirRequest = null;
            if (request.status !== 200)
                return;
            try {
                mergeAirQuality(JSON.parse(request.responseText));
            } catch (error) {
            }
        };
        request.send();
    }

    function refreshWeather() {
        const latitude = Number(Plasmoid.configuration.latitude);
        const longitude = Number(Plasmoid.configuration.longitude);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            errorText = tr("Latitude or longitude is invalid.");
            configError = true;
            return;
        }
        configError = false;
        abortActiveRequest();
        loading = true;
        errorText = "";
        const request = new XMLHttpRequest();
        activeRequest = request;
        request.open("GET", forecastUrl());
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            requestTimeoutTimer.stop();
            if (activeRequest === request)
                activeRequest = null;
            loading = false;
            if (request.status !== 200) {
                errorText = request.status === 0
                    ? tr("No network connection. Will retry on the next refresh.")
                    : trf("Open-Meteo request failed (%1).", request.status);
                return;
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
                refreshAirQuality();
            } catch (error) {
                errorText = tr("Could not read the Open-Meteo response.");
            }
        };
        requestTimeoutTimer.restart();
        request.send();
    }

    function handleRequestTimeout() {
        abortActiveRequest();
        loading = false;
        errorText = tr("Request timed out. Will retry on the next refresh.");
    }

    property Timer requestTimeoutTimer: Timer {
        interval: 15000
        repeat: false
        onTriggered: service.handleRequestTimeout()
    }
}
