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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
