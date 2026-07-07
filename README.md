# Plasma Open-Meteo Weather

A KDE Plasma 6 weather widget designed for the panel/status bar. The compact view shows a native weather icon and optional temperature text; clicking it opens a weather report with current conditions, the next 24 hours, and a 7-day daily forecast.

The widget uses the Open-Meteo forecast API directly and does not need an API key.

Meteocons Fill is the default icon style. The settings page also lets you choose Meteocons Flat, Line, Monochrome, or the current KDE system icon theme.

## Install

```sh
kpackagetool6 -t Plasma/Applet -i .
```

Upgrade after edits:

```sh
kpackagetool6 -t Plasma/Applet -u .
```

Then add **Open-Meteo Weather Card** to a Plasma panel. Configure the widget to search and select a location through Open-Meteo geocoding, or manually edit latitude and longitude. The settings also control units, refresh interval, and whether the panel shows text next to the icon.

## Default Location

The default configuration is Shanghai:

- Latitude: `31.2304`
- Longitude: `121.4737`

## Credits and Licenses

- Weather and forecast data are provided by [Open-Meteo.com](https://open-meteo.com/). Open-Meteo API data is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).
- Location search uses the [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api). Location data is based on [GeoNames](https://www.geonames.org/), which is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).
- Bundled Meteocons icons are from [Meteocons](https://github.com/basmilius/meteocons) by Bas Milius and are licensed under the MIT License. A copy of the license is included in `contents/icons/meteocons/LICENSE`.
