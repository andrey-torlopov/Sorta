import SwiftUI

/// Корень NavigationStack. Единственный экран с Metal-анимацией.
/// Пользователь выбирает ОДНУ исходную папку (source); по выбору поток уходит на ActionSelection.
struct WelcomeView: View {
    let onOpenSettings: () -> Void
    @Environment(\.appLocalizer) private var localizer
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            WelcomeBackground()

            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()

                VStack(spacing: DesignSystem.Spacing.m) {
                    Text(localizer("welcome_title"))
                        .font(DesignSystem.Typography.screenTitle)
                        .foregroundColor(Colors.textPrimary)
                    Text(localizer("welcome_subtitle"))
                        .font(DesignSystem.Typography.bodyEmphasis)
                        .foregroundColor(Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                GlassCard {
                    FolderDropZone(
                        title: localizer("source_folder_button"),
                        pathText: coordinator.sourcePath(using: localizer)
                    ) { url in
                        Task { await coordinator.selectSource(url) }
                    }
                }
                .frame(maxWidth: 520)

                Spacer()
                Button(action: onOpenSettings) {
                    Label(localizer("settings_title"), systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("open-settings")
                .padding(.bottom, 24)
            }
            .padding(.horizontal, DesignSystem.Spacing.screenEdge)
        }
    }
}

/// Управляет жизненным циклом Metal-рендера: пауза, когда welcome не виден ИЛИ окно неактивно.
/// При отсутствии Metal - статичный тёмный фон Pro Dark Glass.
struct WelcomeBackground: View {
    @Environment(\.appLocalizer) private var localizer
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        Group {
            if GlowMetalView.isMetalAvailable {
                GlowMetalView(
                    isPaused: !isVisible || scenePhase != .active,
                    isLight: colorScheme == .light
                )
                .overlay(Colors.base.opacity(0.35)) // подложка под контраст текста (адаптивна к теме)
            } else {
                DesignSystem.screenBackground
            }
        }
        .ignoresSafeArea()
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
