import Foundation

/// One night of sleep summarized as a duration.
public struct SleepNight: Hashable, Sendable {
    public let nightOf: Date
    public let durationMinutes: Int

    public init(nightOf: Date, durationMinutes: Int) {
        self.nightOf = nightOf
        self.durationMinutes = durationMinutes
    }
}

@MainActor
public protocol SleepService {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws -> Bool
    func lastNight() async throws -> SleepNight?
}

@MainActor
public final class InMemorySleepService: SleepService {

    public var isAvailable: Bool = true
    public var stub: SleepNight?

    public init(stub: SleepNight? = nil) {
        self.stub = stub
    }

    public func requestAuthorization() async throws -> Bool { true }

    public func lastNight() async throws -> SleepNight? { stub }
}

@MainActor
public final class HealthKitSleepService: SleepService {
    public init() {}
    public var isAvailable: Bool { false }  // not bridged into the simulator
    public func requestAuthorization() async throws -> Bool { false }
    public func lastNight() async throws -> SleepNight? { nil }
}
