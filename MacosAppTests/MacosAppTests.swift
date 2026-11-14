import XCTest
import AppKit
@testable import MacosApp

@MainActor
final class MacosAppTests: XCTestCase {
    func testWindowCloseCannotBypassOnboarding() {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        let guardDelegate = WindowGuard()
        var showCount = 0
        guardDelegate.requiresOnboarding = { true }
        guardDelegate.onShowInformation = { showCount += 1 }
        XCTAssertFalse(guardDelegate.windowShouldClose(window))
        XCTAssertEqual(showCount, 1)
    }

    func testWindowCloseWaitsForActiveProcessing() {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        let guardDelegate = WindowGuard()
        var processing = true
        var blockedCount = 0
        guardDelegate.isProcessing = { processing }
        guardDelegate.onBlockedClose = { blockedCount += 1 }
        XCTAssertFalse(guardDelegate.windowShouldClose(window))
        XCTAssertEqual(blockedCount, 1)
        processing = false
        XCTAssertTrue(guardDelegate.windowShouldClose(window))
    }

    func testQuitIsAllowedDuringOnboardingButNotDuringProcessing() {
        let delegate = SortaAppDelegate()
        var processing = false
        var blockedCount = 0
        delegate.isProcessing = { processing }
        delegate.onBlockedTermination = { blockedCount += 1 }
        XCTAssertEqual(delegate.applicationShouldTerminate(NSApplication.shared), .terminateNow)
        processing = true
        XCTAssertEqual(delegate.applicationShouldTerminate(NSApplication.shared), .terminateCancel)
        XCTAssertEqual(blockedCount, 1)
    }
}
