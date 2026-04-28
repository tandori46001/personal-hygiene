import Foundation

/// Round-25 slice T2.16: lightweight snapshot of "today's completion"
/// (done/total) so non-Today surfaces (TemplateListView, complication
/// providers) can read the latest figure without owning a TodayViewModel.
/// Stored in `UserDefaults` keyed by day-bucket so a stale entry from
/// yesterday is identifiable. TodayView writes on every reload.
public enum TodayCompletionSnapshotStore {

    public static let key = "today.completion.snapshot.v1"

    public struct Snapshot: Codable, Equatable, Sendable {
        public let dayKey: String
        public let done: Int
        public let total: Int

        public init(dayKey: String, done: Int, total: Int) {
            self.dayKey = dayKey
            self.done = done
            self.total = total
        }
    }

    public static func write(_ snapshot: Snapshot, in defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    public static func read(in defaults: UserDefaults = .standard) -> Snapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    public static func readForToday(
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = .standard
    ) -> Snapshot? {
        guard let snap = read(in: defaults) else { return nil }
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        let today = String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        return snap.dayKey == today ? snap : nil
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
