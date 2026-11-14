import Foundation

struct AboutConfiguration {
    let version: String?
    let build: String?
    let links: [AboutExternalLink]

    static let developerLinks: [AboutExternalLink] = [
        AboutExternalLink(id: "boosty", titleKey: "about_boosty", symbol: "heart",
                          address: "https://boosty.to/andreytorlopov", displayAddress: "boosty.to/andreytorlopov"),
        AboutExternalLink(id: "gui_repository", titleKey: "about_gui_repository", symbol: "macwindow",
                          address: "https://github.com/andrey-torlopov/Sorta", displayAddress: "andrey-torlopov / Sorta"),
        AboutExternalLink(id: "repository", titleKey: "about_cli_repository", symbol: "chevron.left.forwardslash.chevron.right",
                          address: "https://github.com/andrey-torlopov/PhotoSorterCLI", displayAddress: "andrey-torlopov / PhotoSorterCLI", descriptionKey: "about_cli_description"),
        AboutExternalLink(id: "support", titleKey: "about_support", symbol: "envelope",
                          address: "mailto:mail@torlopov.dev", displayAddress: "mail@torlopov.dev")
    ]
}

