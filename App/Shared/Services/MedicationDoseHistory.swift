import Foundation

/// Round-15 slice 41: rolling history of medication dose completions. Backed
/// by `BlockCompletion` records — reads through the `RoutineRepository`'s
/// completion store. Pure helper that aggregates.
public enum MedicationDoseHistory {

    public struct Entry: Equatable, Sendable, Identifiable {
        public let id: UUID
        public let blockID: UUID
        public let blockTitle: String
        public let conceptIdentifier: String?
        public let completedAt: Date

        public init(
            id: UUID = UUID(),
            blockID: UUID,
            blockTitle: String,
            conceptIdentifier: String?,
            completedAt: Date
        ) {
            self.id = id
            self.blockID = blockID
            self.blockTitle = blockTitle
            self.conceptIdentifier = conceptIdentifier
            self.completedAt = completedAt
        }
    }

    /// Filter completion + block pairs to medication-only entries within the
    /// trailing `days` window. Returned newest-first.
    public static func recent(
        completions: [BlockCompletion],
        blocks: [Block],
        days: Int = 30,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Entry] {
        let blocksByID = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now)
            ?? now.addingTimeInterval(-Double(days * 86_400))
        return completions
            .filter { $0.completedAt >= cutoff }
            .compactMap { completion -> Entry? in
                guard let block = blocksByID[completion.blockID],
                      block.medicationConceptIdentifier != nil
                else { return nil }
                return Entry(
                    blockID: block.id,
                    blockTitle: block.title,
                    conceptIdentifier: block.medicationConceptIdentifier,
                    completedAt: completion.completedAt
                )
            }
            .sorted { $0.completedAt > $1.completedAt }
    }
}
