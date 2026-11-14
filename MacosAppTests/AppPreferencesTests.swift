import XCTest
import SwiftUI
@testable import MacosApp

@MainActor
final class AppPreferencesTests: XCTestCase {
    func testFirstLaunchUsesBundleLanguageAndExplicitChoiceSurvivesRestart() throws {
        let suite = "SortaPreferencesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var appliedThemes: [AppTheme] = []
        let first = AppPreferences(store: UserDefaultsPreferencesStore(defaults: defaults), systemLanguage: "ru",
                                   applyTheme: { appliedThemes.append($0) })
        XCTAssertEqual(first.language, .ru)
        XCTAssertEqual(first.theme, .system)
        var appliedLanguages: [AppLanguage] = []
        first.languageDidChange = { appliedLanguages.append($0.language) }
        first.language = .en
        XCTAssertEqual(appliedLanguages, [.en], "Menu updates must not depend on a live main view")
        first.theme = .dark
        XCTAssertEqual(appliedThemes, [.dark], "The app appearance callback must not depend on a main window")
        let restored = AppPreferences(store: UserDefaultsPreferencesStore(defaults: defaults), systemLanguage: "ru")
        XCTAssertEqual(restored.language, .en, "An explicit choice must win over the current system language")
        XCTAssertEqual(restored.theme, .dark)
        restored.theme = .system
        XCTAssertNil(restored.theme.appearance, "System mode must release the AppKit appearance override")
        XCTAssertNil(restored.theme.colorScheme)
        XCTAssertEqual(defaults.string(forKey: "appearance.theme"), "system")
    }

    func testUnknownStoredValuesFallBackWithoutChangingSystemDefaults() {
        let store = MemoryPreferencesStore()
        store.language = "removed-language"
        store.theme = "removed-theme"
        let preferences = AppPreferences(store: store, systemLanguage: "en")
        XCTAssertEqual(preferences.language, .en)
        XCTAssertEqual(preferences.theme, .system)
        XCTAssertEqual(store.language, "removed-language", "Reading preferences must not rewrite storage")
        XCTAssertEqual(AppLanguage.ru.name, "Русский")
        XCTAssertEqual(AppLanguage.en.name, "English")
    }

    func testExistingLogsAndNestedErrorsRenderInTheNewLanguage() throws {
        let preferences = AppPreferences(store: MemoryPreferencesStore(), systemLanguage: "en")
        let message = LocalizedMessage(key: "sort_photos_fileMovedFailed", arguments: [
            .text("/source/фото.jpg"), .text("/target/photo.jpg"),
            .message(LocalizedMessage(key: "operation_check_file_access"))
        ])
        let entry = OperationLogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), message: message)
        let english = entry.render(using: preferences.localizer)
        preferences.language = .ru
        let russian = entry.render(using: preferences.localizer)
        XCTAssertNotEqual(english, russian)
        XCTAssertTrue(english.contains("Failed to move file"))
        XCTAssertTrue(russian.contains("Ошибка перемещения"))
        for text in [english, russian] {
            XCTAssertTrue(text.contains("/source/фото.jpg"))
            XCTAssertTrue(text.contains("/target/photo.jpg"))
            XCTAssertFalse(text.contains("operation_check_file_access"))
        }
        XCTAssertTrue(russian.contains(preferences.localizer("operation_check_file_access")))
        let count = LocalizedMessage(key: "sort_photos_success", arguments: [.integer(4_294_967_297)])
        for language in AppLanguage.allCases {
            let rendered = count.render(using: AppLocalizer(language: language))
            let digits = rendered.filter(\.isNumber)
            XCTAssertEqual(digits, "4294967297", "Counts must not truncate to 32 bits")
        }
        XCTAssertEqual(preferences.localizer.locale.identifier, "ru")
        let ruHelp = try HelpDocument.load(language: preferences.language.rawValue)
        preferences.language = .en
        let enHelp = try HelpDocument.load(language: preferences.language.rawValue)
        XCTAssertNotEqual(ruHelp["important_text"], enHelp["important_text"])
    }

    func testChangingPresentationPreservesRunningOperationAndCancellationDrain() async {
        let preferences = AppPreferences(store: MemoryPreferencesStore(), systemLanguage: "en")
        let coordinator = AppCoordinator()
        await coordinator.selectSource(FileManager.default.temporaryDirectory)
        coordinator.open(.sortPhotos)
        let model = SortPhotosViewModel()
        coordinator.sortViewModel = model
        model.sourceFolderURL = FileManager.default.temporaryDirectory
        model.isRemoveOriginalFile = true
        let previousPath = coordinator.path
        let previousSource = coordinator.sourceURL
        let (started, signal) = AsyncStream<UUID>.makeStream()
        var release: CheckedContinuation<Void, Never>?
        model.session.start { id in
            await withCheckedContinuation { continuation in
                release = continuation
                signal.yield(id)
            }
            return .succeeded
        }
        var iterator = started.makeAsyncIterator()
        guard let id = await iterator.next() else { return XCTFail("No operation started") }
        preferences.language = .ru
        preferences.theme = .dark
        XCTAssertTrue(coordinator.sortViewModel === model)
        XCTAssertEqual(coordinator.path, previousPath)
        XCTAssertEqual(coordinator.sourceURL, previousSource)
        XCTAssertTrue(model.isRemoveOriginalFile)
        XCTAssertEqual(model.session.status, .running)
        XCTAssertTrue(model.session.acceptsEvents(for: id))
        model.session.cancel()
        preferences.language = .en
        preferences.theme = .light
        XCTAssertTrue(coordinator.isProcessing)
        XCTAssertEqual(model.session.status, .cancelling)
        release?.resume()
        await model.session.waitForCompletion()
        XCTAssertEqual(model.session.status, .cancelled)
        signal.finish()
    }

    func testApplicationMenuHeadingsPreserveActualNativeCommands() throws {
        let menu = try XCTUnwrap(NSApp.mainMenu)
        let appMenu = try XCTUnwrap(menu.items.first?.submenu)
        let identities = appMenu.items.filter { !$0.isSeparatorItem }.map { item in
            "title=\(item.title), action=\(item.action.map(NSStringFromSelector) ?? "nil"), identifier=\(item.identifier?.rawValue ?? "nil"), key=\(item.keyEquivalent)"
        }.joined(separator: "\n")
        let attachment = XCTAttachment(string: identities)
        attachment.name = "Sorta standard menu identities"
        attachment.lifetime = .keepAlways
        add(attachment)
        let nativeTitles = appMenu.items.map(\.title)
        let preferences = AppPreferences(store: MemoryPreferencesStore(), systemLanguage: "en")
        let presenter = AppMenuPresenter(preferences: preferences)
        preferences.language = .ru
        presenter.update(menu, helpMenu: NSApp.helpMenu, windowsMenu: NSApp.windowsMenu)
        XCTAssertTrue(menu.items.contains { $0.title == "Файл" })
        XCTAssertEqual(appMenu.items.map(\.title), nativeTitles)
        preferences.language = .en
        presenter.update(menu, helpMenu: NSApp.helpMenu, windowsMenu: NSApp.windowsMenu)
        XCTAssertTrue(menu.items.contains { $0.title == "File" })
        XCTAssertEqual(appMenu.items.map(\.title), nativeTitles)
    }

    func testMenuPresentationKeepsActionsShortcutsAndDynamicSystemItems() {
        let preferences = AppPreferences(store: MemoryPreferencesStore(), systemLanguage: "en")
        let presenter = AppMenuPresenter(preferences: preferences)
        let menu = NSMenu()
        let parent = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Edit")
        parent.submenu = submenu
        menu.addItem(parent)
        let copy = NSMenuItem(title: "Copy", action: NSSelectorFromString("copy:"), keyEquivalent: "c")
        let undo = NSMenuItem(title: "Undo Rename", action: NSSelectorFromString("undo:"), keyEquivalent: "z")
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let systemMenu = NSMenu(title: "Services")
        let systemCommand = NSMenuItem(title: "Third-party Copy", action: NSSelectorFromString("copy:"), keyEquivalent: "")
        systemMenu.addItem(systemCommand)
        services.submenu = systemMenu
        submenu.addItem(copy)
        submenu.addItem(undo)
        submenu.addItem(services)
        let viewParent = NSMenuItem(title: "Вид", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "Вид")
        let tabCommand = NSMenuItem(title: "Скрыть панель вкладок", action: NSSelectorFromString("toggleTabBar:"), keyEquivalent: "")
        viewMenu.addItem(tabCommand)
        viewParent.submenu = viewMenu
        menu.addItem(viewParent)
        preferences.language = .ru
        presenter.update(menu)
        XCTAssertEqual(parent.title, "Правка")
        XCTAssertEqual(copy.title, "Copy", "Standard command titles remain owned by AppKit")
        XCTAssertEqual(copy.action, NSSelectorFromString("copy:"))
        XCTAssertEqual(copy.keyEquivalent, "c")
        XCTAssertEqual(undo.title, "Undo Rename", "Dynamic undo descriptions belong to the system")
        XCTAssertEqual(services.title, "Services")
        XCTAssertEqual(systemCommand.title, "Third-party Copy")
        preferences.language = .en
        presenter.update(menu)
        XCTAssertEqual(parent.title, "Edit")
        XCTAssertEqual(copy.title, "Copy")
        XCTAssertEqual(viewParent.title, "View")
        XCTAssertEqual(tabCommand.title, "Скрыть панель вкладок", "Stateful AppKit labels remain system-owned")
    }

    func testChangingLanguageAndThemeDoesNotAcknowledgeOrRestartOnboarding() {
        let preferences = AppPreferences(store: MemoryPreferencesStore(), systemLanguage: "en")
        let origin = ContinuousClock.now
        var now = origin
        let store = PreferencesOnboardingStore()
        let onboarding = OnboardingState(store: store, monotonicTime: { now })
        onboarding.didPresent()
        now = origin.advanced(by: .seconds(17))
        preferences.language = .ru
        preferences.theme = .dark
        onboarding.refreshCountdown()
        XCTAssertEqual(onboarding.remainingSeconds, 13)
        XCTAssertFalse(onboarding.acknowledge())
        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertTrue(preferences.localizer("information_close_countdown", onboarding.remainingSeconds).contains("13"))
        now = origin.advanced(by: .seconds(30))
        onboarding.refreshCountdown()
        XCTAssertTrue(onboarding.canAcknowledge)
        XCTAssertFalse(onboarding.isCompleted)
    }
}

@MainActor
private final class PreferencesOnboardingStore: OnboardingCompletionStoring {
    private(set) var hasCompletedOnboarding = false
    func markOnboardingCompleted() { hasCompletedOnboarding = true }
}
