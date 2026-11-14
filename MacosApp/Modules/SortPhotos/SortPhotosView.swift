//
//  SortPhotosView.swift
//  MacosApp
//
//  Created by Andrey Torlopov on 15.02.2025.
//

import SwiftUI

/// Конфиг-экран Сортировки. Source приходит с Welcome; здесь добавляется ВТОРАЯ папка (target)
/// и настраиваются опции. Запуск уводит на экран процесса, который работает поверх ЭТОЙ ЖЕ VM.
/// Экземпляр VM принадлежит координатору и переиспользуется всеми окнами.
struct SortPhotosView: View {
    @Environment(\.appLocalizer) private var localizer
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel = SortPhotosViewModel()
    @State private var didSetup = false

    var body: some View {
        ZStack {
            DesignSystem.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    SourceFolderHeader(path: viewModel.sourceFolderPath(using: localizer))

                    GlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                            FolderDropZone(
                                title: localizer("target_folder_button"),
                                pathText: viewModel.targetFolderPath(using: localizer)
                            ) { url in
                                Task { await viewModel.selectTarget(url) }
                            }

                            Divider().overlay(Colors.separator)

                            GlassToggleRow(
                                title: localizer("sort_photos_rename_files_to_date_format"),
                                isOn: $viewModel.isRenameFileWithDateFormat
                            )
                            GlassToggleRow(
                                title: localizer("sort_photos_fix_metadata"),
                                isOn: $viewModel.isFixMetadata
                            )
                            GlassToggleRow(
                                title: localizer("sort_photos_create_folder_structure"),
                                isOn: $viewModel.isCreateFolderStruct
                            )
                            GlassToggleRow(
                                title: localizer("remove_original_file"),
                                isOn: $viewModel.isRemoveOriginalFile
                            )

                            if !viewModel.isFixMetadata {
                                GlassToggleRow(
                                    title: localizer("sort_photos_set_custom_date"),
                                    isOn: $viewModel.isSetCustomDate
                                )
                            }

                            if viewModel.isSetCustomDate {
                                DateSelectionView(selectedDate: $viewModel.selectedDate)
                            }
                        }
                    }

                    Button(localizer("sort_photo_button_run")) {
                        coordinator.startProcess(.sortPhotos)
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.isFolderSelected))
                    .disabled(!viewModel.isFolderSelected)
                }
                .padding(DesignSystem.Spacing.screenEdge)
            }
        }
        .navigationTitle(localizer("sortPhotos_title"))
        .task {
            guard !didSetup else { return }
            didSetup = true
            if let existing = coordinator.sortViewModel {
                viewModel = existing
                return
            }
            if let source = coordinator.sourceURL {
                viewModel.selectSource(source)
            }
            coordinator.sortViewModel = viewModel
            viewModel.log(LocalizedMessage(key: "sort_photos_intro"))
        }
    }
}

/// Шапка с путём исходной (source) папки. Общий элемент конфиг-экранов.
struct SourceFolderHeader: View {
    @Environment(\.appLocalizer) private var localizer
    let path: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(localizer("action_select_source_caption"))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(Colors.textTertiary)
            Text(path)
                .font(DesignSystem.Typography.bodyEmphasis)
                .foregroundColor(Colors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
