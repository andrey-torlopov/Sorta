import SwiftUI

/// Семантика строки лога: цвет + иконка.
enum LogSeverity {
    case info, success, warning, error, progress

    var color: Color {
        switch self {
        case .info:     return Colors.info
        case .success:  return Colors.success
        case .warning:  return Colors.warning
        case .error:    return Colors.error
        case .progress: return Colors.textSecondary
        }
    }

    var iconName: String {
        switch self {
        case .info:     return "info.circle.fill"
        case .success:  return "checkmark.circle.fill"
        case .warning:  return "exclamationmark.triangle.fill"
        case .error:    return "xmark.circle.fill"
        case .progress: return "arrow.right.circle.fill"
        }
    }

    /// The canonical English message supplies a stable presentation classification.
    /// This heuristic never influences operation success, cancellation or file handling.
    static func classify(_ line: String) -> LogSeverity {
        let s = line.lowercased()
        if line.contains("✅") || line.contains("🏁")
            || s.contains("success") || s.contains("completed") || s.contains("finished")
            || s.contains("converted and saved") {
            return .success
        }
        if line.contains("⚠️") || s.contains("attention") || s.contains("skipped") || s.contains("warning") {
            return .warning
        }
        if line.contains("✗") || line.contains("❌")
            || s.contains("error") || s.contains("failed") || s.contains("unable")
            || s.contains("cancel") || s.contains("no write access") || s.contains("not writable")
            || s.contains("invalid") || s.contains("not selected") || s.contains("not accessible")
            || s.contains("insufficient") {
            return .error
        }
        if line.contains("ℹ️") || line.contains("🚀") || s.contains("intro") || s.contains("start") {
            return .info
        }
        return .progress
    }
}

/// Строка лога: семантическая иконка + моноширинный текст в цвете severity.
struct LogRowView: View {
    let line: String
    let severity: LogSeverity

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.s) {
            Image(systemName: severity.iconName)
                .font(.system(size: 12))
                .foregroundColor(severity.color)
                .frame(width: 20)
            Text(line)
                .font(DesignSystem.Typography.logMono)
                .foregroundColor(severity.color)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

/// Переиспользуемый список логов (DUP-1). Контейнер - тёмная glass-панель с автоскроллом.
///
/// Ключ ForEach - `\.offset`, а не `\.element`: одинаковые строки лога не должны
/// коллизить по ключу и пропадать из списка (намеренное решение, не менять).
struct LogListView: View {
    @Environment(\.appLocalizer) private var localizer
    let logs: [OperationLogEntry]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                        // Presentation language must not change an event's color or icon.
                        LogRowView(line: log.render(using: localizer), severity: LogSeverity.classify(
                            log.message.render(using: AppLocalizer(language: .en))
                        ))
                            .id(index)
                    }
                }
                .padding(DesignSystem.Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .fill(Colors.base.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                            .stroke(Colors.glassStroke, lineWidth: 1)
                    )
            )
            .onChange(of: logs.count) { _, newCount in
                guard newCount > 0 else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newCount - 1, anchor: .bottom)
                }
            }
        }
    }
}
