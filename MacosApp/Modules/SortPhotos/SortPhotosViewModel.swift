import SwiftUI
import PhotoSorterCore

@MainActor
@Observable
final class SortPhotosViewModel {
    var logs: [OperationLogEntry] = []
    var sourceFolderURL: URL?
    var targetFolderURL: URL?
    var isRenameFileWithDateFormat = true
    var isFixMetadata = true
    var isCreateFolderStruct = true
    var isSetCustomDate = false
    var selectedDate = Date()
    var isRemoveOriginalFile = false
    let session = PhotoOperationSession()

    var inProgress: Bool { session.status.isActive }
    func sourceFolderPath(using localizer: AppLocalizer) -> String { sourceFolderURL?.path ?? localizer("empty_folder") }
    func targetFolderPath(using localizer: AppLocalizer) -> String { isSelectingTarget ? localizer("folder_checking_access") : targetFolderURL?.path ?? localizer("empty_folder") }
    var isFolderSelected: Bool { !isSelectingTarget && sourceFolderURL != nil && targetFolderURL != nil }
    private let logger = LoggerViewModel()
    private let folderAccess: any FolderAccessChecking
    private var targetSelectionID: UUID?
    private(set) var isSelectingTarget = false

    init(folderAccess: any FolderAccessChecking = FolderAccess()) {
        self.folderAccess = folderAccess
    }

    private enum Event: Sendable {
        case progress(SorterProgress)
        case failure(FileProcessingError)
    }

    func log(_ message: LocalizedMessage) { logs = logger.log(message) }

    func selectSource(_ url: URL) {
        guard !inProgress else { return }
        sourceFolderURL = url
    }

    func selectTarget(_ url: URL) async {
        guard !inProgress else { return }
        let selectionID = UUID()
        targetSelectionID = selectionID
        isSelectingTarget = true
        targetFolderURL = nil
        defer {
            if targetSelectionID == selectionID { isSelectingTarget = false }
        }
        let writable = await folderAccess.validateWritable(url)
        guard targetSelectionID == selectionID, !inProgress else { return }
        guard writable else {
            log(LocalizedMessage(key: "target_folder_not_writable"))
            return
        }
        targetFolderURL = url
    }

    func work() async {
        guard !isSelectingTarget else { return }
        let source = sourceFolderURL
        let target = targetFolderURL
        let removeOriginal = isRemoveOriginalFile
        let customDate = isSetCustomDate ? selectedDate : nil
        var options: SorterEngine.Options = []
        if isRenameFileWithDateFormat { options.insert(.renameFiles) }
        if isCreateFolderStruct { options.insert(.createFolders) }
        if isFixMetadata { options.insert(.fixMetadata) }
        let selectedOptions = options

        guard session.start({ [weak self] id in
            guard let self else { return .failed }
            guard let source, let target else {
                self.log(LocalizedMessage(key: "sorter_event_empty_folder"))
                return .failed
            }
            let readable = await self.folderAccess.isReadableDirectory(source)
            guard !Task.isCancelled else { return .cancelled }
            guard readable else {
                self.log(LocalizedMessage(key: "operation_check_file_access"))
                return .failed
            }
            let targetWritable = await self.folderAccess.validateWritable(target)
            guard !Task.isCancelled else { return .cancelled }
            guard targetWritable else {
                self.log(LocalizedMessage(key: "target_folder_not_writable"))
                return .failed
            }
            if removeOriginal {
                let sourceWritable = await self.folderAccess.validateWritable(source)
                guard !Task.isCancelled else { return .cancelled }
                guard sourceWritable else {
                    self.log(LocalizedMessage(key: "source_folder_not_writable"))
                    return .failed
                }
            }
            let sourceScoped = source.startAccessingSecurityScopedResource()
            let targetScoped = target.startAccessingSecurityScopedResource()
            defer {
                if sourceScoped { source.stopAccessingSecurityScopedResource() }
                if targetScoped { target.stopAccessingSecurityScopedResource() }
            }
            let configuration = SorterEngine.Configure.builder(input: source, output: target)
                .options(selectedOptions)
                .disposition(removeOriginal ? .move : .keepOriginal)
                .concreteDate(customDate)
                .build()
            let (events, continuation) = AsyncStream<Event>.makeStream()
            let consumer = Task { @MainActor in
                var hadErrors = false
                for await event in events {
                    guard self.session.acceptsEvents(for: id) else { continue }
                    switch event {
                    case .progress(let progress): await self.handle(progress)
                    case .failure(let error):
                        hadErrors = true
                        await self.handle(error)
                    }
                }
                return hadErrors
            }
            let progressHandler: @Sendable (SorterProgress) -> Void = { continuation.yield(.progress($0)) }
            let errorHandler: @Sendable (FileProcessingError) -> Void = { continuation.yield(.failure($0)) }
            do {
                try Task.checkCancellation()
                let result = try await SorterEngine(configure: configuration).run(
                    progressHandler: progressHandler,
                    errorHandler: errorHandler
                )
                continuation.finish()
                let hadErrors = await consumer.value
                if Task.isCancelled { return .cancelled }
                if hadErrors { return .failed }
                self.log(LocalizedMessage(key: "sort_photos_success", arguments: [.integer(Int64(result.processedCount))]))
                return .succeeded
            } catch {
                continuation.finish()
                _ = await consumer.value
                if Task.isCancelled || error is CancellationError {
                    self.log(LocalizedMessage(key: "sort_photos_taskCancelled"))
                    return .cancelled
                }
                if let error = error as? SorterError { self.log(self.map(error)) }
                else { self.log(LocalizedMessage(key: "operation_failed")) }
                return .failed
            }
        }) else { return }
        await session.waitForCompletion()
    }

    func cancel() async { session.cancel() }

    // MARK: - Маппинг событий Core в лог

    private func handle(_ progress: SorterProgress) async {
        switch progress {
        case .started:
            log(LocalizedMessage(key: "sort_photos_start"))
        case .folderCreated(let name):
            log(LocalizedMessage(key: "sort_photos_folderCreated", arguments: [.text(name)]))
        case .fileProcessed(let sourcePath, let targetPath):
            log(LocalizedMessage(key: "sort_photos_fileProcessed", arguments: [.text(sourcePath), .text(targetPath)]))
        case .fileSkipped(let path):
            log(LocalizedMessage(key: "sort_photos_fileSkipped", arguments: [.text(path)]))
        case .completed:
            break // Report the final result once, after all callbacks have drained.
        }
    }

    private func handle(_ error: FileProcessingError) async {
        switch error {
        case .invalidDate(let filePath, let dateString):
            log(LocalizedMessage(key: "sort_photos_fileHasInvalidDate", arguments: [.text(filePath), .text(dateString)]))
        case .missingDateComponents(let filePath):
            log(LocalizedMessage(key: "sort_photos_invalidDateComponentInFile", arguments: [.text(filePath)]))
        case .moveFailed(let source, let destination, _):
            log(LocalizedMessage(key: "sort_photos_fileMovedFailed", arguments: [.text(source), .text(destination), .message(LocalizedMessage(key: "operation_check_file_access"))]))
        case .copyFailed(let source, let destination, _):
            log(LocalizedMessage(key: "sort_photos_fileCopyFailed", arguments: [.text(source), .text(destination), .message(LocalizedMessage(key: "operation_check_file_access"))]))
        case .dateUpdateFailed(let fileURL, _):
            log(LocalizedMessage(key: "sort_photos_dateUpdateFailed", arguments: [.text(fileURL.path)]))
        case .cantFixDate(let fileURL, _):
            log(LocalizedMessage(key: "sort_photos_cantFixDateForFile", arguments: [.text(fileURL.path)]))
        case .metadataError(let filePath, _):
            log(LocalizedMessage(key: "sort_photos_catchErrorWithMetadata", arguments: [.text(filePath), .message(LocalizedMessage(key: "operation_check_file_access"))]))
        case .creationDateSetFailed(let filePath, _):
            log(LocalizedMessage(key: "sort_photos_errorCantSetCreationDate", arguments: [.text(filePath)]))
        }
    }

    private func map(_ error: SorterError) -> LocalizedMessage {
        switch error {
        case .permissionDenied:
            return LocalizedMessage(key: "sort_photos_notEnoughtPermissionToFolder")
        case .folderNotAccessible(let path):
            return LocalizedMessage(key: "sort_photos_cantOpenFolder", arguments: [.text(path)])
        case .folderCreationFailed(let path):
            return LocalizedMessage(key: "sort_photos_cantCreateFolder", arguments: [.text(path)])
        case .cancelled:
            return LocalizedMessage(key: "sort_photos_taskCancelled")
        }
    }
}
