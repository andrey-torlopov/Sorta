import Foundation

/// Keep arguments typed and untranslated until presentation, including nested errors.
struct LocalizedMessage: Equatable, Sendable {
    indirect enum Argument: Equatable, Sendable {
        case text(String), integer(Int64), message(LocalizedMessage)
        func value(using localizer: AppLocalizer) -> CVarArg {
            switch self {
            case .text(let text): text
            case .integer(let number): number
            case .message(let message): message.render(using: localizer)
            }
        }
    }
    let key: String
    var arguments: [Argument] = []

    func render(using localizer: AppLocalizer) -> String {
        localizer.string(key, arguments: arguments.map { $0.value(using: localizer) })
    }
}

struct OperationLogEntry: Equatable, Sendable {
    let timestamp: Date
    let message: LocalizedMessage

    func render(using localizer: AppLocalizer) -> String {
        let formatter = DateFormatter()
        formatter.locale = localizer.locale
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return "[\(formatter.string(from: timestamp))] \(message.render(using: localizer))"
    }
}

@MainActor
final class LoggerViewModel {
    private var logs: [OperationLogEntry] = []

    func log(_ message: LocalizedMessage) -> [OperationLogEntry] {
        logs.append(OperationLogEntry(timestamp: Date(), message: message))
        return logs
    }
}
