import AppKit
import SwiftUI

@MainActor
final class AboutWindowController {
    private let configuration: AboutConfiguration
    private let preferences: AppPreferences
    private var window: NSWindow?

    init(configuration: AboutConfiguration, preferences: AppPreferences) {
        self.configuration = configuration
        self.preferences = preferences
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = preferences.localizer("about_window_title")
            window.identifier = NSUserInterfaceItemIdentifier("about-window")
            window.isReleasedWhenClosed = false
            window.contentMinSize = NSSize(width: 480, height: 560)
            window.contentView = NSHostingView(rootView: PreferencesRoot(preferences: preferences, titleKey: "about_window_title") { [configuration] in
                AboutContentView(configuration: configuration)
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
