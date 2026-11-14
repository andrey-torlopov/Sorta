import Foundation

/// Действие приложения. Ровно 3 кейса = три рабочих модуля (функционал не меняем).
/// `enum` уместен: есть перечисление и `switch`-роутинг по действиям.
enum PhotoAction: String, CaseIterable, Identifiable, Hashable {
    case sortPhotos        // ДВЕ папки: source + target
    case convertDngToHeic  // ОДНА папка: in-place
    case fixDates          // ОДНА папка: in-place

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .sortPhotos:       return "action_sort_title"
        case .convertDngToHeic: return "action_convert_title"
        case .fixDates:         return "action_fixdate_title"
        }
    }

    var subtitleKey: String {
        switch self {
        case .sortPhotos:       return "action_sort_subtitle"
        case .convertDngToHeic: return "action_convert_subtitle"
        case .fixDates:         return "action_fixdate_subtitle"
        }
    }

    var icon: String {
        switch self {
        case .sortPhotos:       return "folder.badge.gearshape"
        case .convertDngToHeic: return "photo.on.rectangle.angled"
        case .fixDates:         return "calendar.badge.clock"
        }
    }

    /// Заголовок экрана конфигурации/процесса для этого действия.
    var screenTitleKey: String {
        switch self {
        case .sortPhotos:       return "sortPhotos_title"
        case .convertDngToHeic: return "convert_dng_to_heic_title"
        case .fixDates:         return "fix_date_tool_title"
        }
    }

    /// Сортировке нужна вторая папка (target), остальным - нет.
    var requiresTargetFolder: Bool { self == .sortPhotos }
}
