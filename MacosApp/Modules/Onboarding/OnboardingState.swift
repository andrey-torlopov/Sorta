import Foundation
import Observation

@MainActor
protocol OnboardingCompletionStoring {
    var hasCompletedOnboarding: Bool { get }
    func markOnboardingCompleted()
}

@MainActor
final class UserDefaultsOnboardingStore: OnboardingCompletionStoring {
    static let completionKey = "importantInformationAcknowledged"
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var hasCompletedOnboarding: Bool {
        defaults.bool(forKey: Self.completionKey)
    }

    func markOnboardingCompleted() {
        defaults.set(true, forKey: Self.completionKey)
    }
}

/// Owns the first-run acknowledgement. Merely displaying or timing out never persists it.
@MainActor
@Observable
final class OnboardingState {
    private(set) var isCompleted: Bool
    private(set) var remainingSeconds = 30

    @ObservationIgnored private let store: any OnboardingCompletionStoring
    @ObservationIgnored private let monotonicTime: () -> ContinuousClock.Instant
    @ObservationIgnored private var deadline: ContinuousClock.Instant?

    init(store: any OnboardingCompletionStoring,
         monotonicTime: @escaping () -> ContinuousClock.Instant = { ContinuousClock.now }) {
        self.store = store
        self.monotonicTime = monotonicTime
        isCompleted = store.hasCompletedOnboarding
        if isCompleted { remainingSeconds = 0 }
    }

    var canAcknowledge: Bool {
        isCompleted || (deadline != nil && remainingSeconds == 0)
    }

    /// Called after the window is ordered onscreen; repeated menu/window events are idempotent.
    func didPresent() {
        guard !isCompleted, deadline == nil else { return }
        deadline = monotonicTime().advanced(by: .seconds(30))
        refreshCountdown()
    }

    func refreshCountdown() {
        guard !isCompleted, let deadline else { return }
        let remaining = monotonicTime().duration(to: deadline).components
        remainingSeconds = max(0, Int(remaining.seconds) + (remaining.attoseconds > 0 ? 1 : 0))
    }

    @discardableResult
    func acknowledge() -> Bool {
        refreshCountdown()
        guard canAcknowledge else { return false }
        if !isCompleted {
            store.markOnboardingCompleted()
            isCompleted = true
        }
        return true
    }
}
