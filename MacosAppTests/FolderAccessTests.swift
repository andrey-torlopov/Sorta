import XCTest
@testable import MacosApp

final class FolderAccessTests: XCTestCase {
    func testDirectoryValidationPreservesExistingFilesAndCleansUpProbe() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let original = folder.appendingPathComponent("original.txt")
        let data = Data("Do not change this file".utf8)
        try data.write(to: original)
        let access = FolderAccess()
        let readable = await access.isReadableDirectory(folder)
        let writable = await access.validateWritable(folder)
        let fileIsDirectory = await access.isReadableDirectory(original)
        let fileIsWritableDirectory = await access.validateWritable(original)
        XCTAssertTrue(readable)
        XCTAssertTrue(writable)
        XCTAssertFalse(fileIsDirectory, "A file is not a folder")
        XCTAssertFalse(fileIsWritableDirectory)
        XCTAssertEqual(try Data(contentsOf: original), data)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), ["original.txt"],
                       "Write validation must remove its own probe")
    }
}
