import Foundation
import Observation

@Observable
@MainActor
final class HydrationDashboardViewModel {

    private let service: any HydrationService
    private let calendar: Calendar

    var todayLogs: [HydrationLog] = []
    var recentLogs: [HydrationLog] = []
    var goal: HydrationGoal
    var errorMessage: String?

    /// Number of days of history we keep around to compute the streak.
    /// 14 is plenty for a UI badge — anything higher just bloats the fetch.
    private let streakWindowDays = 14

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
            recentLogs = []
            return
        }
        let windowStart = calendar.date(byAdding: .day, value: -streakWindowDays, to: day) ?? day
        do {
            todayLogs = try service.logs(between: day, and: endOfDay)
            recentLogs = try service.logs(between: windowStart, and: endOfDay)
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

    func deleteLog(_ log: HydrationLog, now: Date = Date()) {
        do {
            try service.delete(log)
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

    /// Consecutive days (ending today) where the goal was met. 0 until today
    /// itself crosses the goal.
    func streakDays(now: Date = Date()) -> Int {
        HydrationCompliance.currentStreakDays(
            on: now,
            logs: recentLogs,
            goal: goal,
            calendar: calendar
        )
    }

    /// Longest goal-meeting run within the rolling 14-day window. Survives a
    /// missed day so the user has something to chase even after a setback.
    func bestStreakDays(now: Date = Date()) -> Int {
        HydrationCompliance.bestStreakDays(
            on: now,
            logs: recentLogs,
            goal: goal,
            calendar: calendar
        )
    }
}
