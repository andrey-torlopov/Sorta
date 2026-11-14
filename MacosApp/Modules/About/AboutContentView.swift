import SwiftUI

struct AboutContentView: View {
    let configuration: AboutConfiguration
    @Environment(\.appLocalizer) private var localizer

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Sorta").font(DesignSystem.Typography.screenTitle)
                    Text(versionDescription)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(Colors.textSecondary)
                        .textSelection(.enabled)
                }
                DeveloperInformationView(links: configuration.links)
                Text(localizer("about_description"))
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Colors.textPrimary)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 480, idealWidth: 550, minHeight: 560, idealHeight: 700)
        .background(DesignSystem.screenBackground)
        .accessibilityIdentifier("about-content")
    }

    private var versionDescription: String {
        if let version = configuration.version, let build = configuration.build {
            return localizer("about_version_build", version, build)
        }
        if let version = configuration.version {
            return localizer("about_version", version)
        }
        return localizer("about_version_unavailable")
    }

}
