import SwiftUI
import PhotoSorterCore

@MainActor
@Observable
final class FixDateViewModel {
    var folderURL: URL?
    var logs: [OperationLogEntry] = []
    var isSetCustomDate = false
    var selectedDate = Date()
    let session = PhotoOperationSession()

    var inProgress: Bool { session.status.isActive }
    func folderPath(using localizer: AppLocalizer) -> String { isSelectingFolder ? localizer("folder_checking_access") : folderURL?.path ?? localizer("empty_folder") }
    var isFolderSelected: Bool { !isSelectingFolder && folderURL != nil }
    private let logger = LoggerViewModel()
    private let folderAccess: any FolderAccessChecking
    private var folderSelectionID: UUID?
    private(set) var isSelectingFolder = false

    init(folderAccess: any FolderAccessChecking = FolderAccess()) {
        self.folderAccess = folderAccess
    }
    private let worker = FixDateWorker()

    func log(_ message: LocalizedMessage) { logs = logger.log(message) }

    func selectFolder(_ url: URL) async {
        guard !inProgress else { return }
        let selectionID = UUID()
        folderSelectionID = selectionID
        isSelectingFolder = true
        folderURL = nil
        defer {
            if folderSelectionID == selectionID { isSelectingFolder = false }
        }
        let writable = await folderAccess.validateWritable(url)
        guard folderSelectionID == selectionID, !inProgress else { return }
        guard writable else {
            log(LocalizedMessage(key: "target_folder_not_writable"))
            return
        }
        folderURL = url
    }

    func runFixDate() async {
        guard !isSelectingFolder else { return }
        let folder = folderURL
        let customDate = isSetCustomDate ? selectedDate : nil
        guard session.start({ [weak self] id in
            guard let self else { return .failed }
            guard let folder else {
                self.log(LocalizedMessage(key: "target_folder_not_writable"))
                return .failed
            }
            let writable = await self.folderAccess.validateWritable(folder)
            guard !Task.isCancelled else { return .cancelled }
            guard writable else {
                self.log(LocalizedMessage(key: "target_folder_not_writable"))
                return .failed
            }
            self.log(LocalizedMessage(key: "fix_date_starting"))
            let (events, continuation) = AsyncStream<FixDateError>.makeStream()
            let consumer = Task { @MainActor in
                var hadErrors = false
                for await error in events {
                    guard self.session.acceptsEvents(for: id) else { continue }
                    hadErrors = true
                    await self.handle(error)
                }
                return hadErrors
            }
            do {
                try await self.worker.run(folderURL: folder, customDate: customDate) {
                    continuation.yield($0)
                }
                continuation.finish()
                let hadErrors = await consumer.value
                if Task.isCancelled { return .cancelled }
                if hadErrors { return .failed }
                self.log(LocalizedMessage(key: "fix_date_done"))
                return .succeeded
            } catch {
                continuation.finish()
                _ = await consumer.value
                if Task.isCancelled || error is CancellationError {
                    self.log(LocalizedMessage(key: "task_cancelled"))
                    return .cancelled
                }
                if let error = error as? FixDateError { await self.handle(error) }
                else { self.log(LocalizedMessage(key: "operation_failed")) }
                return .failed
            }
        }) else { return }
        await session.waitForCompletion()
    }

    func cancel() async { session.cancel() }

    private func handle(_ error: FixDateError) async {
        switch error {
        case .securityScopedResourceAccessFailed:
            log(LocalizedMessage(key: "unable_to_access_security_scoped_resource"))
        case .cancelled:
            log(LocalizedMessage(key: "task_cancelled"))
        case .folderNotAccessible(let path):
            log(LocalizedMessage(key: "cant_open_folder_path_error", arguments: [.text(path.path)]))
        case .dateUpdateFailed(let fileURL, _):
            log(LocalizedMessage(key: "date_update_failed", arguments: [.text(fileURL.path)]))
        case .cantFixDate(let fileURL, _):
            log(LocalizedMessage(key: "cant_fix_date_for_file", arguments: [.text(fileURL.path)]))
        case .metadataError(let filePath, _):
            log(LocalizedMessage(key: "catch_error_with_fix_metadata", arguments: [.text(filePath), .message(LocalizedMessage(key: "operation_check_file_access"))]))
        case .creationDateSetFailed:
            log(LocalizedMessage(key: "cant_set_create_date"))
        }
    }
}
