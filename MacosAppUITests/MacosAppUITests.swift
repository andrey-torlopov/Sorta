import XCTest

@MainActor
final class MacosAppUITests: XCTestCase {
    func testFirstRunBlocksClosingThenAllowsAcknowledgementAndImmediateRepeatViewing() {
        continueAfterFailure = false
        let app = launch(language: "en", onboarding: "required")
        defer { app.terminate() }
        let close = app.buttons["important-information-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertFalse(close.isEnabled)
        app.typeKey(.escape, modifierFlags: [])
        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(close.exists, "Escape and Cmd+W must not dismiss mandatory information")
        XCTAssertFalse(close.isEnabled)

        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: close)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 35), .completed)
        XCTAssertEqual(close.label, "Close")
        close.click()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3))

        openInformation(in: app, title: "Important Information")
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        XCTAssertTrue(close.isEnabled, "Help must not restart the mandatory countdown after acknowledgement")
        XCTAssertEqual(close.label, "Close")
        close.click()

        app.menuBars.menuBarItems["Sorta"].click()
        app.menuBars.menuItems["About Sorta"].click()
        XCTAssertTrue(app.buttons["about-link-repository"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["about-link-boosty"].exists)
        XCTAssertTrue(app.buttons["about-link-support"].exists)
        XCTAssertTrue(app.staticTexts["Andrey Torlopov"].exists)
    }

    func testRussianInformationAndAboutAfterAcknowledgement() {
        continueAfterFailure = false
        let app = launch(language: "ru", onboarding: "completed")
        defer { app.terminate() }
        XCTAssertFalse(app.buttons["important-information-close"].exists)
        openInformation(in: app, title: "Важная информация")
        let close = app.buttons["important-information-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        XCTAssertTrue(close.isEnabled)
        XCTAssertEqual(close.label, "Закрыть")
        let paragraph = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Фотографии — самое важное")).firstMatch
        XCTAssertTrue(paragraph.exists)
        close.click()
        app.menuBars.menuBarItems["Sorta"].click()
        app.menuBars.menuItems["О Sorta"].click()
        XCTAssertTrue(app.buttons["about-link-repository"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Андрей Торлопов"].exists)
        XCTAssertEqual(app.buttons["about-link-boosty"].label, "Мой Boosty")
    }

    private func launch(language: String, onboarding: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ru" ? "ru_RU" : "en_US"]
        app.launchEnvironment["SORTA_UI_TEST_ONBOARDING"] = onboarding
        app.launch()
        return app
    }

    private func openInformation(in app: XCUIApplication, title: String) {
        let help = app.menuBars.menuBarItems.matching(NSPredicate(format: "label IN %@", ["Help", "Справка", "Помощь"])).firstMatch
        XCTAssertTrue(help.waitForExistence(timeout: 3))
        help.click()
        app.menuBars.menuItems[title].click()
    }
}
