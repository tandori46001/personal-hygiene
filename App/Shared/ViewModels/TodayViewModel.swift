import Foundation
import Observation

@Observable
@MainActor
final class TodayViewModel {

    private let repository: any RoutineRepository
    private let calendar: Calendar

    var activeTemplate: RoutineTemplate?
    var todaysDayType: DayType = .weekday
    var errorMessage: String?

    init(repository: any RoutineRepository, calendar: Calendar = .autoupdatingCurrent) {
        self.repository = repository
        self.calendar = calendar
    }

    func reload(now: Date = Date()) {
        todaysDayType = Self.dayType(for: now, in: calendar)
        do {
            activeTemplate = try repository.activeTemplate(for: todaysDayType)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var blocks: [Block] {
        activeTemplate?.sortedBlocks ?? []
    }

    static func dayType(for date: Date, in calendar: Calendar) -> DayType {
        let weekday = calendar.component(.weekday, from: date)
        // Calendar.weekday: 1 = Sunday, 7 = Saturday
        return (weekday == 1 || weekday == 7) ? .weekend : .weekday
    }

    func nextBlock(after now: Date = Date()) -> Block? {
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return blocks.first { $0.startMinutesFromMidnight > nowMinutes }
    }

    func currentBlock(at now: Date = Date()) -> Block? {
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return blocks.first {
            $0.startMinutesFromMidnight <= nowMinutes && $0.endMinutesFromMidnight > nowMinutes
        }
    }

    func activeFocusWindow(at now: Date = Date()) -> DeepFocusFilter.FocusWindow? {
        DeepFocusFilter.activeWindow(at: now, in: blocks, calendar: calendar)
    }
}
