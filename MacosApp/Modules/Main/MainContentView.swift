import SwiftUI

// MARK: - Маршруты

/// Шаг потока Source-first. Welcome - корень NavigationStack и в path НЕ кладётся.
enum AppRoute: Hashable {
    case actionSelection          // сетка карточек действий
    case config(PhotoAction)      // конфигурация конкретного действия
    case process(PhotoAction)     // экран процесса поверх существующей VM
}

// MARK: - Координатор

/// Единый источник состояния потока. Заменяет три разрозненных `@State`-флага старого
/// `MainContentView`. ViewModel модулей живут ЗДЕСЬ (по одному экземпляру на действие),
/// чтобы конфиг-экран и экран процесса делили ОДИН инстанс и не теряли логи/таск.
@MainActor
@Observable
final class AppCoordinator {
    /// Стек после Welcome. Welcome - root, в path не входит.
    private(set) var path: [AppRoute] = []

    /// Source-папка, выбранная через системный picker или подтверждённый drop.
    private(set) var sourceURL: URL?

    var canStartWork: () -> Bool = { true }
    /// Store a key so an already visible failure follows presentation preferences.
    var sourceError: String?
    private(set) var isLaunchingProcess = false
    private(set) var isSelectingSource = false
    private var sourceSelectionID: UUID?
    private let folderAccess: any FolderAccessChecking

    init(folderAccess: any FolderAccessChecking = FolderAccess()) {
        self.folderAccess = folderAccess
    }

    /// Window and termination guards read task ownership, not delayed UI callbacks.
    var isProcessing: Bool {
        isLaunchingProcess || sortViewModel?.inProgress == true
            || convertViewModel?.inProgress == true || fixDateViewModel?.inProgress == true
    }

    /// Общие экземпляры VM (по одному на действие). Создаются на конфиг-экране,
    /// переиспользуются на экране процесса.
    var sortViewModel: SortPhotosViewModel?
    var convertViewModel: ConvertDNGtoHeicContentViewModel?
    var fixDateViewModel: FixDateViewModel?

    func sourcePath(using localizer: AppLocalizer) -> String {
        isSelectingSource ? localizer("folder_checking_access") : sourceURL?.path ?? localizer("empty_folder")
    }

    // MARK: Переходы

    func selectSource(_ url: URL) async {
        guard canStartWork(), !isProcessing else { return }
        let selectionID = UUID()
        sourceSelectionID = selectionID
        isSelectingSource = true
        sourceError = nil
        sourceURL = nil
        sortViewModel = nil
        convertViewModel = nil
        fixDateViewModel = nil
        path.removeAll()
        defer {
            if sourceSelectionID == selectionID { isSelectingSource = false }
        }
        let readable = await folderAccess.isReadableDirectory(url)
        guard sourceSelectionID == selectionID, canStartWork(), !isProcessing else { return }
        guard readable else {
            sourceError = "folder_select_again"
            return
        }
        sourceURL = url
        path = [.actionSelection]
    }

    func open(_ action: PhotoAction) {
        guard canStartWork(), !isProcessing, !isSelectingSource, sourceURL != nil else { return }
        path.append(.config(action))
    }

    func updateNavigationPath(_ newPath: [AppRoute]) {
        guard canStartWork(), !isProcessing, !isSelectingSource else { return }
        path = newPath
    }

    /// A user action launches work once; appearing process views never launch it.
    func startProcess(_ action: PhotoAction) {
        guard canStartWork(), !isProcessing, !isSelectingSource else { return }
        switch action {
        case .sortPhotos: guard sortViewModel?.isFolderSelected == true else { return }
        case .convertDngToHeic: guard convertViewModel?.isFolderSelected == true else { return }
        case .fixDates: guard fixDateViewModel?.isFolderSelected == true else { return }
        }
        isLaunchingProcess = true
        path.append(.process(action))
        Task { @MainActor in
            defer { isLaunchingProcess = false }
            switch action {
            case .sortPhotos: await sortViewModel?.work()
            case .convertDngToHeic: await convertViewModel?.runConvert()
            case .fixDates: await fixDateViewModel?.runFixDate()
            }
        }
    }

    /// Возврат на Welcome из экрана процесса (кнопка «На главный»).
    func resetToWelcome() {
        guard canStartWork(), !isProcessing else { return }
        sourceSelectionID = nil
        isSelectingSource = false
        path.removeAll()
        sourceURL = nil
        sortViewModel = nil
        convertViewModel = nil
        fixDateViewModel = nil
    }
}

// MARK: - Корневой контейнер

struct RootView: View {
    @Environment(\.appLocalizer) private var localizer
    let onOpenSettings: () -> Void
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: Binding(get: { coordinator.path }, set: coordinator.updateNavigationPath)) {
            WelcomeView(onOpenSettings: onOpenSettings)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .actionSelection:
                        ActionSelectionView()

                    case .config(let action):
                        configScreen(for: action)

                    case .process(let action):
                        ProcessView(action: action)
                    }
                }
        }
        .environment(coordinator)
        .alert(localizer("folder_access_failed"), isPresented: Binding(
            get: { coordinator.sourceError != nil },
            set: { if !$0 { coordinator.sourceError = nil } }
        )) {
            Button(localizer("close_button"), role: .cancel) { coordinator.sourceError = nil }
        } message: {
            Text(localizer(coordinator.sourceError ?? "folder_select_again"))
        }
        .background(DesignSystem.screenBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func configScreen(for action: PhotoAction) -> some View {
        switch action {
        case .sortPhotos:
            SortPhotosView()
        case .convertDngToHeic:
            ConvertDNGtoHeicView()
        case .fixDates:
            FixDateToolView()
        }
    }
}
