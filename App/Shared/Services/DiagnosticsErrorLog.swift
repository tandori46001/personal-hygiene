import Foundation

/// Round-25 slice T8.54: ring buffer of recent caught errors. View models
/// + services call `record(_:)` when they catch an error rendered in UI;
/// `DiagnosticsView` displays the last 3 lines for forensic debugging.
@MainActor
public final class DiagnosticsErrorLog {

    public static let shared = DiagnosticsErrorLog()

    private var entries: [Entry] = []
    private let capacity = 20

    private init() {}

    public struct Entry: Equatable, Sendable {
        public let timestamp: Date
        public let message: String
    }

    public func record(_ message: String, at timestamp: Date = Date()) {
        entries.append(Entry(timestamp: timestamp, message: message))
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    public func recent(limit: Int = 3) -> [String] {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        return entries.suffix(limit).reversed().map { entry in
            "\(formatter.string(from: entry.timestamp)) — \(entry.message)"
        }
    }

    public func clear() {
        entries.removeAll()
    }
}
