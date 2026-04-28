import Foundation

/// Round-23 slice T2.10: per-mood count histogram for the Settings chart.
/// Pure helper — UI side renders a Swift Charts bar chart over these bins.
public enum MoodHistogram {

    public struct Bin: Equatable, Sendable, Identifiable {
        public let mood: MoodLogStore.Mood
        public let count: Int
        public var id: String { mood.rawValue }
    }

    public static func bins(
        from entries: [MoodLogStore.Entry]
    ) -> [Bin] {
        var counts: [MoodLogStore.Mood: Int] = [:]
        for entry in entries {
            guard let mood = entry.moodCase else { continue }
            counts[mood, default: 0] += 1
        }
        // Always emit one bin per mood (count zero when missing) so the
        // chart axis is stable across renders.
        return MoodLogStore.Mood.allCases.map { mood in
            Bin(mood: mood, count: counts[mood] ?? 0)
        }
    }
}
