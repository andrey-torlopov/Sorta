import Foundation
import Observation

/// Owns the task lifetime shared by configuration, process UI and window guards.
@MainActor
@Observable
final class PhotoOperationSession {
    enum Status: Equatable {
        case idle, running, cancelling, succeeded, failed, cancelled

        var isActive: Bool { self == .running || self == .cancelling }
    }

    enum Outcome {
        case succeeded, failed, cancelled
    }

    private(set) var status: Status = .idle
    private var task: Task<Void, Never>?
    private var operationID: UUID?

    /// Sets busy synchronously, before the task can suspend or another action can run.
    @discardableResult
    func start(_ operation: @escaping @MainActor (UUID) async -> Outcome) -> Bool {
        guard task == nil else { return false }
        let id = UUID()
        operationID = id
        status = .running
        task = Task { [weak self] in
            guard let self else { return }
            let outcome = await operation(id)
            guard self.operationID == id else { return }
            if Task.isCancelled {
                self.status = .cancelled
            } else {
                switch outcome {
                case .succeeded: self.status = .succeeded
                case .failed: self.status = .failed
                case .cancelled: self.status = .cancelled
                }
            }
            self.operationID = nil
            self.task = nil
        }
        return true
    }

    func acceptsEvents(for id: UUID) -> Bool {
        operationID == id && status.isActive
    }

    func cancel() {
        guard let task, status == .running else { return }
        status = .cancelling
        task.cancel()
        // The task alone clears busy, after Core returns and releases its resources.
    }

    func waitForCompletion() async {
        await task?.value
    }
}
