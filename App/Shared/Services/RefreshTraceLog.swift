import Foundation

/// In-memory ring buffer of the last N `NotificationCoordinator.refreshForToday`
/// invocations. Surfaces in `DiagnosticsView` so the on-device user can see
/// what was scheduled and when, without having to attach Xcode to inspect
/// `os_log`. Process-local; cleared on relaunch.
public enum RefreshTraceKind: String, Sendable {
    case refresh
    case reschedule
    /// Round-13 slice 5: the coordinator short-circuited because notifications
    /// are paused. Distinct from `.refresh` so observability code doesn't
    /// confuse a deliberate gap with drift.
    case paused
}

@MainActor
public final class RefreshTraceLog {

    public struct Entry: Equatable, Sendable {
        public let timestamp: Date
        public let scheduledCount: Int
        public let kind: RefreshTraceKind
    }

    public static let shared = RefreshTraceLog()

    /// Capacity 20 strikes the balance between "useful history" and "no
    /// runaway memory in a long-running app". Older entries are dropped
    /// when capacity is reached.
    private let capacity: Int
    private(set) var entries: [Entry] = []

    public init(capacity: Int = 20) {
        self.capacity = capacity
    }

    public func record(scheduledCount: Int, kind: RefreshTraceKind, at timestamp: Date = Date()) {
        entries.append(Entry(timestamp: timestamp, scheduledCount: scheduledCount, kind: kind))
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    public func reset() {
        entries.removeAll()
    }

    /// Newest-first copy for UI rendering.
    public var newestFirst: [Entry] { entries.reversed() }

    /// Round-23 slice T4.24: terse summary of the most-recent N entries
    /// (each formatted `HH:MM:SS · kind · count`). Used by the Today
    /// pull-to-refresh history disclosure.
    public func recentSummary(limit: Int = 5) -> [String] {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return newestFirst.prefix(max(0, limit)).map { entry in
            "\(formatter.string(from: entry.timestamp)) · \(entry.kind.rawValue) · \(entry.scheduledCount)"
        }
    }
}
