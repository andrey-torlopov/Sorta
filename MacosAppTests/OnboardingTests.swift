import XCTest
@testable import MacosApp

@MainActor
final class OnboardingTests: XCTestCase {
    func testCountdownStartsOnlyWhenPresentedAndCannotBeSkipped() {
        let store = MemoryOnboardingStore()
        let origin = ContinuousClock.now
        var uptime = origin
        let state = OnboardingState(store: store, monotonicTime: { uptime })
        uptime = origin.advanced(by: .seconds(400))
        XCTAssertFalse(state.acknowledge(), "Elapsed app lifetime must not count before the window is shown")
        state.didPresent()
        XCTAssertEqual(state.remainingSeconds, 30)

        uptime = origin.advanced(by: .milliseconds(429_999))
        state.refreshCountdown()
        XCTAssertEqual(state.remainingSeconds, 1)
        XCTAssertFalse(state.acknowledge(), "The button must remain blocked immediately before 30 seconds")
        XCTAssertEqual(store.saveCount, 0)

        uptime = origin.advanced(by: .seconds(430))
        state.refreshCountdown()
        XCTAssertTrue(state.canAcknowledge)
        XCTAssertFalse(state.isCompleted, "The timer must not acknowledge on the user's behalf")
        XCTAssertEqual(store.saveCount, 0)
        XCTAssertTrue(state.acknowledge())
        XCTAssertTrue(state.isCompleted)
        XCTAssertEqual(store.saveCount, 1)
    }

    func testRepeatedWindowAndMenuRequestsDoNotResetTheTimer() {
        let store = MemoryOnboardingStore()
        let origin = ContinuousClock.now
        var uptime = origin
        let state = OnboardingState(store: store, monotonicTime: { uptime })
        state.didPresent()
        uptime = origin.advanced(by: .seconds(15))
        state.didPresent()
        state.refreshCountdown()
        XCTAssertEqual(state.remainingSeconds, 15)
        uptime = origin.advanced(by: .seconds(30))
        XCTAssertTrue(state.acknowledge(), "A delayed timer callback must not block a valid acknowledgement")
    }

    func testExitBeforeAcknowledgementRequiresAFullNewCountdown() {
        let store = MemoryOnboardingStore()
        let origin = ContinuousClock.now
        var uptime = origin
        let firstRun = OnboardingState(store: store, monotonicTime: { uptime })
        firstRun.didPresent()
        uptime = origin.advanced(by: .seconds(90))
        firstRun.refreshCountdown()
        XCTAssertTrue(firstRun.canAcknowledge)
        XCTAssertFalse(store.hasCompletedOnboarding)

        let secondRun = OnboardingState(store: store, monotonicTime: { uptime })
        secondRun.didPresent()
        XCTAssertFalse(secondRun.isCompleted)
        XCTAssertEqual(secondRun.remainingSeconds, 30)
        XCTAssertFalse(secondRun.acknowledge())
    }

    func testCompletedOnboardingSurvivesNewSessionAndRepeatViewingDoesNotWrite() {
        let store = MemoryOnboardingStore(completed: true)
        let state = OnboardingState(store: store, monotonicTime: { ContinuousClock.now })
        state.didPresent()
        XCTAssertTrue(state.isCompleted)
        XCTAssertEqual(state.remainingSeconds, 0)
        XCTAssertTrue(state.acknowledge())
        XCTAssertEqual(store.saveCount, 0)
    }

    func testUserDefaultsAdapterPersistsOnlyExplicitAcknowledgement() throws {
        let suite = "SortaOnboardingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsOnboardingStore(defaults: defaults)
        XCTAssertFalse(store.hasCompletedOnboarding)
        store.markOnboardingCompleted()
        let restoredStore = UserDefaultsOnboardingStore(defaults: defaults)
        XCTAssertTrue(restoredStore.hasCompletedOnboarding)
    }
}

@MainActor
private final class MemoryOnboardingStore: OnboardingCompletionStoring {
    private(set) var hasCompletedOnboarding: Bool
    private(set) var saveCount = 0

    init(completed: Bool = false) { hasCompletedOnboarding = completed }

    func markOnboardingCompleted() {
        hasCompletedOnboarding = true
        saveCount += 1
    }
}
