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
    /// Set of `Block.id`s already marked done today; cached so the row toggle
    /// is read synchronously from the view body.
    private(set) var completedBlockIDs: Set<UUID> = []

    init(repository: any RoutineRepository, calendar: Calendar = .autoupdatingCurrent) {
        self.repository = repository
        self.calendar = calendar
    }

    func reload(now: Date = Date()) {
        todaysDayType = Self.dayType(for: now, in: calendar)
        do {
            activeTemplate = try repository.activeTemplate(for: todaysDayType)
            let completions = try repository.completions(on: now, calendar: calendar)
            completedBlockIDs = Set(completions.map(\.blockID))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isDone(_ block: Block) -> Bool {
        completedBlockIDs.contains(block.id)
    }

    func toggleDone(_ block: Block, now: Date = Date()) {
        do {
            if completedBlockIDs.contains(block.id) {
                try repository.unmarkDone(block, on: now, calendar: calendar)
                completedBlockIDs.remove(block.id)
            } else {
                try repository.markDone(block, on: now, calendar: calendar)
                completedBlockIDs.insert(block.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var doneCount: Int { completedBlockIDs.count }
    var totalCount: Int { blocks.count }

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
