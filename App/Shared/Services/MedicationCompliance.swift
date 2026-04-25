import Foundation

/// Per-day medication compliance summary derived from `MedicationDoseLog`s.
public struct DailyCompliance: Equatable, Sendable {
    public let day: Date
    public let scheduledCount: Int
    public let takenCount: Int

    public var rate: Double {
        scheduledCount == 0 ? 1.0 : Double(takenCount) / Double(scheduledCount)
    }
}

public enum MedicationCompliance {

    /// Bucket logs by start-of-day and count taken vs. scheduled.
    /// Skipped + missed logs count toward `scheduledCount` but not toward `takenCount`.
    public static func dailySummaries(
        from logs: [MedicationDoseLog],
        between start: Date,
        and end: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [DailyCompliance] {
        var buckets: [Date: (scheduled: Int, taken: Int)] = [:]
        for log in logs where log.scheduledAt >= start && log.scheduledAt <= end {
            let day = calendar.startOfDay(for: log.scheduledAt)
            var bucket = buckets[day] ?? (0, 0)
            bucket.scheduled += 1
            if log.status == .taken {
                bucket.taken += 1
            }
            buckets[day] = bucket
        }

        return
            buckets
            .map { DailyCompliance(day: $0.key, scheduledCount: $0.value.scheduled, takenCount: $0.value.taken) }
            .sorted { $0.day < $1.day }
    }

    /// Adherence ratio across all logs in `[start, end]`.
    public static func overallAdherence(
        from logs: [MedicationDoseLog],
        between start: Date,
        and end: Date
    ) -> Double {
        let scoped = logs.filter { $0.scheduledAt >= start && $0.scheduledAt <= end }
        guard !scoped.isEmpty else { return 1.0 }
        let taken = scoped.filter { $0.status == .taken }.count
        return Double(taken) / Double(scoped.count)
    }
}
