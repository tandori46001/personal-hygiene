import Foundation
import Observation

@Observable
@MainActor
final class TodayViewModel {

    private let repository: any RoutineRepository
    private let tripsRepository: (any TripsRepository)?
    private let skipStore: (any BlockSkipStore)?
    private let snoozeStore: (any BlockSnoozeStore)?
    private let focusScheduleStore: (any FocusScheduleStore)?
    private let calendar: Calendar

    var activeTemplate: RoutineTemplate?
    var todaysDayType: DayType = .weekday
    var errorMessage: String?
    /// Set of `Block.id`s already marked done today; cached so the row toggle
    /// is read synchronously from the view body.
    private(set) var completedBlockIDs: Set<UUID> = []
    /// Next upcoming trip (sorted by start date) — used for the Today countdown card.
    private(set) var upcomingTrip: Trip?

    init(
        repository: any RoutineRepository,
        tripsRepository: (any TripsRepository)? = nil,
        skipStore: (any BlockSkipStore)? = nil,
        snoozeStore: (any BlockSnoozeStore)? = nil,
        focusScheduleStore: (any FocusScheduleStore)? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.tripsRepository = tripsRepository
        self.skipStore = skipStore
        self.snoozeStore = snoozeStore
        self.focusScheduleStore = focusScheduleStore
        self.calendar = calendar
    }

    /// Whether the user marked `block` as skipped for today.
    func isSkipped(_ block: Block, now: Date = Date()) -> Bool {
        skipStore?.isSkipped(blockID: block.id, on: now, calendar: calendar) ?? false
    }

    /// Whether `block` was snoozed at least once today via the notification action.
    func isSnoozedToday(_ block: Block, now: Date = Date()) -> Bool {
        snoozeStore?.isSnoozed(blockID: block.id, on: now, calendar: calendar) ?? false
    }

    /// Toggle skip-for-today for `block`.
    func toggleSkippedToday(_ block: Block, now: Date = Date()) {
        guard let skipStore else { return }
        if skipStore.isSkipped(blockID: block.id, on: now, calendar: calendar) {
            skipStore.unskip(blockID: block.id, on: now, calendar: calendar)
        } else {
            skipStore.skip(blockID: block.id, on: now, calendar: calendar)
        }
    }

    /// Marks every not-yet-done, not-already-skipped block whose start time
    /// is at or after `block.startMinutesFromMidnight` as skipped for today.
    /// Used by the Today "Skip rest of today" swipe action — useful for sick
    /// days / unexpected interruptions without having to swipe each row.
    func skipRestOfToday(from block: Block, now: Date = Date()) {
        guard let skipStore, let activeTemplate else { return }
        let cutoff = block.startMinutesFromMidnight
        for candidate in activeTemplate.sortedBlocks
        where candidate.startMinutesFromMidnight >= cutoff {
            skipStore.skip(blockID: candidate.id, on: now, calendar: calendar)
        }
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
        if let tripsRepository {
            do {
                upcomingTrip = try Self.nextUpcoming(
                    trips: tripsRepository.allTrips(),
                    now: now,
                    calendar: calendar
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        // Round-25 slice T2.16: publish today's completion snapshot so
        // non-Today surfaces (TemplateListView header) can read the chip
        // figure without re-traversing the repository.
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        let dayKey = String(
            format: "%04d-%02d-%02d",
            comps.year ?? 0, comps.month ?? 0, comps.day ?? 0
        )
        TodayCompletionSnapshotStore.write(
            .init(dayKey: dayKey, done: doneCount, total: totalCount)
        )
    }

    static func nextUpcoming(trips: [Trip], now: Date, calendar: Calendar) -> Trip? {
        let today = calendar.startOfDay(for: now)
        return
            trips
            .filter { calendar.startOfDay(for: $0.startDate) >= today }
            .min { $0.startDate < $1.startDate }
    }

    func daysUntilUpcomingTrip(now: Date = Date()) -> Int? {
        guard let trip = upcomingTrip else { return nil }
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: trip.startDate)
        return calendar.dateComponents([.day], from: today, to: target).day
    }

    func isDone(_ block: Block) -> Bool {
        completedBlockIDs.contains(block.id)
    }

    /// Round-12 slice 25 / round-20 slice T4.19: clear today's completions +
    /// skips so the user can "start over". Returns a `ResetDaySnapshot` that
    /// `undoResetDay(snapshot:)` can replay so a misclick is recoverable
    /// within the 10-second toast window.
    @discardableResult
    func resetDay(now: Date = Date()) -> ResetDaySnapshot {
        let priorCompletions = blocks.filter { completedBlockIDs.contains($0.id) }
        let priorSkips = blocks.filter { skipStore?.isSkipped(blockID: $0.id, on: now, calendar: calendar) ?? false }
        for block in priorCompletions {
            try? repository.unmarkDone(block, on: now, calendar: calendar)
        }
        completedBlockIDs.removeAll()
        for block in blocks {
            skipStore?.unskip(blockID: block.id, on: now, calendar: calendar)
        }
        return ResetDaySnapshot(
            completionBlockIDs: priorCompletions.map(\.id),
            skipBlockIDs: priorSkips.map(\.id),
            capturedAt: now
        )
    }

    /// Round-20 slice T4.19: replay a snapshot returned by `resetDay`.
    /// Re-marks each block done + re-skips those that were skipped at capture
    /// time. No-op when there is nothing to restore.
    func undoResetDay(_ snapshot: ResetDaySnapshot) {
        let blocksByID = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })
        for id in snapshot.completionBlockIDs {
            if let block = blocksByID[id] {
                try? repository.markDone(block, on: snapshot.capturedAt, calendar: calendar)
                completedBlockIDs.insert(id)
            }
        }
        for id in snapshot.skipBlockIDs {
            skipStore?.skip(blockID: id, on: snapshot.capturedAt, calendar: calendar)
        }
    }

    public struct ResetDaySnapshot: Sendable, Equatable {
        public let completionBlockIDs: [UUID]
        public let skipBlockIDs: [UUID]
        public let capturedAt: Date

        public var isEmpty: Bool { completionBlockIDs.isEmpty && skipBlockIDs.isEmpty }
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

    /// Done count is computed against the *currently visible* blocks so a
    /// completion recorded against a block that was later deleted (or that
    /// belongs to a different template / day-type) cannot inflate the ratio
    /// past `totalCount`. Earlier this could yield "2 of 1" in the Today
    /// summary row after a template edit.
    var doneCount: Int {
        let activeIDs = Set(blocks.map(\.id))
        return completedBlockIDs.intersection(activeIDs).count
    }
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

    /// Round-19 slice T5.19: blocks scheduled for *tomorrow* (based on
    /// tomorrow's day-type's active template). Returns an empty array when
    /// no template exists for the target day-type. Pure read — does not
    /// mutate `activeTemplate` or `todaysDayType`.
    func tomorrowBlocks(now: Date = Date()) -> [Block] {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return [] }
        let dayType = Self.dayType(for: tomorrow, in: calendar)
        guard let template = try? repository.activeTemplate(for: dayType) else { return [] }
        return template.sortedBlocks
    }

    func currentBlock(at now: Date = Date()) -> Block? {
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return blocks.first {
            $0.startMinutesFromMidnight <= nowMinutes && $0.endMinutesFromMidnight > nowMinutes
        }
    }

    func activeFocusWindow(at now: Date = Date()) -> DeepFocusFilter.FocusWindow? {
        let scheduled = focusScheduleStore?.windows() ?? []
        return DeepFocusFilter.activeWindow(
            at: now,
            in: blocks,
            scheduledWindows: scheduled,
            calendar: calendar
        )
    }
}
