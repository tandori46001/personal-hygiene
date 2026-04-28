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

    /// Captures the most recently deleted log so the UI can offer an undo. The
    /// view sets a timer to clear this after a few seconds; tapping Undo
    /// replays the original `(milliliters, timestamp)` and clears it.
    var lastDeleted: HydrationLog?

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
            lastDeleted = log
            reload(now: now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoLastDelete(now: Date = Date()) {
        guard let log = lastDeleted else { return }
        do {
            try service.log(milliliters: log.milliliters, at: log.drankAt)
            lastDeleted = nil
            reload(now: now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearLastDeleted() {
        lastDeleted = nil
    }

    /// Round-18 slice 22: returns the number of full calendar days since the
    /// most recent log, or `nil` if `recentLogs` is empty. The view shows a
    /// "comeback nudge" caption when this exceeds 2 days.
    func daysSinceLastLog(now: Date = Date()) -> Int? {
        guard let mostRecent = recentLogs.map(\.drankAt).max() else { return nil }
        let lastDay = calendar.startOfDay(for: mostRecent)
        let today = calendar.startOfDay(for: now)
        guard let delta = calendar.dateComponents([.day], from: lastDay, to: today).day else {
            return nil
        }
        return max(0, delta)
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

    /// Trailing 7-day totals (oldest first), each as `(dayStart, totalMl)`.
    /// Days without logs come back as `0` so the bar chart is dense.
    func weeklyTotals(now: Date = Date()) -> [(date: Date, milliliters: Int)] {
        HydrationCompliance.dailyTotals(
            on: now,
            logs: recentLogs,
            days: 7,
            calendar: calendar
        )
    }
}
