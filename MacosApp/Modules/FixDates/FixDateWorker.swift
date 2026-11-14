import Foundation
import PhotoSorterCore

/// The synchronous Core API runs on this actor's executor, never on the UI actor.
/// Core objects stay within the executor; only Sendable request values cross it.
actor FixDateWorker {
    func run(folderURL: URL, customDate: Date?, onError: @escaping @Sendable (FixDateError) -> Void) throws {
        try Task.checkCancellation()
        let scoped = folderURL.startAccessingSecurityScopedResource()
        defer { if scoped { folderURL.stopAccessingSecurityScopedResource() } }
        let tool = FixDateTool()
        if let customDate {
            try tool.forceSetDate(with: customDate, forFolder: folderURL, errorHandler: onError)
        } else {
            try tool.fixDatesIn(folderURL: folderURL, errorHandler: onError)
        }
        try Task.checkCancellation()
    }
}
