import SwiftUI

struct ActionButtonView: View {
    let title: String
    let action: () async -> Void

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Text(title)
                .frame(width: 150)
                .defaultButtonStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 20)
    }
}
