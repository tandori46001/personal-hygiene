import Foundation

/// Daily hydration target. Pure value type — stored in UserDefaults / settings.
public struct HydrationGoal: Equatable, Hashable, Sendable, Codable {
    public let dailyMilliliters: Int

    public init(dailyMilliliters: Int) {
        self.dailyMilliliters = max(0, dailyMilliliters)
    }

    public static let `default` = Self(dailyMilliliters: 2000)
}
