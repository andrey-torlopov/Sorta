import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let preferences: AppPreferences
    private let developerLinks: [AboutExternalLink]
    private var window: NSWindow?

    init(preferences: AppPreferences, developerLinks: [AboutExternalLink]) {
        self.preferences = preferences
        self.developerLinks = developerLinks
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.identifier = NSUserInterfaceItemIdentifier("settings-window")
            window.isReleasedWhenClosed = false
            window.contentMinSize = NSSize(width: 540, height: 520)
            window.title = preferences.localizer("settings_title")
            window.contentView = NSHostingView(rootView: PreferencesRoot(preferences: preferences, titleKey: "settings_title") { [preferences, developerLinks] in
                SettingsContentView(preferences: preferences, developerLinks: developerLinks)
            })
            self.window = window
        }
        guard let window else { return }
        if window.isMiniaturized { window.deminiaturize(nil) }
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
