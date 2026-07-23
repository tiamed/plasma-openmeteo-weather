import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtPositioning
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "../UiLocale.js" as UiLocale

KCM.SimpleKCM {
    id: root

    property bool searchingLocations: false
    property bool locatingCurrent: false
    property string locationSearchError: ""
    property var locationMatches: []
    property var activeSearchRequest: null
    property alias cfg_locationName: locationNameField.text
    property string cfg_locationNameDefault
    property double cfg_latitude
    property double cfg_latitudeDefault
    property double cfg_longitude
    property double cfg_longitudeDefault
    property string cfg_temperatureUnit
    property string cfg_temperatureUnitDefault
    property string cfg_iconStyle
    property string cfg_iconStyleDefault
    property int cfg_refreshMinutes
    property int cfg_refreshMinutesDefault
    property alias cfg_showPanelText: showPanelTextCheck.checked
    property bool cfg_showPanelTextDefault
    property string cfg_uiLanguage
    property string cfg_uiLanguageDefault
    readonly property string uiLanguage: UiLocale.resolveLanguage(cfg_uiLanguage || "system")
    readonly property var languageOptions: {
        void uiLanguage;
        return UiLocale.languageOptions(tr("System default"));
    }
    readonly property var unitOptions: {
        void uiLanguage;
        return [{
            "text": tr("Celsius"),
            "value": "celsius"
        }, {
            "text": tr("Fahrenheit"),
            "value": "fahrenheit"
        }];
    }
    readonly property var iconStyleOptions: {
        void uiLanguage;
        return [{
            "text": tr("Meteocons Fill"),
            "value": "meteocons-fill",
            "preview": Qt.resolvedUrl("../../icons/meteocons/fill/clear-day.svg")
        }, {
            "text": tr("Meteocons Flat"),
            "value": "meteocons-flat",
            "preview": Qt.resolvedUrl("../../icons/meteocons/flat/clear-day.svg")
        }, {
            "text": tr("Meteocons Line"),
            "value": "meteocons-line",
            "preview": Qt.resolvedUrl("../../icons/meteocons/line/clear-day.svg")
        }, {
            "text": tr("Meteocons Monochrome"),
            "value": "meteocons-monochrome",
            "preview": Qt.resolvedUrl("../../icons/meteocons/monochrome/clear-day.svg")
        }, {
            "text": tr("System icon theme"),
            "value": "system",
            "preview": "weather-clear"
        }];
    }
    readonly property var refreshMinuteOptions: [5, 10, 15, 30, 45, 60, 120, 240]
    readonly property var selectedIconStyle: iconStyleOptions[iconStyleOptionIndex(cfg_iconStyle)] || iconStyleOptions[0]

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

    function optionIndex(options, value, fallbackValue) {
        const selectedValue = value || fallbackValue;
        for (let index = 0; index < options.length; index++) {
            if (options[index].value === selectedValue)
                return index;
        }
        for (let index = 0; index < options.length; index++) {
            if (options[index].value === fallbackValue)
                return index;
        }
        return 0;
    }

    function unitOptionIndex(value) {
        return optionIndex(unitOptions, value, "celsius");
    }

    function iconStyleOptionIndex(value) {
        return optionIndex(iconStyleOptions, value, "meteocons-fill");
    }

    function languageOptionIndex(value) {
        return optionIndex(languageOptions, value || "system", "system");
    }

    function isFilePreview(preview) {
        const text = "" + preview;
        return text.startsWith("file:") || text.startsWith("/") || text.indexOf(".svg") >= 0;
    }

    function clampedNumber(text, minimum, maximum, fallbackValue) {
        const value = Number(text);
        if (!Number.isFinite(value))
            return fallbackValue;

        return Math.max(minimum, Math.min(maximum, value));
    }

    function coordinateText(value) {
        const number = Number(value);
        return Number.isFinite(number) ? number.toFixed(4) : "";
    }

    function applyLatitudeText() {
        const value = clampedNumber(latitudeField.text, -90, 90, root.cfg_latitude);
        root.cfg_latitude = value;
        latitudeField.text = coordinateText(value);
    }

    function applyLongitudeText() {
        const value = clampedNumber(longitudeField.text, -180, 180, root.cfg_longitude);
        root.cfg_longitude = value;
        longitudeField.text = coordinateText(value);
    }

    function refreshOptionText(value) {
        return root.trcp("%1 minute", "%1 minutes", value);
    }

    function refreshOptionValues(value) {
        const values = refreshMinuteOptions.slice();
        const number = Number(value) || 30;
        if (!values.includes(number))
            values.push(number);

        values.sort((left, right) => {
            return left - right;
        });
        return values;
    }

    function refreshOptionModel(value) {
        const values = refreshOptionValues(value);
        const model = [];
        for (let index = 0; index < values.length; index++) {
            model.push({
                "text": refreshOptionText(values[index]),
                "value": values[index]
            });
        }
        return model;
    }

    function refreshOptionIndex(value) {
        const values = refreshOptionValues(value);
        const number = Number(value) || 30;
        for (let index = 0; index < values.length; index++) {
            if (values[index] === number)
                return index;
        }
        return values.indexOf(30);
    }

    function syncCoordinateFields() {
        if (!latitudeField.activeFocus)
            latitudeField.text = coordinateText(cfg_latitude);

        if (!longitudeField.activeFocus)
            longitudeField.text = coordinateText(cfg_longitude);
    }

    function locationDisplayName(result) {
        const parts = [result.name || root.tr("Unnamed location")];
        if (result.admin1 && result.admin1 !== result.name)
            parts.push(result.admin1);

        if (result.country)
            parts.push(result.country);

        return parts.join(", ");
    }

    function locationDetailText(result) {
        const details = [];
        const latitude = Number(result.latitude);
        const longitude = Number(result.longitude);
        if (Number.isFinite(latitude) && Number.isFinite(longitude))
            details.push(latitude.toFixed(4) + ", " + longitude.toFixed(4));

        if (result.timezone)
            details.push(result.timezone);

        return details.join(" | ");
    }

    function geocodingLanguage() {
        const language = uiLanguage.toLowerCase();
        if (language.indexOf("zh") === 0)
            return "zh";
        if (language === "en" || language.indexOf("en_") === 0)
            return "en";
        const shortCode = (uiLanguage.split("_")[0] || "").toLowerCase();
        return shortCode.length > 0 ? shortCode : "en";
    }

    function abortActiveSearch() {
        if (!activeSearchRequest)
            return;
        activeSearchRequest.onreadystatechange = function() {};
        activeSearchRequest.abort();
        activeSearchRequest = null;
    }

    function scheduleSearch() {
        const query = locationSearchField.text.trim();
        if (query.length < 2) {
            searchDebounce.stop();
            abortActiveSearch();
            searchingLocations = false;
            locationMatches = [];
            if (query.length > 0)
                locationSearchError = root.tr("Type at least two characters.");
            else
                locationSearchError = "";
            return;
        }
        locationSearchError = "";
        searchDebounce.restart();
    }

    function searchLocations() {
        const query = locationSearchField.text.trim();
        abortActiveSearch();
        locationMatches = [];
        locationSearchError = "";
        if (query.length < 2) {
            searchingLocations = false;
            locationSearchError = root.tr("Type at least two characters.");
            return;
        }
        searchingLocations = true;
        const request = new XMLHttpRequest();
        activeSearchRequest = request;
        request.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=20&language=" + encodeURIComponent(geocodingLanguage()) + "&format=json&name=" + encodeURIComponent(query));
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;

            if (activeSearchRequest === request)
                activeSearchRequest = null;
            searchingLocations = false;
            if (request.status !== 200) {
                locationSearchError = request.status === 0 ? "" : root.trf("Location search failed (%1).", request.status);
                return;
            }
            try {
                const response = JSON.parse(request.responseText);
                const results = response.results || [];
                const matches = [];
                if (results.length === 0) {
                    locationSearchError = root.tr("No matching locations.");
                    return;
                }
                for (let index = 0; index < results.length; index++) {
                    const result = results[index];
                    matches.push({
                        "title": locationDisplayName(result),
                        "subtitle": locationDetailText(result),
                        "latitude": Number(result.latitude),
                        "longitude": Number(result.longitude)
                    });
                }
                locationMatches = matches;
            } catch (error) {
                locationSearchError = root.tr("Could not read location results.");
            }
        };
        request.send();
    }

    function applyLocation(display, latitude, longitude) {
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude))
            return;

        cfg_locationName = display;
        cfg_latitude = latitude;
        cfg_longitude = longitude;
        locationSearchError = "";
    }

    function reverseGeocodeDisplayName(payload, latitude, longitude) {
        const address = payload.address || {
        };
        const locality = address.city || address.town || address.village || address.municipality || address.suburb || address.neighbourhood || address.hamlet || address.county || "";
        const region = address.state || address.province || address.region || "";
        const country = address.country || "";
        const parts = [];
        if (locality.length > 0)
            parts.push(locality);
        if (region.length > 0 && region !== locality)
            parts.push(region);
        if (country.length > 0 && country !== locality && country !== region)
            parts.push(country);
        if (parts.length > 0)
            return parts.join(", ");

        const displayName = (payload.display_name || "").toString().trim();
        if (displayName.length > 0) {
            const shortName = displayName.split(",").slice(0, 3).map(part => part.trim()).filter(part => part.length > 0);
            if (shortName.length > 0)
                return shortName.join(", ");
        }

        return root.trf("Current location (%1, %2)", latitude.toFixed(4), longitude.toFixed(4));
    }

    function resolveCurrentLocationName(latitude, longitude) {
        const request = new XMLHttpRequest();
        const language = geocodingLanguage();
        const url = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&zoom=14&lat=" + encodeURIComponent(latitude.toFixed(6)) + "&lon=" + encodeURIComponent(longitude.toFixed(6)) + "&accept-language=" + encodeURIComponent(language);
        request.open("GET", url);
        request.setRequestHeader("User-Agent", "plasma-openmeteo-weather/0.1 (https://github.com/tiamed/plasma-openmeteo-weather)");
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;

            locatingCurrent = false;
            locationTimeout.stop();
            let display = root.trf("Current location (%1, %2)", latitude.toFixed(4), longitude.toFixed(4));
            if (request.status === 200) {
                try {
                    display = reverseGeocodeDisplayName(JSON.parse(request.responseText), latitude, longitude);
                } catch (error) {
                }
            }
            applyLocation(display, latitude, longitude);
        };
        request.send();
    }

    function useCurrentLocation() {
        locationSearchError = "";
        if (positionSource.sourceError === PositionSource.AccessError) {
            locationSearchError = root.tr("Location access denied.");
            return;
        }
        locatingCurrent = true;
        locationTimeout.restart();
        positionSource.update();
    }

    function finishCurrentLocation(latitude, longitude) {
        // Keep locatingCurrent true while reverse-geocoding the placename.
        locationTimeout.restart();
        resolveCurrentLocationName(latitude, longitude);
    }

    Component.onCompleted: Qt.callLater(root.syncCoordinateFields)

    Timer {
        id: searchDebounce

        interval: 300
        repeat: false
        onTriggered: root.searchLocations()
    }

    Timer {
        id: locationTimeout

        interval: 15000
        repeat: false
        onTriggered: {
            root.locatingCurrent = false;
            positionSource.stop();
            root.locationSearchError = root.tr("Could not determine current location.");
        }
    }

    PositionSource {
        id: positionSource

        updateInterval: 1000
        preferredPositioningMethods: PositionSource.AllPositioningMethods
        onPositionChanged: {
            if (!root.locatingCurrent)
                return;
            if (!position.latitudeValid || !position.longitudeValid)
                return;
            root.finishCurrentLocation(position.coordinate.latitude, position.coordinate.longitude);
            stop();
        }
        onSourceErrorChanged: {
            if (!root.locatingCurrent)
                return;
            if (sourceError === PositionSource.NoError)
                return;
            root.locatingCurrent = false;
            locationTimeout.stop();
            stop();
            if (sourceError === PositionSource.AccessError)
                root.locationSearchError = root.tr("Location access denied.");
            else if (sourceError === PositionSource.ClosedError)
                root.locationSearchError = root.tr("Location services unavailable.");
            else
                root.locationSearchError = root.tr("Could not determine current location.");
        }
    }

    Kirigami.FormLayout {
        QQC2.TextField {
            id: locationNameField

            Kirigami.FormData.label: root.tr("Location name:")
            placeholderText: root.tr("City or label")
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: root.tr("Search:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: locationSearchField

                placeholderText: root.tr("Search city")
                Layout.fillWidth: true
                onTextChanged: root.scheduleSearch()
                Keys.onReturnPressed: event => {
                    searchDebounce.stop();
                    root.searchLocations();
                    event.accepted = true;
                }
                Keys.onEnterPressed: event => {
                    searchDebounce.stop();
                    root.searchLocations();
                    event.accepted = true;
                }
            }

            QQC2.Button {
                text: root.tr("Find")
                icon.name: "edit-find"
                enabled: !root.searchingLocations
                onClicked: {
                    searchDebounce.stop();
                    root.searchLocations();
                }
            }
        }

        QQC2.Button {
            text: root.locatingCurrent ? root.tr("Locating…") : root.tr("Use current location")
            icon.name: "mark-location-symbolic"
            enabled: !root.locatingCurrent
            Layout.fillWidth: true
            onClicked: root.useCurrentLocation()
        }

        QQC2.Label {
            text: root.searchingLocations ? root.tr("Searching...") : root.locationSearchError
            visible: root.searchingLocations || root.locationSearchError.length > 0
            opacity: 0.72
            Layout.fillWidth: true
        }

        Item {
            id: locationResultsHost

            readonly property real listHeight: Math.min(Kirigami.Units.gridUnit * 14, Math.max(Kirigami.Units.gridUnit * 3.2, root.locationMatches.length * (Kirigami.Units.gridUnit * 3.2 + Kirigami.Units.smallSpacing)))

            Kirigami.FormData.label: root.tr("Results:")
            visible: root.locationMatches.length > 0
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            Layout.preferredHeight: listHeight
            implicitHeight: listHeight

            ListView {
                id: locationResultsList

                anchors.fill: parent
                model: root.locationMatches
                clip: true
                spacing: Kirigami.Units.smallSpacing
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                }

                delegate: Rectangle {
                    id: locationResultRow

                    required property var modelData
                    readonly property var result: modelData || ({
                    })

                    width: locationResultsList.width
                    height: Kirigami.Units.gridUnit * 3.2
                    radius: Kirigami.Units.smallSpacing
                    color: selectArea.containsMouse || selectArea.pressed ? Kirigami.Theme.hoverColor : Kirigami.Theme.alternateBackgroundColor
                    border.width: 1
                    border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.82)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: "mark-location-symbolic"
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0

                            QQC2.Label {
                                text: locationResultRow.result.title || ""
                                color: Kirigami.Theme.textColor
                                font.bold: true
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            QQC2.Label {
                                text: locationResultRow.result.subtitle || ""
                                color: Kirigami.Theme.textColor
                                opacity: 0.72
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: selectArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.applyLocation(locationResultRow.result.title || "", Number(locationResultRow.result.latitude), Number(locationResultRow.result.longitude))
                    }
                }
            }
        }

        QQC2.TextField {
            id: latitudeField

            Kirigami.FormData.label: root.tr("Latitude:")
            text: root.coordinateText(root.cfg_latitude)
            placeholderText: "31.2304"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            Layout.fillWidth: true
            onAccepted: root.applyLatitudeText()
            onEditingFinished: root.applyLatitudeText()

            Connections {
                target: root

                function onCfg_latitudeChanged() {
                    if (!latitudeField.activeFocus)
                        latitudeField.text = root.coordinateText(root.cfg_latitude);
                }
            }

            validator: DoubleValidator {
                bottom: -90
                top: 90
                decimals: 4
                notation: DoubleValidator.StandardNotation
            }
        }

        QQC2.TextField {
            id: longitudeField

            Kirigami.FormData.label: root.tr("Longitude:")
            text: root.coordinateText(root.cfg_longitude)
            placeholderText: "121.4737"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            Layout.fillWidth: true
            onAccepted: root.applyLongitudeText()
            onEditingFinished: root.applyLongitudeText()

            Connections {
                target: root

                function onCfg_longitudeChanged() {
                    if (!longitudeField.activeFocus)
                        longitudeField.text = root.coordinateText(root.cfg_longitude);
                }
            }

            validator: DoubleValidator {
                bottom: -180
                top: 180
                decimals: 4
                notation: DoubleValidator.StandardNotation
            }
        }

        QQC2.ComboBox {
            id: languageCombo

            Kirigami.FormData.label: root.tr("Language:")
            textRole: "text"
            valueRole: "value"
            model: root.languageOptions
            currentIndex: root.languageOptionIndex(root.cfg_uiLanguage)
            Layout.fillWidth: true
            onActivated: root.cfg_uiLanguage = currentValue
        }

        QQC2.ComboBox {
            id: unitCombo

            Kirigami.FormData.label: root.tr("Units:")
            textRole: "text"
            valueRole: "value"
            model: root.unitOptions
            currentIndex: root.unitOptionIndex(root.cfg_temperatureUnit)
            onActivated: root.cfg_temperatureUnit = currentValue
        }

        QQC2.ComboBox {
            id: iconStyleCombo

            Kirigami.FormData.label: root.tr("Icons:")
            textRole: "text"
            valueRole: "value"
            model: root.iconStyleOptions
            currentIndex: root.iconStyleOptionIndex(root.cfg_iconStyle)
            Layout.fillWidth: true
            onActivated: root.cfg_iconStyle = currentValue

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                    Kirigami.Icon {
                        anchors.fill: parent
                        visible: !root.isFilePreview(root.selectedIconStyle.preview)
                        source: root.isFilePreview(root.selectedIconStyle.preview) ? "" : root.selectedIconStyle.preview
                    }

                    Image {
                        anchors.fill: parent
                        visible: root.isFilePreview(root.selectedIconStyle.preview)
                        source: root.isFilePreview(root.selectedIconStyle.preview) ? root.selectedIconStyle.preview : ""
                        sourceSize.width: Kirigami.Units.iconSizes.smallMedium
                        sourceSize.height: Kirigami.Units.iconSizes.smallMedium
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                QQC2.Label {
                    text: iconStyleCombo.displayText
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            delegate: QQC2.ItemDelegate {
                id: iconStyleDelegate

                required property var model
                required property int index
                readonly property string preview: model.preview || ""
                readonly property bool filePreview: root.isFilePreview(preview)

                width: iconStyleCombo.width
                highlighted: iconStyleCombo.highlightedIndex === index
                text: model[iconStyleCombo.textRole]

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Item {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                        Kirigami.Icon {
                            anchors.fill: parent
                            visible: !iconStyleDelegate.filePreview
                            source: iconStyleDelegate.filePreview ? "" : iconStyleDelegate.preview
                        }

                        Image {
                            anchors.fill: parent
                            visible: iconStyleDelegate.filePreview
                            source: iconStyleDelegate.filePreview ? iconStyleDelegate.preview : ""
                            sourceSize.width: Kirigami.Units.iconSizes.smallMedium
                            sourceSize.height: Kirigami.Units.iconSizes.smallMedium
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    QQC2.Label {
                        text: iconStyleDelegate.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        QQC2.ComboBox {
            id: refreshCombo

            Kirigami.FormData.label: root.tr("Refresh:")
            textRole: "text"
            valueRole: "value"
            model: root.refreshOptionModel(root.cfg_refreshMinutes)
            currentIndex: root.refreshOptionIndex(root.cfg_refreshMinutes)
            Layout.fillWidth: true
            onActivated: root.cfg_refreshMinutes = Number(currentValue)
        }

        QQC2.CheckBox {
            id: showPanelTextCheck

            text: root.tr("Show temperature text in horizontal panels")
        }
    }
}
