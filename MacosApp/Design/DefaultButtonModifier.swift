import SwiftUI

struct DefaultButtonModifier: ViewModifier {
    var foregroundColor: Color = Colors.textColor
    var backgroundColor: Color = Colors.accentColor
    var cornerRadius: CGFloat = 10
    var shadowColor: Color = .black.opacity(0.2)
    var shadowRadius: CGFloat = 5
    var shadowOffset: (x: CGFloat, y: CGFloat) = (x: 0, y: 2)
    var padding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity) // Кнопка занимает всю доступную ширину
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: shadowOffset.x, y: shadowOffset.y)
    }
}

extension View {
    func defaultButtonStyle(
        foregroundColor: Color = Colors.textColor,
        backgroundColor: Color = Colors.accentColor,
        cornerRadius: CGFloat = 10,
        shadowColor: Color = .black.opacity(0.2),
        shadowRadius: CGFloat = 5,
        shadowOffset: (x: CGFloat, y: CGFloat) = (x: 0, y: 2),
        padding: CGFloat = 12
    ) -> some View {
        self.modifier(
            DefaultButtonModifier(
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                shadowColor: shadowColor,
                shadowRadius: shadowRadius,
                shadowOffset: shadowOffset,
                padding: padding
            )
        )
    }
}
