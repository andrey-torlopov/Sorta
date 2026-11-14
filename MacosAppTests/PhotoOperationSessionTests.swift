import XCTest
@testable import MacosApp

@MainActor
final class PhotoOperationSessionTests: XCTestCase {
    func testCancellationKeepsBusyUntilTheRealOperationReturns() async {
        let session = PhotoOperationSession()
        let (started, signal) = AsyncStream<UUID>.makeStream()
        var releaseOperation: CheckedContinuation<Void, Never>?
        XCTAssertTrue(session.start { id in
            await withCheckedContinuation { continuation in
                releaseOperation = continuation
                signal.yield(id)
            }
            return .succeeded
        })
        XCTAssertEqual(session.status, .running, "Busy must be set before a second launch can run")
        var iterator = started.makeAsyncIterator()
        guard let id = await iterator.next() else { return XCTFail("Operation did not start") }
        session.cancel()
        XCTAssertEqual(session.status, .cancelling)
        XCTAssertTrue(session.status.isActive, "Cancelling must continue to protect file access and window closure")
        XCTAssertTrue(session.acceptsEvents(for: id), "The current operation may still report its final file")
        XCTAssertFalse(session.start { _ in .succeeded }, "A second operation must not overlap cancellation")
        releaseOperation?.resume()
        await session.waitForCompletion()
        XCTAssertEqual(session.status, .cancelled)
        XCTAssertFalse(session.acceptsEvents(for: id), "Late events must not enter a completed session")
        signal.finish()
    }

    func testOldEventsAreRejectedWhenANewOperationStarts() async {
        let session = PhotoOperationSession()
        var previousID: UUID?
        session.start { id in previousID = id; return .failed }
        await session.waitForCompletion()
        XCTAssertEqual(session.status, .failed, "A partial or complete failure must not be shown as success")
        let (started, signal) = AsyncStream<UUID>.makeStream()
        var releaseOperation: CheckedContinuation<Void, Never>?
        session.start { id in
            await withCheckedContinuation { continuation in
                releaseOperation = continuation
                signal.yield(id)
            }
            return .succeeded
        }
        var iterator = started.makeAsyncIterator()
        guard let currentID = await iterator.next(), let previousID else { return XCTFail("Missing operation identity") }
        XCTAssertNotEqual(previousID, currentID)
        XCTAssertFalse(session.acceptsEvents(for: previousID))
        XCTAssertTrue(session.acceptsEvents(for: currentID))
        releaseOperation?.resume()
        await session.waitForCompletion()
        XCTAssertEqual(session.status, .succeeded)
        signal.finish()
    }

    func testChoosingAnotherSourceDiscardsPreviousConfiguration() async {
        let coordinator = AppCoordinator()
        await coordinator.selectSource(FileManager.default.temporaryDirectory)
        coordinator.sortViewModel = SortPhotosViewModel()
        coordinator.convertViewModel = ConvertDNGtoHeicContentViewModel()
        coordinator.fixDateViewModel = FixDateViewModel()
        await coordinator.selectSource(FileManager.default.temporaryDirectory)
        XCTAssertNil(coordinator.sortViewModel, "The next operation must use the new source")
        XCTAssertNil(coordinator.convertViewModel)
        XCTAssertNil(coordinator.fixDateViewModel)
        XCTAssertEqual(coordinator.path, [.actionSelection])
    }

    func testCoordinatorBlocksUncompletedOnboardingAndActiveOperationNavigation() async {
        let coordinator = AppCoordinator()
        coordinator.canStartWork = { false }
        await coordinator.selectSource(FileManager.default.temporaryDirectory)
        coordinator.open(.sortPhotos)
        coordinator.startProcess(.sortPhotos)
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertNil(coordinator.sourceURL)

        coordinator.canStartWork = { true }
        await coordinator.selectSource(FileManager.default.temporaryDirectory)
        coordinator.open(.sortPhotos)
        let previousPath = coordinator.path
        let model = SortPhotosViewModel()
        coordinator.sortViewModel = model
        let (started, signal) = AsyncStream<Void>.makeStream()
        var releaseOperation: CheckedContinuation<Void, Never>?
        model.session.start { _ in
            await withCheckedContinuation { continuation in
                releaseOperation = continuation
                signal.yield(())
            }
            return .succeeded
        }
        var iterator = started.makeAsyncIterator()
        _ = await iterator.next()
        XCTAssertTrue(coordinator.isProcessing)
        coordinator.resetToWelcome()
        coordinator.updateNavigationPath([])
        coordinator.open(.fixDates)
        XCTAssertEqual(coordinator.path, previousPath)
        XCTAssertTrue(coordinator.sortViewModel === model)
        releaseOperation?.resume()
        await model.session.waitForCompletion()
        XCTAssertFalse(coordinator.isProcessing)
        coordinator.resetToWelcome()
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertNil(coordinator.sortViewModel)
        signal.finish()
    }
}
