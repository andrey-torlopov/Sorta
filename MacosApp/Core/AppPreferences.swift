import AppKit
import SwiftUI

enum AppLanguage: String, CaseIterable, Sendable {
    case en, ru
    var name: String { self == .ru ? "Русский" : "English" }
}

enum AppTheme: String, CaseIterable, Sendable {
    case system, light, dark
    var titleKey: String { "settings_theme_\(rawValue)" }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

@MainActor
protocol AppPreferencesStoring {
    var language: String? { get set }
    var theme: String? { get set }
}

@MainActor
final class UserDefaultsPreferencesStore: AppPreferencesStoring {
    private let defaults: UserDefaults
    init(defaults: UserDefaults) { self.defaults = defaults }
    var language: String? {
        get { defaults.string(forKey: "appearance.language") }
        set { defaults.set(newValue, forKey: "appearance.language") }
    }
    var theme: String? {
        get { defaults.string(forKey: "appearance.theme") }
        set { defaults.set(newValue, forKey: "appearance.theme") }
    }
}

@MainActor
final class MemoryPreferencesStore: AppPreferencesStoring {
    var language: String?
    var theme: String?
}

/// Presentation preferences never own navigation, file access or operation tasks.
@MainActor @Observable
final class AppPreferences {
    var language: AppLanguage {
        didSet {
            store.language = language.rawValue
            languageDidChange(localizer)
        }
    }
    /// Composition-only wiring; the presentation controller is created after preferences.
    @ObservationIgnored var languageDidChange: (AppLocalizer) -> Void = { _ in }
    var theme: AppTheme {
        didSet {
            store.theme = theme.rawValue
            applyTheme(theme)
        }
    }
    private var store: any AppPreferencesStoring
    private let applyTheme: (AppTheme) -> Void

    init(store: any AppPreferencesStoring, systemLanguage: String = AppLocalization.language,
         applyTheme: @escaping (AppTheme) -> Void = { _ in }) {
        self.store = store
        self.applyTheme = applyTheme
        language = store.language.flatMap(AppLanguage.init(rawValue:))
            ?? AppLanguage(rawValue: systemLanguage) ?? .en
        theme = store.theme.flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    var localizer: AppLocalizer { AppLocalizer(language: language) }
}

struct AppLocalizer: Equatable, Sendable {
    let language: AppLanguage
    var locale: Locale { Locale(identifier: language.rawValue) }

    func callAsFunction(_ key: String, _ arguments: CVarArg...) -> String {
        string(key, arguments: arguments)
    }

    func string(_ key: String, arguments: [CVarArg] = []) -> String {
        let format = AppLocalization.string(key, preferences: [language.rawValue])
        return arguments.isEmpty ? format : String(format: format, locale: locale, arguments: arguments)
    }
}

private struct AppLocalizerKey: EnvironmentKey {
    static let defaultValue = AppLocalizer(language: AppLanguage(rawValue: AppLocalization.language) ?? .en)
}

extension EnvironmentValues {
    var appLocalizer: AppLocalizer {
        get { self[AppLocalizerKey.self] }
        set { self[AppLocalizerKey.self] = newValue }
    }
}

/// Each hosting root observes the same preferences without replacing its content identity.
struct PreferencesRoot<Content: View>: View {
    let preferences: AppPreferences
    var titleKey: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        let localizer = preferences.localizer
        content()
            .environment(\.appLocalizer, localizer)
            .environment(\.locale, localizer.locale)
            .preferredColorScheme(preferences.theme.colorScheme)
            .background(WindowAccessor { window in
                if let titleKey { window.title = localizer(titleKey) }
                window.appearance = preferences.theme.appearance
            })
    }
}
