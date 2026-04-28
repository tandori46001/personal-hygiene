import Foundation
import Observation

@Observable
@MainActor
final class SleepDashboardViewModel {

    private let service: any SleepService

    var wakeUpHour: Int
    var wakeUpMinute: Int
    var lastNight: SleepNight?
    var isAvailable: Bool = false
    var errorMessage: String?
    /// Round-25 slice T2.9/T2.10: trailing 14-night history fed into the
    /// weekly-average chart, weekly-delta caption, and bedtime variance
    /// verdict. Populated from `lastNight` for now (1 entry); will fill out
    /// once `SleepService` exposes a ranged fetch alongside HealthKit
    /// observer wiring. Empty array = sections render nothing.
    var recentNights: [SleepNight] = []
    /// Round-25 slice T2.10: minute-of-midnight bedtime samples for the
    /// `SleepBedtimeVariance` verdict. Sources from `recentNights` once
    /// the service exposes per-night start times.
    var recentBedtimeMinutes: [Int] = []

    init(
        service: any SleepService,
        defaultWakeUpHour: Int = 6,
        defaultWakeUpMinute: Int = 30
    ) {
        self.service = service
        self.wakeUpHour = defaultWakeUpHour
        self.wakeUpMinute = defaultWakeUpMinute
    }

    var bedtimeMinutes: Int {
        BedtimeCalculator.bedtimeMinutes(
            forWakeUp: wakeUpHour * 60 + wakeUpMinute
        )
    }

    var lastNightDeficitMinutes: Int? {
        guard let actual = lastNight?.durationMinutes else { return nil }
        return BedtimeCalculator.deficit(actualMinutes: actual)
    }

    func reload() async {
        isAvailable = service.isAvailable
        guard isAvailable else { return }
        do {
            lastNight = try await service.lastNight()
            if let night = lastNight {
                recentNights = [night]
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
