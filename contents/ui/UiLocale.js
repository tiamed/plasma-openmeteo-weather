.pragma library
.import "LocaleData.js" as LocaleData

function catalogCodes() {
    const catalogs = LocaleData.catalogs || {};
    return Object.keys(catalogs).sort();
}

function availableLanguages() {
    return ["en"].concat(catalogCodes());
}

function hasCatalog(language) {
    if (!language || language === "en")
        return language === "en";
    const catalogs = LocaleData.catalogs || {};
    return catalogs.hasOwnProperty(language);
}

function matchSystemLanguage() {
    const name = ((Qt.locale().name || "en_US").toString()).replace(/-/g, "_");
    const lower = name.toLowerCase();
    if (lower === "en" || lower.indexOf("en_") === 0)
        return "en";

    const codes = catalogCodes();
    for (let index = 0; index < codes.length; index++) {
        if (codes[index].toLowerCase() === lower)
            return codes[index];
    }

    const parts = name.split("_");
    const lang = (parts[0] || "").toLowerCase();
    const country = (parts[1] || "").toUpperCase();
    if (country) {
        for (let index = 0; index < codes.length; index++) {
            const codeParts = codes[index].split("_");
            if (codeParts[0].toLowerCase() === lang && (codeParts[1] || "").toUpperCase() === country)
                return codes[index];
        }
    }
    for (let index = 0; index < codes.length; index++) {
        if (codes[index].split("_")[0].toLowerCase() === lang)
            return codes[index];
    }
    return "en";
}

function resolveLanguage(configValue) {
    const value = (configValue || "system").toString();
    if (value === "system")
        return matchSystemLanguage();
    if (value === "en" || value === "en_US" || value === "en_GB")
        return "en";
    if (hasCatalog(value))
        return value;
    return matchSystemLanguage();
}

function localeName(language) {
    const resolved = resolveLanguage(language);
    if (resolved === "en")
        return "en_US";
    return resolved;
}

function usesChineseDateFormat(language) {
    return resolveLanguage(language).toLowerCase().indexOf("zh") === 0;
}

function languageDisplayName(language) {
    const code = language === "en" ? "en_US" : localeName(language);
    const locale = Qt.locale(code);
    if (locale && locale.nativeLanguageName)
        return locale.nativeLanguageName;
    return language;
}

function languageOptions(trSystemDefault) {
    const options = [{
        "text": trSystemDefault || "System default",
        "value": "system"
    }];
    const languages = availableLanguages();
    for (let index = 0; index < languages.length; index++) {
        const code = languages[index];
        options.push({
            "text": languageDisplayName(code),
            "value": code
        });
    }
    return options;
}

function translate(language, msgid) {
    if (!msgid)
        return "";
    const resolved = resolveLanguage(language);
    if (resolved === "en")
        return msgid;
    const catalogs = LocaleData.catalogs || {};
    const catalog = catalogs[resolved] || {};
    return catalog.hasOwnProperty(msgid) ? catalog[msgid] : msgid;
}

function format(language, msgid /*, ...args */) {
    let text = translate(language, msgid);
    for (let index = 2; index < arguments.length; index++) {
        const token = "%" + (index - 1);
        text = text.split(token).join(String(arguments[index]));
    }
    return text;
}

function translatePlural(language, singular, plural, count) {
    const msgid = Number(count) === 1 ? singular : plural;
    return format(language, msgid, count);
}
