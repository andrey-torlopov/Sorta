import SwiftUI

struct SettingsContentView: View {
    @Bindable var preferences: AppPreferences
    let developerLinks: [AboutExternalLink]
    @Environment(\.appLocalizer) private var localizer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizer("settings_title"))
                    .font(DesignSystem.Typography.screenTitle)
                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(localizer("settings_appearance"))
                            .font(DesignSystem.Typography.sectionHeader)
                        HStack(spacing: 10) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                choice(localizer(theme.titleKey), selected: preferences.theme == theme,
                                       identifier: "settings-theme-\(theme.rawValue)") {
                                    preferences.theme = theme
                                }
                            }
                        }
                        Text(localizer("settings_language"))
                            .font(DesignSystem.Typography.sectionHeader)
                        HStack(spacing: 10) {
                            ForEach([AppLanguage.ru, .en], id: \.self) { language in
                                choice(language.name, selected: preferences.language == language,
                                       identifier: "settings-language-\(language.rawValue)") {
                                    preferences.language = language
                                }
                            }
                        }
                        Text(localizer("settings_native_language_note"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                DeveloperInformationView(links: developerLinks, compact: true)
            }
            .padding(24)
            .foregroundStyle(Colors.textPrimary)
        }
        .frame(minWidth: 540, idealWidth: 580, minHeight: 520, idealHeight: 700)
        .background(DesignSystem.screenBackground)
    }

    private func choice(_ title: String, selected: Bool, identifier: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.bordered)
        .tint(selected ? Colors.accent : Colors.textSecondary)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}
