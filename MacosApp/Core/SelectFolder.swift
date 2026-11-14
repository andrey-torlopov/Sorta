import AppKit

@MainActor
enum SelectFolder {
    static func selectFolder(initialURL: URL? = nil, confirmAccess: Bool = false,
                             title: String, localizer: AppLocalizer) async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = initialURL
        panel.title = title
        panel.prompt = localizer("folder_button")
        if confirmAccess { panel.message = localizer("folder_confirm_access") }
        let response = await withCheckedContinuation { continuation in
            panel.begin { response in continuation.resume(returning: response) }
        }
        guard response == .OK else { return nil }
        return panel.url
    }
}
