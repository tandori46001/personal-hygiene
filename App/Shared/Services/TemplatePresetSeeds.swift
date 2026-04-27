import Foundation

/// Round-14 slice 28: pre-defined block bundles a user can drop into an
/// existing template. Each preset is an ordered list of `BlockSeed` value
/// types — start times are baseline; the editor offsets them to fit after
/// the last existing block.
public enum TemplatePresetSeeds {

    public struct BlockSeed: Sendable, Equatable {
        public let title: String
        public let category: BlockCategory
        public let startMinutesFromMidnight: Int
        public let durationMinutes: Int

        public init(
            title: String,
            category: BlockCategory,
            startMinutesFromMidnight: Int,
            durationMinutes: Int
        ) {
            self.title = title
            self.category = category
            self.startMinutesFromMidnight = startMinutesFromMidnight
            self.durationMinutes = durationMinutes
        }
    }

    public enum Preset: String, CaseIterable, Sendable {
        case morningRoutine
        case workday
        case weekendChores

        public var displayName: String {
            switch self {
            case .morningRoutine: "Morning routine"
            case .workday: "Workday"
            case .weekendChores: "Weekend chores"
            }
        }

        public var seeds: [BlockSeed] {
            switch self {
            case .morningRoutine: Self.morningRoutineSeeds
            case .workday: Self.workdaySeeds
            case .weekendChores: Self.weekendChoresSeeds
            }
        }

        private static let morningRoutineSeeds: [BlockSeed] = [
            BlockSeed(
                title: "Wake up",
                category: .hygiene,
                startMinutesFromMidnight: 7 * 60,
                durationMinutes: 10
            ),
            BlockSeed(
                title: "Brush + shower",
                category: .hygiene,
                startMinutesFromMidnight: 7 * 60 + 10,
                durationMinutes: 20
            ),
            BlockSeed(
                title: "Breakfast",
                category: .meal,
                startMinutesFromMidnight: 7 * 60 + 30,
                durationMinutes: 20
            ),
        ]

        private static let workdaySeeds: [BlockSeed] = [
            BlockSeed(
                title: "Deep work",
                category: .work,
                startMinutesFromMidnight: 9 * 60,
                durationMinutes: 90
            ),
            BlockSeed(
                title: "Stand-up",
                category: .work,
                startMinutesFromMidnight: 10 * 60 + 30,
                durationMinutes: 15
            ),
            BlockSeed(
                title: "Lunch",
                category: .meal,
                startMinutesFromMidnight: 13 * 60,
                durationMinutes: 45
            ),
        ]

        private static let weekendChoresSeeds: [BlockSeed] = [
            BlockSeed(
                title: "Groceries",
                category: .shopping,
                startMinutesFromMidnight: 10 * 60,
                durationMinutes: 60
            ),
            BlockSeed(
                title: "Laundry",
                category: .housekeeping,
                startMinutesFromMidnight: 11 * 60 + 30,
                durationMinutes: 90
            ),
            BlockSeed(
                title: "Cleanup",
                category: .housekeeping,
                startMinutesFromMidnight: 14 * 60,
                durationMinutes: 60
            ),
        ]
    }
}
