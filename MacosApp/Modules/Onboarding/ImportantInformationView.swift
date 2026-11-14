import SwiftUI

struct ImportantInformationView: View {
    @Environment(\.appLocalizer) private var localizer
    let state: OnboardingState
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Label(localizer("important_information_title"), systemImage: "photo.on.rectangle.angled")
                        .font(DesignSystem.Typography.screenTitle)
                        .foregroundStyle(Colors.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text(localizer("important_information_paragraph_one"))
                    Text(localizer("important_information_paragraph_two"))
                }
                .font(.system(size: 16))
                .foregroundStyle(Colors.textPrimary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
                .textSelection(.enabled)
            }

            Divider()
            Button(action: onClose) {
                Text(state.canAcknowledge
                     ? localizer("information_close")
                     : localizer("information_close_countdown", state.remainingSeconds))
                    .monospacedDigit()
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: state.canAcknowledge))
            .disabled(!state.canAcknowledge)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("important-information-close")
            .accessibilityHint(state.canAcknowledge
                               ? localizer("information_close_hint")
                               : localizer("information_countdown_hint", state.remainingSeconds))
            .frame(maxWidth: 300)
            .padding(20)
        }
        .frame(minWidth: 520, idealWidth: 620, minHeight: 480, idealHeight: 570)
        .background(DesignSystem.screenBackground)
    }
}
