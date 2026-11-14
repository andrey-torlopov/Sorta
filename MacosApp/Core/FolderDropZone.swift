import SwiftUI

/// Зона выбора папки: кнопка (NSOpenPanel) + frosted-glass область drag&drop.
///
/// Используется для исходной и целевой папок. Выбранный URL отдаётся через `onPick`;
/// вызывающий код отвечает за проверку прав и security-scoped доступ (см. `FolderAccess`).
/// Логика выбора не меняется - стиль переведён на Pro Dark Glass.
@MainActor
struct FolderDropZone: View {
    @Environment(\.appLocalizer) private var localizer
    let title: String
    let pathText: String
    let onPick: (URL) -> Void
    private let folderAccess: FolderAccess

    init(title: String, pathText: String, folderAccess: FolderAccess = FolderAccess(),
         onPick: @escaping (URL) -> Void) {
        self.title = title
        self.pathText = pathText
        self.folderAccess = folderAccess
        self.onPick = onPick
    }

    @State private var isTargeted = false
    @State private var selectionID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack(spacing: DesignSystem.Spacing.m) {
                ActionButtonView(title: title) {
                    await chooseFolder()
                }
                .frame(width: 200)

                if selectionID != nil { ProgressView().controlSize(.small) }
                Text(selectionID == nil ? pathText : localizer("folder_checking_access"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }

            dropArea
        }
        .onDisappear { selectionID = nil }
    }

    private func chooseFolder() async {
        let id = UUID()
        selectionID = id
        defer { if selectionID == id { selectionID = nil } }
        let url = await SelectFolder.selectFolder(title: title, localizer: localizer)
        guard selectionID == id, let url else { return }
        onPick(url)
    }

    private func acceptDrop(_ url: URL) async {
        let id = UUID()
        selectionID = id
        defer { if selectionID == id { selectionID = nil } }
        let hasAccess = await folderAccess.hasScopedReadAccess(url)
        guard selectionID == id else { return }
        if hasAccess {
            onPick(url)
        } else {
            let selected = await SelectFolder.selectFolder(initialURL: url, confirmAccess: true,
                                                            title: title, localizer: localizer)
            guard selectionID == id, let selected else { return }
            onPick(selected)
        }
    }

    private var dropArea: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .fill(isTargeted ? Colors.glassFillTopHover : Colors.glassFillTop)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .strokeBorder(
                        isTargeted ? Colors.accent : Colors.glassStroke,
                        style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [8, 6])
                    )
            )
            .frame(height: 72)
            .overlay {
                HStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 22))
                        .foregroundColor(isTargeted ? Colors.accent : Colors.textSecondary)
                    Text(localizer("drop_folder_hint"))
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(Colors.textSecondary)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .onTapGesture {
                Task { await chooseFolder() }
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first, url.isFileURL else { return false }
                Task { await acceptDrop(url) }
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
            .animation(DesignSystem.interactionAnimation, value: isTargeted)
    }
}
