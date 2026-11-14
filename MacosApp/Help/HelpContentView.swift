import SwiftUI

struct HelpDocument {
    enum LoadError: Error { case missingResource, missingEnglish }

    static func load(in bundle: Bundle = .main, language: String = AppLocalization.language) throws -> [String: String] {
        guard let url = bundle.url(forResource: "help_content", withExtension: "json") else {
            throw LoadError.missingResource
        }
        return try decode(Data(contentsOf: url), language: language)
    }

    static func decode(_ data: Data, language: String) throws -> [String: String] {
        let languages = try JSONDecoder().decode([String: [String: String]].self, from: data)
        guard let english = languages["en"] else { throw LoadError.missingEnglish }
        return english.merging(languages[language] ?? [:]) { _, localized in localized }
    }
}

struct HelpContentView: View {
    @Environment(\.appLocalizer) private var localizer
    let onClose: () -> Void
    @State private var helpContent: [String: String] = [:]
    @State private var loadingFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizer("help_title"))
                .font(.largeTitle)
                .bold()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    if loadingFailed {
                        Text(localizer("help_content_unavailable"))
                            .foregroundStyle(.secondary)
                        Button(localizer("retry_button"), action: loadHelpText)
                    } else {
                        helpSection(titleKey: "important_section", contentKey: "important_text")
                        helpSection(titleKey: "preface_section", contentKey: "preface_text")
                        helpSection(titleKey: "problems_section", contentKey: "problems_text")
                        helpSection(titleKey: "metadata_section", contentKey: "metadata_text")
                        helpSection(titleKey: "how_to_use_section", contentKey: "how_to_use_text")
                        helpSection(titleKey: "converter_section", contentKey: "converter_text")
                        helpSection(titleKey: "sorting_section", contentKey: "sorting_text")
                        helpSection(titleKey: "qa_section", contentKey: "qa_text")
                    }
                }
                .padding()
            }
            .frame(minHeight: 300)
            Button(localizer("close_button"), action: onClose)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.cancelAction)
                .padding(.top, 10)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onChange(of: localizer.language, initial: true) { _, _ in loadHelpText() }
    }

    private func loadHelpText() {
        do {
            helpContent = try HelpDocument.load(language: localizer.language.rawValue)
            loadingFailed = false
        } catch {
            helpContent = [:]
            loadingFailed = true
        }
    }

    private func helpSection(titleKey: String, contentKey: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(localizer(titleKey))
                .font(.title2)
                .bold()
                .foregroundStyle(.blue)
            Text(helpContent[contentKey] ?? localizer("help_content_unavailable"))
                .font(.body)
                .textSelection(.enabled)
        }
    }
}
