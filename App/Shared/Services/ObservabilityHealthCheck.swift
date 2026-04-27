import Foundation

/// Round-12 slice 21: aggregates the various observability signals into a
/// single traffic-light enum the DiagnosticsView can show as a badge at the
/// top of the screen. Pure value type — fed inputs by the caller so tests can
/// drive every branch.
public enum ObservabilityHealthCheck {

    public enum Status: String, Sendable, Equatable {
        case green
        case yellow
        case red
    }

    /// Inputs:
    /// - `pendingDelta`: pending - expected from `PendingNotificationsByCategory`
    /// - `widgetReloads`: count from `WidgetReloadCounter`
    /// - `observerAvailable`: `MedicationObserverService.isAvailable`
    /// - `authStatusOK`: notification authorization is `.authorized` or `.provisional`
    /// - `paused`: round-13 — `true` while `PauseNotificationsStore.isPaused()`.
    ///             We surface yellow rather than red because the user
    ///             explicitly opted in. Defaults `false` for back-compat.
    public static func status(
        routinePendingDelta: Int,
        widgetReloads: Int,
        observerAvailable: Bool,
        authStatusOK: Bool,
        paused: Bool = false
    ) -> Status {
        if !authStatusOK || abs(routinePendingDelta) > 5 {
            return .red
        }
        if paused {
            return .yellow
        }
        if abs(routinePendingDelta) > 0 || (widgetReloads == 0 && observerAvailable) {
            return .yellow
        }
        return .green
    }
}
