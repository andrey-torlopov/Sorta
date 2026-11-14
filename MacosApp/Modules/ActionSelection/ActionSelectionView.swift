import SwiftUI

/// Экран выбора действия после выбора source. Сетка из 3 frosted-glass карточек.
/// Metal тут НЕТ - статичный тёмный фон.
struct ActionSelectionView: View {
    @Environment(\.appLocalizer) private var localizer
    @Environment(AppCoordinator.self) private var coordinator

    private let columns = [
        GridItem(.adaptive(minimum: 250, maximum: 300), spacing: DesignSystem.Spacing.gridSpacing)
    ]

    var body: some View {
        ZStack {
            DesignSystem.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xxl) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(localizer("action_select_source_caption"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(Colors.textTertiary)
                        Text(coordinator.sourcePath(using: localizer))
                            .font(DesignSystem.Typography.bodyEmphasis)
                            .foregroundColor(Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.xxl)

                    LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.gridSpacing) {
                        ForEach(PhotoAction.allCases) { action in
                            ActionCardView(action: action) {
                                coordinator.open(action)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenEdge)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
        }
        .navigationTitle(localizer("action_selection_title"))
    }
}
