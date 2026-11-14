import XCTest
import AppKit
@testable import MacosApp

@MainActor
final class AboutTests: XCTestCase {
    func testPendingLinkRejectsDuplicateOpenAndOffersRecoveryOnFailure() throws {
        let link = try XCTUnwrap(AboutConfiguration.developerLinks.first)
        let action = AboutLinkAction()
        var completion: (@MainActor (Bool) -> Void)?
        var opens = 0
        action.open(link) { _, callback in
            opens += 1
            completion = callback
        }
        action.open(link) { _, _ in opens += 1 }
        XCTAssertEqual(opens, 1)
        XCTAssertEqual(action.pendingLink, link)
        completion?(false)
        XCTAssertNil(action.pendingLink)
        XCTAssertEqual(action.failedLink, link)

        action.open(link) { _, callback in callback(true) }
        XCTAssertNil(action.failedLink)
        XCTAssertNil(action.pendingLink)
    }

    func testCopyPreservesTheExactAddressAndClearsFailure() throws {
        let link = try XCTUnwrap(AboutConfiguration.developerLinks.first(where: { $0.id == "repository" }))
        let action = AboutLinkAction()
        action.open(link) { _, callback in callback(false) }
        var copied: String?
        action.copy(link) { copied = $0 }
        XCTAssertEqual(copied, "https://github.com/andrey-torlopov/PhotoSorterCLI")
        XCTAssertNil(action.failedLink)
    }

    func testAvatarIsIncludedInTheApplicationBundle() {
        XCTAssertNotNil(NSImage(named: "DeveloperAvatar"), "The developer avatar must decode from the app asset catalog")
    }
}
