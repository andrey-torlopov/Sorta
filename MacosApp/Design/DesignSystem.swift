import SwiftUI

enum DesignSystem {

    /// Статичный тёмный фон для всех экранов, кроме welcome (там Metal).
    /// Заменяет старый кремовый `gradientBackground`.
    static var screenBackground: some View {
        Colors.base
    }

    /// Единая пружинная анимация для hover/pressed-состояний (как в референсе Sorta).
    static let interactionAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)

    // MARK: - Типографика

    enum Typography {
        static let screenTitle = Font.system(size: 28, weight: .bold)
        static let sectionHeader = Font.system(size: 20, weight: .semibold)
        static let cardTitle = Font.system(size: 18, weight: .semibold)
        static let bodyEmphasis = Font.system(size: 16, weight: .medium)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let logMono = Font.system(size: 13, weight: .regular, design: .monospaced)
    }

    // MARK: - Отступы

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24       // внутренний padding карточки
        static let screenEdge: CGFloat = 40 // боковые отступы экрана
        static let gridSpacing: CGFloat = 20
    }

    // MARK: - Радиусы

    enum Radius {
        static let field: CGFloat = 12
        static let button: CGFloat = 12
        static let card: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Тени

    enum Shadow {
        static let cardColor = Color.black.opacity(0.20)
        static let cardRadius: CGFloat = 10
        static let cardY: CGFloat = 5

        static let accentColor = Colors.accent.opacity(0.30)
        static let accentRadius: CGFloat = 10
        static let accentY: CGFloat = 5

        static let subtleColor = Color.black.opacity(0.15)
        static let subtleRadius: CGFloat = 6
        static let subtleY: CGFloat = 3
    }
}
