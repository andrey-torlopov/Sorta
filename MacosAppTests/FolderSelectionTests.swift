import XCTest
@testable import MacosApp

/// Explicitly releases validations in the opposite order; no sleeps or filesystem races.
private actor ControlledFolderAccess: FolderAccessChecking {
    nonisolated let requests: AsyncStream<URL>
    private let signal: AsyncStream<URL>.Continuation
    private var pending: [URL: CheckedContinuation<Bool, Never>] = [:]
    private(set) var requestedURLs: [URL] = []

    init() {
        let pair = AsyncStream<URL>.makeStream()
        requests = pair.stream
        signal = pair.continuation
    }

    func isReadableDirectory(_ url: URL) async -> Bool { await wait(for: url) }
    func validateWritable(_ url: URL) async -> Bool { await wait(for: url) }

    private func wait(for url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            pending[url] = continuation
            requestedURLs.append(url)
            signal.yield(url)
        }
    }

    func complete(_ url: URL, result: Bool) {
        pending.removeValue(forKey: url)?.resume(returning: result)
    }
}

@MainActor
final class FolderSelectionTests: XCTestCase {
    func testLatestSourceSelectionWinsAndResetInvalidatesPendingValidation() async {
        let access = ControlledFolderAccess()
        let coordinator = AppCoordinator(folderAccess: access)
        var iterator = access.requests.makeAsyncIterator()
        let first = URL(fileURLWithPath: "/first-source")
        let second = URL(fileURLWithPath: "/second-source")
        let firstTask = Task { await coordinator.selectSource(first) }
        _ = await iterator.next()
        XCTAssertTrue(coordinator.isSelectingSource)
        XCTAssertNil(coordinator.sourceURL)
        coordinator.open(.sortPhotos)
        XCTAssertTrue(coordinator.path.isEmpty)
        let secondTask = Task { await coordinator.selectSource(second) }
        _ = await iterator.next()
        await access.complete(second, result: true)
        await secondTask.value
        XCTAssertEqual(coordinator.sourceURL, second)
        await access.complete(first, result: false)
        await firstTask.value
        XCTAssertEqual(coordinator.sourceURL, second, "Late validation must not replace the selected source")
        XCTAssertNil(coordinator.sourceError, "A rejected stale source must not report an error for the current one")
        XCTAssertFalse(coordinator.isSelectingSource)

        let resetTask = Task { await coordinator.selectSource(first) }
        _ = await iterator.next()
        coordinator.resetToWelcome()
        await access.complete(first, result: true)
        await resetTask.value
        XCTAssertNil(coordinator.sourceURL)
        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertFalse(coordinator.isSelectingSource)
    }

    func testWritableSelectionsRejectLateValidationForEveryOperation() async {
        let sortAccess = ControlledFolderAccess()
        let sort = SortPhotosViewModel(folderAccess: sortAccess)
        sort.selectSource(URL(fileURLWithPath: "/source"))
        await assertLatestSelection(access: sortAccess, select: sort.selectTarget,
                                    current: { sort.targetFolderURL }, checking: { sort.isSelectingTarget },
                                    ready: { sort.isFolderSelected })
        XCTAssertTrue(sort.logs.isEmpty)

        let conversionAccess = ControlledFolderAccess()
        let conversion = ConvertDNGtoHeicContentViewModel(folderAccess: conversionAccess)
        await assertLatestSelection(access: conversionAccess, select: conversion.selectFolder,
                                    current: { conversion.folderURL }, checking: { conversion.isSelectingFolder },
                                    ready: { conversion.isFolderSelected })
        XCTAssertTrue(conversion.logs.isEmpty)

        let dateAccess = ControlledFolderAccess()
        let dates = FixDateViewModel(folderAccess: dateAccess)
        await assertLatestSelection(access: dateAccess, select: dates.selectFolder,
                                    current: { dates.folderURL }, checking: { dates.isSelectingFolder },
                                    ready: { dates.isFolderSelected })
        XCTAssertTrue(dates.logs.isEmpty)
    }

    func testCancellingDuringPreflightNeverStartsCoreProcessing() async {
        let access = ControlledFolderAccess()
        let model = SortPhotosViewModel(folderAccess: access)
        let source = URL(fileURLWithPath: "/unprocessed-source")
        model.sourceFolderURL = source
        model.targetFolderURL = URL(fileURLWithPath: "/unprocessed-target")
        var iterator = access.requests.makeAsyncIterator()
        let operation = Task { await model.work() }
        _ = await iterator.next()
        XCTAssertTrue(model.inProgress)
        await model.cancel()
        XCTAssertEqual(model.session.status, .cancelling)
        await access.complete(source, result: true)
        await operation.value
        XCTAssertEqual(model.session.status, .cancelled)
        XCTAssertFalse(model.inProgress)
        let requests = await access.requestedURLs
        XCTAssertEqual(requests, [source], "Cancellation must stop before target probing and Core execution")
    }

    private func assertLatestSelection(
        access: ControlledFolderAccess,
        select: @escaping @MainActor (URL) async -> Void,
        current: @MainActor () -> URL?,
        checking: @MainActor () -> Bool,
        ready: @MainActor () -> Bool
    ) async {
        var iterator = access.requests.makeAsyncIterator()
        let first = URL(fileURLWithPath: "/first-target")
        let second = URL(fileURLWithPath: "/second-target")
        let firstTask = Task { await select(first) }
        _ = await iterator.next()
        XCTAssertTrue(checking())
        XCTAssertNil(current())
        XCTAssertFalse(ready(), "Start must remain unavailable while access is being checked")
        let secondTask = Task { await select(second) }
        _ = await iterator.next()
        await access.complete(second, result: true)
        await secondTask.value
        XCTAssertEqual(current(), second)
        XCTAssertTrue(ready())
        await access.complete(first, result: false)
        await firstTask.value
        XCTAssertEqual(current(), second)
        XCTAssertFalse(checking())
        XCTAssertTrue(ready())
    }
}
