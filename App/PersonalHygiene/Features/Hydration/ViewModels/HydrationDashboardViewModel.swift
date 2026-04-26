import Foundation
import Observation

@Observable
@MainActor
final class HydrationDashboardViewModel {

    private let service: any HydrationService
    private let calendar: Calendar

    var todayLogs: [HydrationLog] = []
    var goal: HydrationGoal
    var errorMessage: String?

    init(
        service: any HydrationService,
        goal: HydrationGoal = .default,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.service = service
        self.goal = goal
        self.calendar = calendar
    }

    func reload(now: Date = Date()) {
        let day = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            todayLogs = []
            return
        }
        do {
            todayLogs = try service.logs(between: day, and: endOfDay)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func log(milliliters: Int, now: Date = Date()) {
        guard milliliters > 0 else { return }
        do {
            try service.log(milliliters: milliliters, at: now)
            reload(now: now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var totalMilliliters: Int {
        HydrationCompliance.totalMilliliters(on: Date(), logs: todayLogs, calendar: calendar)
    }

    var progress: Double {
        HydrationCompliance.progress(
            on: Date(),
            logs: todayLogs,
            goal: goal,
            calendar: calendar
        )
    }
}
