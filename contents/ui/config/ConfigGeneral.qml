import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property bool searchingLocations: false
    property string locationSearchError: ""
    property var locationMatches: []
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
    readonly property var unitOptions: [{
        "text": i18nc("@item:inlistbox", "Celsius"),
        "value": "celsius"
    }, {
        "text": i18nc("@item:inlistbox", "Fahrenheit"),
        "value": "fahrenheit"
    }]
    readonly property var iconStyleOptions: [{
        "text": i18nc("@item:inlistbox icon style", "Meteocons Fill"),
        "value": "meteocons-fill"
    }, {
        "text": i18nc("@item:inlistbox icon style", "Meteocons Flat"),
        "value": "meteocons-flat"
    }, {
        "text": i18nc("@item:inlistbox icon style", "Meteocons Line"),
        "value": "meteocons-line"
    }, {
        "text": i18nc("@item:inlistbox icon style", "Meteocons Monochrome"),
        "value": "meteocons-monochrome"
    }, {
        "text": i18nc("@item:inlistbox icon style", "System icon theme"),
        "value": "system"
    }]
    readonly property var refreshMinuteOptions: [5, 10, 15, 30, 45, 60, 120, 240]

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
        return i18ncp("@item:inlistbox", "%1 minute", "%1 minutes", value);
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
        const parts = [result.name || i18n("Unnamed location")];
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

    function searchLocations() {
        const query = locationSearchField.text.trim();
        locationMatches = [];
        locationSearchError = "";
        if (query.length < 2) {
            locationSearchError = i18n("Type at least two characters.");
            return ;
        }
        searchingLocations = true;
        const request = new XMLHttpRequest();
        request.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=8&language=en&format=json&name=" + encodeURIComponent(query));
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return ;

            searchingLocations = false;
            if (request.status !== 200) {
                locationSearchError = i18nc("@info", "Location search failed (%1).", request.status);
                return ;
            }
            try {
                const response = JSON.parse(request.responseText);
                const results = response.results || [];
                const matches = [];
                if (results.length === 0) {
                    locationSearchError = i18n("No matching locations.");
                    return ;
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
                locationSearchError = i18n("Could not read location results.");
            }
        };
        request.send();
    }

    function applyLocation(display, latitude, longitude) {
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude))
            return ;

        cfg_locationName = display;
        cfg_latitude = latitude;
        cfg_longitude = longitude;
    }

    Component.onCompleted: Qt.callLater(root.syncCoordinateFields)

    Kirigami.FormLayout {
        QQC2.TextField {
            id: locationNameField

            Kirigami.FormData.label: i18nc("@label:textbox", "Location name:")
            placeholderText: i18nc("@info:placeholder", "City or label")
            Layout.fillWidth: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:textbox", "Search:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: locationSearchField

                placeholderText: i18nc("@info:placeholder", "Search city")
                Layout.fillWidth: true
                onAccepted: root.searchLocations()
            }

            QQC2.Button {
                text: i18nc("@action:button", "Find")
                icon.name: "edit-find"
                enabled: !root.searchingLocations
                onClicked: root.searchLocations()
            }

        }

        QQC2.Label {
            text: root.searchingLocations ? i18n("Searching...") : root.locationSearchError
            visible: root.searchingLocations || root.locationSearchError.length > 0
            opacity: 0.72
            Layout.fillWidth: true
        }

        Column {
            id: locationResultsColumn

            Kirigami.FormData.label: i18nc("@label:listbox", "Results:")
            visible: root.locationMatches.length > 0
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: root.locationMatches

                delegate: Rectangle {
                    id: locationResultRow

                    readonly property var result: modelData || ({
                    })

                    width: locationResultsColumn.width
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

            Kirigami.FormData.label: i18nc("@label:textbox", "Latitude:")
            text: root.coordinateText(root.cfg_latitude)
            placeholderText: "31.2304"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            Layout.fillWidth: true
            onAccepted: root.applyLatitudeText()
            onEditingFinished: root.applyLatitudeText()

            Connections {
                function onCfg_latitudeChanged() {
                    if (!latitudeField.activeFocus)
                        latitudeField.text = root.coordinateText(root.cfg_latitude);

                }

                target: root
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

            Kirigami.FormData.label: i18nc("@label:textbox", "Longitude:")
            text: root.coordinateText(root.cfg_longitude)
            placeholderText: "121.4737"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            Layout.fillWidth: true
            onAccepted: root.applyLongitudeText()
            onEditingFinished: root.applyLongitudeText()

            Connections {
                function onCfg_longitudeChanged() {
                    if (!longitudeField.activeFocus)
                        longitudeField.text = root.coordinateText(root.cfg_longitude);

                }

                target: root
            }

            validator: DoubleValidator {
                bottom: -180
                top: 180
                decimals: 4
                notation: DoubleValidator.StandardNotation
            }

        }

        QQC2.ComboBox {
            id: unitCombo

            Kirigami.FormData.label: i18nc("@label:listbox", "Units:")
            textRole: "text"
            valueRole: "value"
            model: root.unitOptions
            currentIndex: root.unitOptionIndex(root.cfg_temperatureUnit)
            onActivated: root.cfg_temperatureUnit = currentValue
        }

        QQC2.ComboBox {
            id: iconStyleCombo

            Kirigami.FormData.label: i18nc("@label:listbox", "Icons:")
            textRole: "text"
            valueRole: "value"
            model: root.iconStyleOptions
            currentIndex: root.iconStyleOptionIndex(root.cfg_iconStyle)
            Layout.fillWidth: true
            onActivated: root.cfg_iconStyle = currentValue
        }

        QQC2.ComboBox {
            id: refreshCombo

            Kirigami.FormData.label: i18nc("@label:listbox", "Refresh:")
            textRole: "text"
            valueRole: "value"
            model: root.refreshOptionModel(root.cfg_refreshMinutes)
            currentIndex: root.refreshOptionIndex(root.cfg_refreshMinutes)
            Layout.fillWidth: true
            onActivated: root.cfg_refreshMinutes = Number(currentValue)
        }

        QQC2.CheckBox {
            id: showPanelTextCheck

            text: i18nc("@option:check", "Show temperature text in horizontal panels")
        }

    }

}
