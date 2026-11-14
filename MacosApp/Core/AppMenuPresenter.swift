import AppKit

/// Translates app menu headings through public AppKit APIs.
/// Native item titles, validation, selectors, targets and shortcuts remain owned by macOS.
@MainActor
final class AppMenuPresenter: NSObject {
    private let preferences: AppPreferences
    private var refreshQueued = false

    init(preferences: AppPreferences) {
        self.preferences = preferences
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(menuOpened),
                                               name: NSMenu.didBeginTrackingNotification, object: nil)
    }

    @objc private func menuOpened(_ notification: Notification) { refresh() }

    /// SwiftUI can rebuild command menus after a preference change. Update headings again
    /// on the next turn; never observe our own edits or retry native item validation.
    func refreshAfterUpdates() {
        refresh()
        guard !refreshQueued else { return }
        refreshQueued = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshQueued = false
            self.refresh()
        }
    }

    func refresh() {
        guard let menu = NSApp?.mainMenu else { return }
        update(menu, helpMenu: NSApp.helpMenu, windowsMenu: NSApp.windowsMenu)
    }

    func update(_ menu: NSMenu, helpMenu: NSMenu? = nil, windowsMenu: NSMenu? = nil) {
        let localizer = preferences.localizer
        for item in menu.items {
            guard let submenu = item.submenu else { continue }
            let actions = Set(submenu.items.compactMap { $0.action.map(NSStringFromSelector) })
            let key: String?
            if submenu === helpMenu { key = "menu_help" }
            else if submenu === windowsMenu { key = "menu_window" }
            else if !actions.isDisjoint(with: ["performClose:", "close:", "newWindow:"]) { key = "menu_file" }
            else if !actions.isDisjoint(with: ["undo:", "copy:", "paste:"]) { key = "menu_edit" }
            else if !actions.isDisjoint(with: ["toggleTabBar:", "toggleTabOverview:", "toggleFullScreen:"])
                        || ["View", "Вид"].contains(submenu.title) { key = "menu_view" }
            else { key = nil }
            if let key {
                item.title = localizer(key)
                submenu.title = localizer(key)
            }
        }
    }

}
