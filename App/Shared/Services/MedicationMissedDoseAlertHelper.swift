import Foundation

/// Round-25 slice T3.23: pure helper that, given the user's medication
/// blocks + the current pending notifications, returns the next-future
/// medication block whose primary alert window has *passed* without a
/// completion record. Designed for an "did you take X?" diagnostics row
/// + future Critical Alerts re-fire path.
public enum MedicationMissedDoseAlertHelper {

    public struct Candidate: Equatable, Sendable {
        public let blockID: UUID
        public let blockTitle: String
        public let scheduledAt: Date
    }

    public static func nextMissed(
        blocks: [Block],
        completionsToday: Set<UUID>,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Candidate? {
        let medicationBlocks = blocks.filter { $0.medicationConceptIdentifier != nil }
        let nowMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)
        let startOfDay = calendar.startOfDay(for: now)

        return medicationBlocks
            .filter { $0.startMinutesFromMidnight <= nowMinutes }
            .filter { !completionsToday.contains($0.id) }
            .max(by: { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight })
            .flatMap { block in
                let scheduled = startOfDay.addingTimeInterval(
                    Double(block.startMinutesFromMidnight) * 60
                )
                return Candidate(
                    blockID: block.id,
                    blockTitle: block.title,
                    scheduledAt: scheduled
                )
            }
    }
}
