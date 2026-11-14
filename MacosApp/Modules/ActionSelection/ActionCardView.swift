import SwiftUI

/// Карточка одного действия для сетки выбора. Frosted-glass + hover (масштаб, акцентная обводка/тень).
struct ActionCardView: View {
    @Environment(\.appLocalizer) private var localizer
    let action: PhotoAction
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Image(systemName: action.icon)
                .font(.system(size: 48))
                .foregroundColor(isHovered ? Colors.accent : Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(localizer(action.titleKey))
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundColor(Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(localizer(action.subtitleKey))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            ZStack {
                GlassCardBackground(isHovered: isHovered)
                if isHovered {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                        .stroke(Colors.accent, lineWidth: 1)
                }
            }
        )
        .shadow(
            color: isHovered ? Colors.accent.opacity(0.25) : .clear,
            radius: 12,
            x: 0,
            y: 6
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .animation(DesignSystem.interactionAnimation, value: isHovered)
    }
}
