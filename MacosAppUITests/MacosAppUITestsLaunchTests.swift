import XCTest

@MainActor
final class MacosAppUITestsLaunchTests: XCTestCase {
    func testQuitBeforeAcknowledgementDoesNotCompleteFirstRun() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)"]
        app.launchEnvironment["SORTA_UI_TEST_ONBOARDING"] = "required"
        app.launch()
        XCTAssertTrue(app.buttons["important-information-close"].waitForExistence(timeout: 5))
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5), "Cmd+Q remains available during mandatory first run")
        app.launch()
        defer { app.terminate() }
        let close = app.buttons["important-information-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertFalse(close.isEnabled)
    }
}
