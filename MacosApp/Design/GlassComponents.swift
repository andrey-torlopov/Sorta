import SwiftUI

// MARK: - Frosted-glass фон карточки

/// Каноничный рецепт frosted-glass поверхности: реальный blur (`.ultraThinMaterial`)
/// под белым градиентом + обводка `glassStroke` (~0.15) + мягкая тень для отрыва от фона.
struct GlassCardBackground: View {
    var isHovered: Bool = false
    var cornerRadius: CGFloat = DesignSystem.Radius.card

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                isHovered ? Colors.glassFillTopHover : Colors.glassFillTop,
                                isHovered ? Colors.glassFillBottomHover : Colors.glassFillBottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHovered ? Colors.glassStrokeHover : Colors.glassStroke, lineWidth: 1)
            )
            .shadow(
                color: DesignSystem.Shadow.cardColor,
                radius: DesignSystem.Shadow.cardRadius,
                x: 0,
                y: DesignSystem.Shadow.cardY
            )
    }
}

// MARK: - Контейнер-карточка

/// Glass-контейнер для панелей конфигурации, статуса процесса и т.п.
/// Hover-масштаб включается параметром `isHoverEnabled` (по умолчанию выключен -
/// панели не «дышат», в отличие от кликабельных плиток действий).
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = DesignSystem.Radius.card
    var padding: CGFloat = DesignSystem.Spacing.xxl
    var isHoverEnabled: Bool = false
    @ViewBuilder let content: () -> Content

    @State private var isHovered = false

    var body: some View {
        content()
            .padding(padding)
            .background(GlassCardBackground(isHovered: isHoverEnabled && isHovered, cornerRadius: cornerRadius))
            .scaleEffect(isHoverEnabled && isHovered ? 1.03 : 1.0)
            .animation(DesignSystem.interactionAnimation, value: isHovered)
            .onHover { hovering in
                guard isHoverEnabled else { return }
                isHovered = hovering
            }
    }
}

// MARK: - Тоггл-строка

/// Строка-переключатель опции: заголовок (+ опц. подзаголовок) слева, нативный switch справа.
/// Трек включённого тоггла красится в акцент.
struct GlassToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(Colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(Colors.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Colors.accent)
        }
        .padding(.vertical, DesignSystem.Spacing.s)
    }
}

// MARK: - Стили кнопок

/// Акцентная кнопка (главное действие). Через `ButtonStyle`, чтобы корректно
/// ловить `configuration.isPressed`.
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let fill: Color = !isEnabled
            ? Colors.accentDisabled
            : (configuration.isPressed ? Colors.accentPressed : Colors.accent)
        return configuration.label
            .font(DesignSystem.Typography.bodyEmphasis)
            .foregroundColor(isEnabled ? Colors.onAccent : Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                    .fill(
                        LinearGradient(
                            colors: [fill, fill.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                            .stroke(Colors.glassStrokeStrong, lineWidth: 1)
                    )
            )
            .shadow(
                color: Colors.accent.opacity(isEnabled ? 0.30 : 0),
                radius: DesignSystem.Shadow.accentRadius,
                x: 0,
                y: DesignSystem.Shadow.accentY
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.interactionAnimation, value: configuration.isPressed)
    }
}

/// Вторичная glass-кнопка (например, «Назад», «Выбрать другую папку»).
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyEmphasis)
            .foregroundColor(Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                            .fill(configuration.isPressed ? Colors.glassFillTopHover : Colors.glassFillTop)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                            .stroke(Colors.glassStroke, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.interactionAnimation, value: configuration.isPressed)
    }
}

/// Деструктивная кнопка («Прервать»). Та же схема, что Primary, но заливка - `error`.
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fill = configuration.isPressed ? Colors.error.opacity(0.85) : Colors.error
        return configuration.label
            .font(DesignSystem.Typography.bodyEmphasis)
            .foregroundColor(Colors.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                    .fill(
                        LinearGradient(
                            colors: [fill, fill.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.button)
                            .stroke(Colors.glassStrokeStrong, lineWidth: 1)
                    )
            )
            .shadow(color: Colors.error.opacity(0.30), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.interactionAnimation, value: configuration.isPressed)
    }
}
