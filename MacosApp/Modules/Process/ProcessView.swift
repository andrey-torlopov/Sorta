import SwiftUI

/// This screen observes the operation already launched by AppCoordinator.
/// A second window or navigation reconstruction must never repeat file processing.
struct ProcessView: View {
    @Environment(\.appLocalizer) private var localizer
    let action: PhotoAction
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        content
            .navigationTitle(localizer("process_title"))
            .navigationBarBackButtonHidden(coordinator.isProcessing)
    }

    @ViewBuilder
    private var content: some View {
        switch action {
        case .sortPhotos:
            if let model = coordinator.sortViewModel {
                processContent(logs: model.logs, status: model.session.status, cancel: { await model.cancel() })
            } else { missingViewModel }
        case .convertDngToHeic:
            if let model = coordinator.convertViewModel {
                processContent(logs: model.logs, status: model.session.status, cancel: { await model.cancel() })
            } else { missingViewModel }
        case .fixDates:
            if let model = coordinator.fixDateViewModel {
                processContent(logs: model.logs, status: model.session.status, cancel: { await model.cancel() })
            } else { missingViewModel }
        }
    }

    private func processContent(logs: [OperationLogEntry], status: PhotoOperationSession.Status,
                                cancel: @escaping () async -> Void) -> some View {
        ProcessContent(logs: logs, status: status, isLaunching: coordinator.isLaunchingProcess,
                       cancel: cancel, onHome: coordinator.resetToWelcome)
    }

    private var missingViewModel: some View {
        Button(localizer("process_return_home")) { coordinator.resetToWelcome() }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(coordinator.isProcessing)
            .padding(DesignSystem.Spacing.screenEdge)
    }
}

private struct ProcessContent: View {
    @Environment(\.appLocalizer) private var localizer
    let logs: [OperationLogEntry]
    let status: PhotoOperationSession.Status
    let isLaunching: Bool
    let cancel: () async -> Void
    let onHome: () -> Void

    private var isActive: Bool { status.isActive || isLaunching }

    var body: some View {
        ZStack {
            DesignSystem.screenBackground.ignoresSafeArea()
            VStack(spacing: DesignSystem.Spacing.xl) {
                GlassCard {
                    HStack(spacing: DesignSystem.Spacing.m) {
                        statusIcon
                        Text(statusText)
                            .font(DesignSystem.Typography.bodyEmphasis)
                            .foregroundColor(Colors.textPrimary)
                        Spacer()
                    }
                }
                LogListView(logs: logs)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                buttons
            }
            .padding(DesignSystem.Spacing.screenEdge)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if isActive {
            ProgressView().progressViewStyle(.circular).controlSize(.small).tint(Colors.accent)
        } else if status == .succeeded {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Colors.success)
        } else {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Colors.warning)
        }
    }

    private var statusText: String {
        if status == .cancelling { return localizer("process_status_cancelling") }
        if isActive { return localizer("process_status_running") }
        switch status {
        case .succeeded: return localizer("process_status_done")
        case .cancelled: return localizer("process_status_cancelled")
        default: return localizer("process_status_failed")
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if isActive {
            Button { Task { await cancel() } } label: {
                Label(status == .cancelling ? localizer("process_status_cancelling") : localizer("button_cancel_title"),
                      systemImage: "stop.fill")
            }
            .buttonStyle(DestructiveButtonStyle())
            .disabled(!status.isActive || status == .cancelling)
        } else {
            Button(action: onHome) {
                Label(localizer("process_return_home"), systemImage: "house.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}
