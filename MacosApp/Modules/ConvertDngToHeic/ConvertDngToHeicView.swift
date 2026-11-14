import SwiftUI
import PhotoSorterCore

/// Конфиг-экран Конвертации DNG -> HEIC. Работает in-place над папкой, выбранной на Welcome.
/// Вторая папка не нужна. `selectFolder` проверяет права на запись; при отказе показываем ошибку.
struct ConvertDNGtoHeicView: View {
    @Environment(\.appLocalizer) private var localizer
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel = ConvertDNGtoHeicContentViewModel()
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
                        GlassToggleRow(
                            title: localizer("remove_original_file"),
                            isOn: $viewModel.isDeleteOriginal
                        )
                    }

                    Button(localizer("convert_button")) {
                        coordinator.startProcess(.convertDngToHeic)
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.isFolderSelected))
                    .disabled(!viewModel.isFolderSelected)
                }
                .padding(DesignSystem.Spacing.screenEdge)
            }
        }
        .navigationTitle(localizer("convert_dng_to_heic_title"))
        .task {
            guard !didSetup else { return }
            didSetup = true
            if let existing = coordinator.convertViewModel {
                viewModel = existing
                return
            }
            coordinator.convertViewModel = viewModel
            viewModel.log(LocalizedMessage(key: "convertion_warning"))
            if let source = coordinator.sourceURL {
                await viewModel.selectFolder(source)
            }
        }
    }
}

/// Инлайновая подсказка об отсутствии прав на запись в выбранную папку.
struct NotWritableHint: View {
    @Environment(\.appLocalizer) private var localizer
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Colors.warning)
            Text(localizer("target_folder_not_writable"))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(Colors.warning)
            Spacer()
        }
        .padding(DesignSystem.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.field)
                .fill(Colors.warning.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.field)
                        .stroke(Colors.warning.opacity(0.4), lineWidth: 1)
                )
        )
    }
}
