import XCTest
@testable import MacosApp

final class LocalizationTests: XCTestCase {
    func testLanguageResolvesRegionsAndUnsupportedPreferences() {
        XCTAssertEqual(AppLocalization.language(preferences: ["ru_RU"]), "ru")
        XCTAssertEqual(AppLocalization.language(preferences: ["en_US"]), "en")
        XCTAssertEqual(AppLocalization.language(preferences: ["en_GB"]), "en")
        XCTAssertEqual(AppLocalization.language(preferences: ["fr_FR"]), "en")
        XCTAssertEqual(AppLocalization.language(preferences: ["fr_FR", "ru_RU"]), "ru")
    }

    func testStringLookupUsesRequestedLanguageAndEnglishFallback() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        let contents = root.appendingPathComponent("Contents")
        let resources = contents.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let info: [String: Any] = [
            "CFBundleIdentifier": "dev.torlopov.sorta.tests.\(UUID().uuidString)",
            "CFBundleDevelopmentRegion": "en",
            "CFBundleLocalizations": ["en", "ru"]
        ]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: contents.appendingPathComponent("Info.plist"))
        for (language, value) in [
            ("en", "\"greeting\" = \"Hello\";\n\"fallback\" = \"English fallback\";"),
            ("ru", "\"greeting\" = \"Привет\";")
        ] {
            let folder = resources.appendingPathComponent(language + ".lproj")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try value.write(to: folder.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
        }
        let bundle = try XCTUnwrap(Bundle(url: root))
        XCTAssertEqual(AppLocalization.string("greeting", in: bundle, preferences: ["ru-RU"]), "Привет")
        XCTAssertEqual(AppLocalization.string("greeting", in: bundle, preferences: ["en-GB"]), "Hello")
        XCTAssertEqual(AppLocalization.string("fallback", in: bundle, preferences: ["ru-RU"]), "English fallback")
        XCTAssertEqual(AppLocalization.string("greeting", in: bundle, preferences: ["fr-FR"]), "Hello")
    }

    func testHelpLanguageAndMissingSectionUseTheSameFallback() throws {
        let data = Data(#"{"en":{"intro":"Introduction","safety":"Keep originals"},"ru":{"intro":"Введение"}}"#.utf8)
        let russian = try HelpDocument.decode(data, language: "ru")
        XCTAssertEqual(russian["intro"], "Введение")
        XCTAssertEqual(russian["safety"], "Keep originals")
        XCTAssertEqual(try HelpDocument.decode(data, language: "de")["intro"], "Introduction")
        XCTAssertThrowsError(try HelpDocument.decode(Data("{}".utf8), language: "ru"))
        XCTAssertThrowsError(try HelpDocument.decode(Data("invalid".utf8), language: "en"))
    }
}
