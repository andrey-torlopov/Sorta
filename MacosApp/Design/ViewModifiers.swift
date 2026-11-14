import SwiftUI

struct CustomImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scaledToFit()
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
    }
}

extension Image {
    func customImageStyle() -> some View {
        self.modifier(CustomImageModifier())
    }
}

struct CustomTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Colors.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.top, 5)
    }
}

extension Text {
    func customTextStyle() -> some View {
        self.modifier(CustomTextModifier())
    }
}

struct CustomButtonBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Colors.accent.opacity(0.3), Colors.accent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func customButtonBackground() -> some View {
        self.modifier(CustomButtonBackgroundModifier())
    }
}
