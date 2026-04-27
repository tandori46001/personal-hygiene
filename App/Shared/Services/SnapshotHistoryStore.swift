import Foundation

/// Round-13 slice 15: stores the last N `DiagnosticsSnapshot`s locally so the
/// user can compare against earlier snapshots without leaving the app. We
/// serialize each snapshot as JSON bytes (the existing wire format) and keep
/// at most `capacity` of them, newest-first.
public enum SnapshotHistoryStore {

    public static let key = "diagnostics.snapshotHistory"
    public static let capacity = 3

    public static func snapshots(defaults: UserDefaults = .standard) -> [DiagnosticsSnapshot] {
        guard let data = defaults.data(forKey: key) else { return [] }
        guard let blobs = try? JSONDecoder().decode([Data].self, from: data) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return blobs.compactMap { try? decoder.decode(DiagnosticsSnapshot.self, from: $0) }
    }

    public static func record(
        _ snapshot: DiagnosticsSnapshot,
        in defaults: UserDefaults = .standard
    ) {
        guard let payload = try? snapshot.encodedJSON() else { return }
        var existing: [Data] = (defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([Data].self, from: $0) }) ?? []
        existing.insert(payload, at: 0)
        if existing.count > capacity { existing = Array(existing.prefix(capacity)) }
        if let wrapper = try? JSONEncoder().encode(existing) {
            defaults.set(wrapper, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
