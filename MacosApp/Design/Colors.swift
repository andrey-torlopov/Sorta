import SwiftUI
import AppKit

// MARK: - Хелперы адаптивных цветов

private func rgb(_ r: Double, _ g: Double, _ b: Double) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
}

private func whiteAlpha(_ a: Double) -> NSColor {
    NSColor(srgbRed: 1, green: 1, blue: 1, alpha: a)
}

private func blackAlpha(_ a: Double) -> NSColor {
    NSColor(srgbRed: 0, green: 0, blue: 0, alpha: a)
}

private extension Color {
    /// Динамический цвет, который сам резолвится под текущую системную тему (light/dark).
    static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

/// Палитра Pro Glass с поддержкой светлой и тёмной тем.
///
/// Тёмная: база `#0D0D14`, акцент `#6E8BFF`, белый frosted-glass.
/// Светлая: база `#EEF0F6`, тот же акцент, светлый frosted-glass с тёмными обводками.
/// Все токены адаптивны (динамический `NSColor`) - приложение следует системной теме.
/// Старые «кремовые» имена сохранены как алиасы, чтобы переиспользуемые файлы компилировались.
enum Colors {

    // MARK: - База и поверхности (elevation)

    static let base = Color.adaptive(
        light: rgb(0.9333, 0.9412, 0.9647),   // #EEF0F6
        dark:  rgb(0.0510, 0.0510, 0.0784)    // #0D0D14
    )
    static let surface1 = Color.adaptive(
        light: rgb(0.9647, 0.9686, 0.9843),   // #F6F7FB
        dark:  rgb(0.0784, 0.0784, 0.1216)    // #14141F
    )
    static let surface2 = Color.adaptive(
        light: rgb(1.0000, 1.0000, 1.0000),   // #FFFFFF
        dark:  rgb(0.1098, 0.1098, 0.1686)    // #1C1C2B
    )
    static let surface3 = Color.adaptive(
        light: rgb(0.8941, 0.9059, 0.9451),   // #E4E7F1
        dark:  rgb(0.1490, 0.1490, 0.2196)    // #262638
    )

    // MARK: - Frosted-glass (заливка и обводка)
    // В тёмной теме - полупрозрачный белый поверх тёмной базы.
    // В светлой - более плотный белый (карточки «выбеливаются» над светлой базой) + тёмные обводки.

    static let glassFillTop = Color.adaptive(light: whiteAlpha(0.55), dark: whiteAlpha(0.10))
    static let glassFillBottom = Color.adaptive(light: whiteAlpha(0.38), dark: whiteAlpha(0.05))
    static let glassFillTopHover = Color.adaptive(light: whiteAlpha(0.72), dark: whiteAlpha(0.18))
    static let glassFillBottomHover = Color.adaptive(light: whiteAlpha(0.55), dark: whiteAlpha(0.12))
    static let glassStroke = Color.adaptive(light: blackAlpha(0.10), dark: whiteAlpha(0.15))
    static let glassStrokeHover = Color.adaptive(light: blackAlpha(0.22), dark: whiteAlpha(0.40))
    static let glassStrokeStrong = Color.adaptive(light: blackAlpha(0.15), dark: whiteAlpha(0.25))

    // MARK: - Акцент и его состояния

    /// Базовый акцент `#6E8BFF` - одинаков в обеих темах (белый текст читается на нём всегда).
    static let accent = Color(red: 0.4314, green: 0.5451, blue: 1.0000)
    static let accentHover = Color(red: 0.5412, green: 0.6314, blue: 1.0000)   // #8AA1FF
    static let accentPressed = Color(red: 0.3451, green: 0.4471, blue: 0.9020) // #5872E6
    static let accentDisabled = Color.adaptive(
        light: rgb(0.7608, 0.7922, 0.9098),   // #C2CAE8
        dark:  rgb(0.2275, 0.2667, 0.4392)    // #3A4470
    )

    /// Цвет подписей на акцентной заливке - всегда светлый (фон кнопки синий в обеих темах).
    static let onAccent = Color(red: 0.9608, green: 0.9647, blue: 0.9804)

    // MARK: - Семантика лога (калибруется под тему для контраста)

    static let success = Color.adaptive(
        light: rgb(0.0863, 0.6392, 0.2902),   // #16A34A
        dark:  rgb(0.2902, 0.8706, 0.5020)    // #4ADE80
    )
    static let warning = Color.adaptive(
        light: rgb(0.7059, 0.3255, 0.0353),   // #B45309
        dark:  rgb(0.9843, 0.7490, 0.1412)    // #FBBF24
    )
    static let error = Color.adaptive(
        light: rgb(0.8627, 0.1490, 0.1490),   // #DC2626
        dark:  rgb(0.9725, 0.4431, 0.4431)    // #F87171
    )
    static let info = Color.adaptive(
        light: rgb(0.1451, 0.3882, 0.9216),   // #2563EB
        dark:  rgb(0.3765, 0.6471, 0.9804)    // #60A5FA
    )

    // MARK: - Текст

    static let textPrimary = Color.adaptive(
        light: rgb(0.1059, 0.1137, 0.1608),   // #1B1D29
        dark:  rgb(0.9608, 0.9647, 0.9804)    // #F5F6FA
    )
    static let textSecondary = Color.adaptive(
        light: rgb(0.2902, 0.3059, 0.3882),   // #4A4E63
        dark:  rgb(0.6627, 0.6784, 0.7451)    // #A9ADBE
    )
    static let textTertiary = Color.adaptive(
        light: rgb(0.4863, 0.5059, 0.5804),   // #7C8194
        dark:  rgb(0.4314, 0.4471, 0.5255)    // #6E7286
    )

    // MARK: - Разделители

    static let separator = Color.adaptive(light: blackAlpha(0.08), dark: whiteAlpha(0.08))
    static let border = Color.adaptive(light: blackAlpha(0.12), dark: whiteAlpha(0.12))

    // MARK: - Совместимость со старыми именами

    static let lightCream = base
    static let mediumCream = surface1
    static let darkCream = surface2
    static let accentColor = accent
    static let highlight = accent
    static let textColor = textPrimary
    static let placeholderText = textTertiary
    static let textFieldBackground = surface2
    static let logBackground = surface1
    static let successText = success
    static let errorText = error
    static let checkboxActive = accent
    static let checkboxInactive = textTertiary
}

// MARK: - Preview

struct ColorsPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                SectionView(title: "Surfaces", colors: [
                    ("base", Colors.base),
                    ("surface1", Colors.surface1),
                    ("surface2", Colors.surface2),
                    ("surface3", Colors.surface3)
                ])
                SectionView(title: "Accent", colors: [
                    ("accent", Colors.accent),
                    ("accentHover", Colors.accentHover),
                    ("accentPressed", Colors.accentPressed),
                    ("accentDisabled", Colors.accentDisabled)
                ])
                SectionView(title: "Log semantics", colors: [
                    ("success", Colors.success),
                    ("warning", Colors.warning),
                    ("error", Colors.error),
                    ("info", Colors.info)
                ])
                SectionView(title: "Text", colors: [
                    ("textPrimary", Colors.textPrimary),
                    ("textSecondary", Colors.textSecondary),
                    ("textTertiary", Colors.textTertiary)
                ])
            }
            .padding()
        }
        .background(Colors.base)
    }
}

struct SectionView: View {
    let title: String
    let colors: [(name: String, color: Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Colors.textPrimary)
                .padding(.bottom, 8)

            ForEach(colors, id: \.name) { color in
                HStack {
                    Text(color.name)
                        .foregroundColor(Colors.textSecondary)
                        .frame(width: 150, alignment: .leading)
                    Rectangle()
                        .fill(color.color)
                        .frame(height: 40)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Colors.glassStroke, lineWidth: 1)
                        )
                }
            }
        }
    }
}

struct ColorsPreview_Previews: PreviewProvider {
    static var previews: some View {
        ColorsPreview()
    }
}
