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

## Translations

UI strings are translated from GNU gettext catalogs in `po/`. The widget still lets you pick a language in settings (independent of the desktop locale).

- Edit or add `po/<lang>.po` (for example `po/de.po`)
- Run `scripts/build-locales.py compile` to regenerate `contents/ui/LocaleData.js`
- Or run `scripts/build-locales.py sync` to extract new strings from QML, merge into `.po` files, and compile

CI runs `scripts/build-locales.py check` on every push/PR: it validates `.po` files and fails if `LocaleData.js` is up of date. English is the source language and does not need a `.po` file.

## Releases

Pushing a version tag publishes a GitHub Release with a `.plasmoid` asset:

1. Bump `KPlugin.Version` in `metadata.json`
2. Commit the change
3. Tag and push, for example:

```sh
git tag v0.2.0
git push origin v0.2.0
```

You can also run the **Release** workflow manually from the Actions tab (`workflow_dispatch`). The tag version must match `metadata.json`.

## Credits and Licenses

- Weather and forecast data are provided by [Open-Meteo.com](https://open-meteo.com/). Open-Meteo API data is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).
- Location search uses the [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api). Location data is based on [GeoNames](https://www.geonames.org/), which is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).
- Bundled Meteocons icons are from [Meteocons](https://github.com/basmilius/meteocons) by Bas Milius and are licensed under the MIT License. A copy of the license is included in `contents/icons/meteocons/LICENSE`.
