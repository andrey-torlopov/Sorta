import Foundation

/// A single language choice for strings, long-form help and format arguments.
/// Bundle preferences include the language chosen for this app in macOS Settings.
enum AppLocalization {
    static var language: String { language(in: .main) }
    static var locale: Locale { Locale(identifier: language) }

    static func language(in bundle: Bundle = .main, preferences: [String]? = nil) -> String {
        let preferred = preferences ?? bundle.preferredLocalizations
        let resolved = Bundle.preferredLocalizations(from: ["en", "ru"], forPreferences: preferred)
        return resolved.first == "ru" ? "ru" : "en"
    }

    static func string(_ key: String, in bundle: Bundle = .main, preferences: [String]? = nil) -> String {
        let language = language(in: bundle, preferences: preferences)
        let english = bundle.url(forResource: "en", withExtension: "lproj")
            .flatMap(Bundle.init(url:))
        let fallback = (english ?? bundle).localizedString(forKey: key, value: key, table: nil)
        let localizedBundle = bundle.url(forResource: language, withExtension: "lproj")
            .flatMap(Bundle.init(url:)) ?? bundle
        return localizedBundle.localizedString(forKey: key, value: fallback, table: nil)
    }
}

extension String {
    var localized: String { AppLocalization.string(self) }

    func localized(_ args: CVarArg...) -> String {
        String(format: localized, locale: AppLocalization.locale, arguments: args)
    }

    /// Explicit locale selection for previews and tests, including region variants.
    func localized(in locale: Locale) -> String {
        AppLocalization.string(self, preferences: [locale.identifier])
    }
}
