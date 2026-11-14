import SwiftUI
import AppKit

@main
@MainActor
struct MacosAppApp: App {
    @NSApplicationDelegateAdaptor(SortaAppDelegate.self) private var appDelegate
    @State private var menuPresenter: AppMenuPresenter
    @State private var preferences: AppPreferences
    @State private var helpWindow: HelpWindowController
    @State private var settingsWindow: SettingsWindowController
    @State private var coordinator: AppCoordinator
    @State private var onboarding: OnboardingState
    @State private var informationWindow: ImportantInformationWindowController
    @State private var aboutWindow: AboutWindowController
    @State private var windowGuard = WindowGuard()
    @State private var showCloseBlocked = false

    init() {
        let preferenceStore: any AppPreferencesStoring
        let completionStore: any OnboardingCompletionStoring
        #if DEBUG
        if let mode = ProcessInfo.processInfo.environment["SORTA_UI_TEST_ONBOARDING"],
           mode == "required" || mode == "completed" {
            completionStore = UITestOnboardingStore(completed: mode == "completed")
            if let suite = ProcessInfo.processInfo.environment["SORTA_UI_TEST_PREFERENCES_SUITE"],
               suite.hasPrefix("SortaUITests."), let defaults = UserDefaults(suiteName: suite) {
                preferenceStore = UserDefaultsPreferencesStore(defaults: defaults)
            } else {
                preferenceStore = MemoryPreferencesStore()
            }
        } else {
            completionStore = UserDefaultsOnboardingStore(defaults: .standard)
            preferenceStore = UserDefaultsPreferencesStore(defaults: .standard)
        }
        #else
        completionStore = UserDefaultsOnboardingStore(defaults: .standard)
        preferenceStore = UserDefaultsPreferencesStore(defaults: .standard)
        #endif
        let preferences = AppPreferences(store: preferenceStore) { theme in
            // The app may outlive its main window while Settings remains open.
            NSApp.appearance = theme.appearance
        }
        _preferences = State(initialValue: preferences)
        let menuPresenter = AppMenuPresenter(preferences: preferences)
        preferences.languageDidChange = { [weak menuPresenter] _ in
            menuPresenter?.refreshAfterUpdates()
        }
        _menuPresenter = State(initialValue: menuPresenter)
        _helpWindow = State(initialValue: HelpWindowController(preferences: preferences))
        _settingsWindow = State(initialValue: SettingsWindowController(preferences: preferences, developerLinks: AboutConfiguration.developerLinks))
        let onboarding = OnboardingState(store: completionStore)
        let coordinator = AppCoordinator()
        coordinator.canStartWork = { onboarding.isCompleted }
        _onboarding = State(initialValue: onboarding)
        _coordinator = State(initialValue: coordinator)
        _informationWindow = State(initialValue: ImportantInformationWindowController(state: onboarding, preferences: preferences))
        _aboutWindow = State(initialValue: AboutWindowController(configuration: AboutConfiguration(
            version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            links: AboutConfiguration.developerLinks
        ), preferences: preferences))
    }

    var body: some Scene {
        WindowGroup {
            PreferencesRoot(preferences: preferences) {
                if onboarding.isCompleted {
                    RootView(onOpenSettings: { settingsWindow.show() }, coordinator: coordinator)
                } else {
                    // No file pickers, drop targets, navigation or processing actions exist yet.
                    DesignSystem.screenBackground
                        .overlay {
                            Text("Sorta")
                                .font(DesignSystem.Typography.screenTitle)
                                .foregroundStyle(Colors.textSecondary)
                        }
                        .frame(minWidth: 700, minHeight: 600)
                }
            }
            .background(
                WindowAccessor { window in
                    windowGuard.isProcessing = { coordinator.isProcessing }
                    windowGuard.requiresOnboarding = { !onboarding.isCompleted }
                    windowGuard.onBlockedClose = { showCloseBlocked = true }
                    windowGuard.onShowInformation = { informationWindow.show() }
                    if window.delegate !== windowGuard {
                        window.delegate = windowGuard
                    }
                }
            )
            .onAppear {
                NSApp.appearance = preferences.theme.appearance
                menuPresenter.refreshAfterUpdates()
                appDelegate.isProcessing = { coordinator.isProcessing }
                appDelegate.onBlockedTermination = { showCloseBlocked = true }
                if !onboarding.isCompleted { informationWindow.show() }
            }
            .confirmationDialog(
                preferences.localizer("menu_change_page_dialog_text"),
                isPresented: $showCloseBlocked,
                titleVisibility: .visible
            ) {
                Button(preferences.localizer("menu_change_page_dialog_button_cancel"), role: .cancel) {}
            }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(preferences.localizer("about_menu_title")) {
                    if onboarding.isCompleted {
                        aboutWindow.show()
                    } else {
                        informationWindow.show()
                    }
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button(preferences.localizer("settings_menu_title")) { settingsWindow.show() }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .help) {
                Button(preferences.localizer("help_menu_title")) {
                    if onboarding.isCompleted {
                        helpWindow.showWindow()
                    } else {
                        informationWindow.show()
                    }
                }
                Button(preferences.localizer("important_information_title")) {
                    informationWindow.show()
                }
            }
        }
    }
}

/// Quitting stays available during first run; active file operations must finish/cancel first.
@MainActor
final class SortaAppDelegate: NSObject, NSApplicationDelegate {
    var isProcessing: () -> Bool = { false }
    var onBlockedTermination: () -> Void = {}

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard isProcessing() else { return .terminateNow }
        onBlockedTermination()
        return .terminateCancel
    }
}

@MainActor
final class WindowGuard: NSObject, NSWindowDelegate {
    var isProcessing: () -> Bool = { false }
    var requiresOnboarding: () -> Bool = { false }
    var onBlockedClose: () -> Void = {}
    var onShowInformation: () -> Void = {}

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if requiresOnboarding() {
            onShowInformation()
            return false
        }
        guard isProcessing() else { return true }
        onBlockedClose()
        return false
    }
}

/// Resolves the actual window when AppKit attaches the view, including newly created scenes.
struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> WindowResolvingView {
        WindowResolvingView(onResolve: onResolve)
    }

    func updateNSView(_ nsView: WindowResolvingView, context: Context) {
        nsView.onResolve = onResolve
        if let window = nsView.window { onResolve(window) }
    }
}

@MainActor
final class WindowResolvingView: NSView {
    var onResolve: (NSWindow) -> Void

    init(onResolve: @escaping (NSWindow) -> Void) {
        self.onResolve = onResolve
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window { onResolve(window) }
    }
}

#if DEBUG
/// UI automation never reads or overwrites the user's real acknowledgement preference.
@MainActor
private final class UITestOnboardingStore: OnboardingCompletionStoring {
    private(set) var hasCompletedOnboarding: Bool

    init(completed: Bool) { hasCompletedOnboarding = completed }
    func markOnboardingCompleted() { hasCompletedOnboarding = true }
}
#endif
