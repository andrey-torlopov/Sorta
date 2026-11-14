import SwiftUI
import AppKit

struct DeveloperInformationView: View {
    let links: [AboutExternalLink]
    var compact = false
    @Environment(\.appLocalizer) private var localizer
    @Environment(\.openURL) private var openURL
    @State private var linkAction = AboutLinkAction()

    var body: some View {
        GlassCard {
            VStack(spacing: compact ? 14 : 24) {
                VStack(spacing: 10) {
                    Image("DeveloperAvatar")
                        .resizable()
                        .scaledToFill()
                        .frame(width: compact ? 64 : 112, height: compact ? 64 : 112)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Colors.glassStrokeStrong, lineWidth: 1))
                        .accessibilityHidden(true)
                    Text(localizer("about_developer_name"))
                        .font(DesignSystem.Typography.sectionHeader)
                    Text(localizer("about_developer_role"))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(Colors.textSecondary)
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: compact ? 8 : 12) {
                    ForEach(links) { link in
                        linkButton(link)
                    }
                }
            }
        }

        .alert(localizer("about_link_failed"), isPresented: Binding(
            get: { linkAction.failedLink != nil },
            set: { if !$0 { linkAction.failedLink = nil } }
        ), presenting: linkAction.failedLink) { link in
            Button(localizer("about_link_retry")) { open(link) }
            Button(localizer("about_link_copy")) {
                linkAction.copy(link) { address in
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(address, forType: .string)
                }
            }
            Button(localizer("about_link_cancel"), role: .cancel) { linkAction.failedLink = nil }
        } message: { link in
            Text(link.address)
        }
    }

    private func linkButton(_ link: AboutExternalLink) -> some View {
        Button { open(link) } label: {
            HStack(spacing: 14) {
                Image(systemName: link.symbol)
                    .font(.title3)
                    .foregroundStyle(Colors.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 5) {
                    Text(localizer(link.titleKey))
                        .font(DesignSystem.Typography.bodyEmphasis)
                    Text(link.displayAddress)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(Colors.textSecondary)
                    if let descriptionKey = link.descriptionKey {
                        Text(localizer(descriptionKey))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Colors.accent)
            }
            .padding(compact ? 10 : 16)
            .frame(maxWidth: .infinity, minHeight: compact ? 48 : 64)
            .background(GlassCardBackground(cornerRadius: DesignSystem.Radius.button))
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button))
        }
        .buttonStyle(.plain)
        .disabled(linkAction.pendingLink != nil)
        .accessibilityLabel(localizer(link.titleKey))
        .accessibilityHint(localizer("about_external_link_hint"))
        .accessibilityIdentifier("about-link-\(link.id)")
    }

    private func open(_ link: AboutExternalLink) {
        linkAction.open(link) { url, completion in
            // NSWorkspace may finish on its launch-services queue, not MainActor.
            let callback: @Sendable (Bool) -> Void = { accepted in
                Task { @MainActor in completion(accepted) }
            }
            openURL(url, completion: callback)
        }
    }
}
