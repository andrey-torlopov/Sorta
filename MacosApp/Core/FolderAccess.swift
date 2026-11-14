import Foundation
import Darwin

protocol FolderAccessChecking: Sendable {
    func isReadableDirectory(_ url: URL) async -> Bool
    func validateWritable(_ url: URL) async -> Bool
}

/// Blocking filesystem calls stay on this actor's executor, outside MainActor.
actor FolderAccess: FolderAccessChecking {
    /// Opening the directory checks access without enumerating any of its files.
    func isReadableDirectory(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return url.withUnsafeFileSystemRepresentation { path in
            guard let path, let directory = opendir(path) else { return false }
            return closedir(directory) == 0
        }
    }

    /// A dropped URL can be used directly only when the system grants access.
    func hasScopedReadAccess(_ url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else { return false }
        defer { url.stopAccessingSecurityScopedResource() }
        return isReadableDirectory(url)
    }

    /// Verify write access with a unique probe and report cleanup failure too.
    func validateWritable(_ url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let probe = url.appendingPathComponent(".sorta-write-probe-\(UUID().uuidString)")
        do {
            guard try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else { return false }
            try Data().write(to: probe, options: .withoutOverwriting)
            try FileManager.default.removeItem(at: probe)
            return true
        } catch {
            return false
        }
    }
}
