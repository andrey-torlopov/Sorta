import SwiftUI
import PhotoSorterCore

@MainActor
@Observable
final class ConvertDNGtoHeicContentViewModel {
    var folderURL: URL?
    var isDeleteOriginal = false
    var logs: [OperationLogEntry] = []
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

    func runConvert() async {
        guard !isSelectingFolder else { return }
        let folder = folderURL
        let deleteOriginal = isDeleteOriginal
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
            let scoped = folder.startAccessingSecurityScopedResource()
            defer { if scoped { folder.stopAccessingSecurityScopedResource() } }
            self.log(LocalizedMessage(key: "converting_started"))
            let (events, continuation) = AsyncStream<ConversionState>.makeStream()
            let consumer = Task { @MainActor in
                var hadErrors = false
                for await state in events {
                    guard self.session.acceptsEvents(for: id) else { continue }
                    if await self.handle(state) { hadErrors = true }
                }
                return hadErrors
            }
            let handler: @Sendable (ConversionState) -> Void = { continuation.yield($0) }
            if !Task.isCancelled {
                await UnifiedConvertManager().convertToHEIC(
                    from: .dng,
                    folderURL: folder,
                    deleteOriginalFile: deleteOriginal,
                    stateHandler: handler
                )
            }
            continuation.finish()
            let hadErrors = await consumer.value
            if Task.isCancelled { return .cancelled }
            if hadErrors { return .failed }
            self.log(LocalizedMessage(key: "convert_finished", arguments: [.text(folder.path)]))
            return .succeeded
        }) else { return }
        await session.waitForCompletion()
    }

    func cancel() async { session.cancel() }

    /// Returns whether the event represents a failure, so partial failures never show “Done”.
    private func handle(_ state: ConversionState) async -> Bool {
        switch state {
        case .successConvertedAndSaved:
            log(LocalizedMessage(key: "file_converted_and_saved"))
        case .fileFoundStartConverting(let fileName):
            log(LocalizedMessage(key: "file_found_and_started_converting_name", arguments: [.text(fileName)]))
        case .originalFileDeleted:
            log(LocalizedMessage(key: "original_file_deleted"))
        case .taskCancelled:
            log(LocalizedMessage(key: "task_cancelled"))
        case .unableToAccessSecurityScopedResource:
            log(LocalizedMessage(key: "unable_to_access_security_scoped_resource"))
            return true
        case .cantOpenFolderPath:
            log(LocalizedMessage(key: "cant_open_folder_path"))
            return true
        case .errorWhenDeletingOriginalFile:
            log(LocalizedMessage(key: "error_when_deleting_original_file"))
            return true
        case .errorReadingFile:
            log(LocalizedMessage(key: "error_reading_file"))
            return true
        case .errorCreatingCGImage:
            log(LocalizedMessage(key: "error_creating_cgimage"))
            return true
        case .errorCreatingCGImageDestination:
            log(LocalizedMessage(key: "error_creating_cgimage_destination"))
            return true
        case .errorSavingHEICFile:
            log(LocalizedMessage(key: "error_saving_heic_file"))
            return true
        }
        return false
    }
}
