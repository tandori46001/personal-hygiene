import Foundation

/// Captures the moment the app process launched so DiagnosticsView can show
/// uptime + last-launch timestamp without depending on `ProcessInfo`'s
/// `systemUptime` (which counts since system boot, not app launch).
public enum ProcessLaunchTimer {
    public static let launchedAt = Date()

    public static func uptimeSeconds(now: Date = Date()) -> TimeInterval {
        now.timeIntervalSince(launchedAt)
    }
}
