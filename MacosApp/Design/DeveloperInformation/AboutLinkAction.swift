import Foundation
import Observation

@MainActor
@Observable
final class AboutLinkAction {
    private(set) var pendingLink: AboutExternalLink?
    var failedLink: AboutExternalLink?

    func open(_ link: AboutExternalLink,
              using opener: (URL, @escaping @MainActor (Bool) -> Void) -> Void) {
        guard pendingLink == nil else { return }
        guard let url = link.url else {
            failedLink = link
            return
        }
        failedLink = nil
        pendingLink = link
        opener(url) { [weak self] accepted in
            self?.pendingLink = nil
            self?.failedLink = accepted ? nil : link
        }
    }

    func copy(_ link: AboutExternalLink, using copyText: (String) -> Void) {
        copyText(link.address)
        failedLink = nil
    }
}
