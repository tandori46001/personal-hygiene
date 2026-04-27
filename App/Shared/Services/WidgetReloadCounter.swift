import Foundation

/// Process-wide counter of how many times the iPhone-side `widgetReloader`
/// closure (passed into `NotificationActionHandler`) has been invoked. Lets
/// `DiagnosticsView` confirm that mark-done flows are actually triggering
/// `WidgetCenter.shared.reloadAllTimelines()`. Cleared on relaunch.
public final class WidgetReloadCounter: @unchecked Sendable {

    public static let shared = WidgetReloadCounter()

    private let lock = NSLock()
    private var _count: Int = 0
    private var _lastFiredAt: Date?

    public init() {}

    public func increment(at timestamp: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        _count += 1
        _lastFiredAt = timestamp
    }

    public var count: Int {
        lock.lock(); defer { lock.unlock() }
        return _count
    }

    public var lastFiredAt: Date? {
        lock.lock(); defer { lock.unlock() }
        return _lastFiredAt
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        _count = 0
        _lastFiredAt = nil
    }
}
