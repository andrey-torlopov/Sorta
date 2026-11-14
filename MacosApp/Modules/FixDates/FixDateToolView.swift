import SwiftUI

/// Конфиг-экран Исправления дат. In-place над папкой, выбранной на Welcome.
/// `selectFolder` проверяет права на запись; при отказе показываем ошибку.
struct FixDateToolView: View {
    @Environment(\.appLocalizer) private var localizer
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel = FixDateViewModel()
    @State private var didSetup = false

    var body: some View {
        ZStack {
            DesignSystem.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    SourceFolderHeader(path: viewModel.folderPath(using: localizer))

                    if !viewModel.isSelectingFolder && viewModel.folderURL == nil {
                        NotWritableHint()
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                            GlassToggleRow(
                                title: localizer("fix_date_tool_checkbox_text"),
                                isOn: $viewModel.isSetCustomDate
                            )

                            if viewModel.isSetCustomDate {
                                DateSelectionView(selectedDate: $viewModel.selectedDate)
                            }
                        }
                    }

                    Button(localizer("fix_date_button_run")) {
                        coordinator.startProcess(.fixDates)
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.isFolderSelected))
                    .disabled(!viewModel.isFolderSelected)
                }
                .padding(DesignSystem.Spacing.screenEdge)
            }
        }
        .navigationTitle(localizer("fix_date_tool_title"))
        .task {
            guard !didSetup else { return }
            didSetup = true
            if let existing = coordinator.fixDateViewModel {
                viewModel = existing
                return
            }
            coordinator.fixDateViewModel = viewModel
            viewModel.log(LocalizedMessage(key: "fix_date_tool_intro"))
            if let source = coordinator.sourceURL {
                await viewModel.selectFolder(source)
            }
        }
    }
}
