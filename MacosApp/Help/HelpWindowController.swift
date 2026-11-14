import AppKit
import SwiftUI

@MainActor
final class HelpWindowController {
    private let preferences: AppPreferences
    private var window: NSWindow?

    init(preferences: AppPreferences) { self.preferences = preferences }

    func showWindow() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 500),
                styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false
            )
            window.isReleasedWhenClosed = false
            window.identifier = NSUserInterfaceItemIdentifier("help-window")
            window.title = preferences.localizer("help_title")
            window.contentView = NSHostingView(rootView: PreferencesRoot(preferences: preferences, titleKey: "help_title") { [weak self] in
                HelpContentView { self?.window?.close() }
            })
            self.window = window
        }
        guard let window else { return }
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
