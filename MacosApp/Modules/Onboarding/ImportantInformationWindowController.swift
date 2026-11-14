import AppKit
import SwiftUI

/// One window per application, shared by mandatory first run and later Help requests.
@MainActor
final class ImportantInformationWindowController: NSObject, NSWindowDelegate {
    private let preferences: AppPreferences
    private let state: OnboardingState
    private var informationWindow: InformationPanel?
    private var countdownTimer: Timer?

    init(state: OnboardingState, preferences: AppPreferences) {
        self.state = state
        self.preferences = preferences
    }

    func show() {
        let window: InformationPanel
        if let existing = informationWindow {
            window = existing
        } else {
            window = InformationPanel(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 570),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.canDismiss = { [state] in state.isCompleted }
            window.identifier = NSUserInterfaceItemIdentifier("important-information-window")
            window.title = preferences.localizer("important_information_title")
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.isFloatingPanel = true
            window.level = .floating
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window.contentMinSize = NSSize(width: 520, height: 480)
            window.delegate = self
            window.contentView = NSHostingView(rootView: PreferencesRoot(preferences: preferences, titleKey: "important_information_title") { [state, weak self] in
                ImportantInformationView(state: state) { [weak self] in
                    self?.acknowledgeAndClose()
                }
            })
            informationWindow = window
        }

        if !window.isVisible { window.center() }
        window.standardWindowButton(.closeButton)?.isEnabled = state.isCompleted
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        state.didPresent()
        startCountdownIfNeeded()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Mandatory mode only accepts the explicit, enabled acknowledgement button.
        state.isCompleted
    }

    func windowWillClose(_ notification: Notification) {
        stopCountdown()
    }

    private func acknowledgeAndClose() {
        guard state.acknowledge() else { return }
        stopCountdown()
        informationWindow?.standardWindowButton(.closeButton)?.isEnabled = true
        informationWindow?.close()
    }

    private func startCountdownIfNeeded() {
        guard !state.isCompleted, !state.canAcknowledge, countdownTimer == nil else { return }
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.state.refreshCountdown()
                if self.state.canAcknowledge { self.stopCountdown() }
            }
        }
        countdownTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

/// Explicitly intercept Escape and Cmd+W in addition to the title-bar/delegate guard.
@MainActor
private final class InformationPanel: NSPanel {
    var canDismiss: () -> Bool = { false }

    override func cancelOperation(_ sender: Any?) {
        guard canDismiss() else { return }
        performClose(sender)
    }

    override func performClose(_ sender: Any?) {
        guard canDismiss() else { return }
        super.performClose(sender)
    }
}
