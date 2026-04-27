import Foundation

/// Round-15 slice 11: pre-cooked milestone bundle (6m / 3m / 1m / 1w) the
/// user can drop into a new trip with one tap. Pure value-types.
public enum MilestoneDefaultBundle {

    public struct Seed: Sendable, Equatable {
        public let title: String
        public let daysBefore: Int

        public init(title: String, daysBefore: Int) {
            self.title = title
            self.daysBefore = daysBefore
        }
    }

    public static let standard: [Seed] = [
        Seed(title: "Book accommodations", daysBefore: 180),
        Seed(title: "Confirm passport + visa", daysBefore: 90),
        Seed(title: "Buy travel insurance", daysBefore: 30),
        Seed(title: "Final pack + check-in", daysBefore: 7),
    ]
}
