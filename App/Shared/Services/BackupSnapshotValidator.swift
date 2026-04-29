import Foundation

/// Round-26 fix: pre-flight validation for `BackupSnapshot` before
/// `BackupService.restore` wipes the live store. Catches:
///
/// - Snapshot version above the supported range (forward-version) — refuse
///   instead of silently dropping unknown fields.
/// - Duplicate UUIDs within a collection (would clobber each other on
///   restore).
/// - Out-of-range block start times / non-positive durations.
/// - Unknown `dayType` / `category` / `recurrence` / `mood` raw values
///   (decode falls back silently otherwise — masks data loss).
/// - `Trip.startDate > endDate`.
/// - `BlockCompletion.blockID` referencing a block id not in the snapshot.
/// - Negative numeric fields (`milestone.daysBefore`, `escalationDays`,
///   `notificationLeadMinutes`, `milliliters`).
///
/// Returned `ValidationReport` has separate `.errors` (block restore) and
/// `.warnings` (proceed but flag) so the import sheet can show both.
///
/// Round-28: split the original 100-line `validate(_:)` into per-entity
/// helpers so each fits the cyclomatic-complexity / function-length
/// budget. Behaviour identical — `BackupSnapshotValidatorTests` confirms.
public enum BackupSnapshotValidator {

    public static let supportedVersionRange: ClosedRange<Int> = 1...6

    public struct ValidationReport: Equatable, Sendable {
        public var errors: [String]
        public var warnings: [String]

        public var isFatal: Bool { !errors.isEmpty }
        public var isClean: Bool { errors.isEmpty && warnings.isEmpty }

        public init(errors: [String] = [], warnings: [String] = []) {
            self.errors = errors
            self.warnings = warnings
        }
    }

    public static func validate(_ snapshot: BackupSnapshot) -> ValidationReport {
        var errors: [String] = []
        var warnings: [String] = []
        validateVersion(snapshot, errors: &errors)
        let blockIDs = validateTemplates(snapshot, errors: &errors, warnings: &warnings)
        validateCompletions(snapshot, blockIDs: blockIDs, errors: &errors, warnings: &warnings)
        validateHydration(snapshot, errors: &errors)
        validateHousekeeping(snapshot, errors: &errors, warnings: &warnings)
        validateTrips(snapshot, errors: &errors, warnings: &warnings)
        validateMood(snapshot, warnings: &warnings)
        validateMoodGoal(snapshot, warnings: &warnings)
        validateHousekeepingLog(snapshot, warnings: &warnings)
        return ValidationReport(errors: errors, warnings: warnings)
    }

    // MARK: - Per-entity helpers

    private static func validateVersion(_ snapshot: BackupSnapshot, errors: inout [String]) {
        let lower = supportedVersionRange.lowerBound
        let upper = supportedVersionRange.upperBound
        if snapshot.version < lower {
            errors.append(
                "Snapshot version \(snapshot.version) is below the supported range (\(lower)–\(upper))."
            )
        }
        if snapshot.version > upper {
            errors.append(
                "Snapshot version \(snapshot.version) is newer than this app supports "
                + "(\(upper)). Update the app before restoring."
            )
        }
    }

    private static func validateTemplates(
        _ snapshot: BackupSnapshot,
        errors: inout [String],
        warnings: inout [String]
    ) -> Set<UUID> {
        var templateIDs = Set<UUID>()
        var allBlockIDs = Set<UUID>()
        for template in snapshot.templates {
            if !templateIDs.insert(template.id).inserted {
                errors.append("Duplicate template id: \(template.id).")
            }
            if DayType(rawValue: template.dayType) == nil {
                errors.append("Template '\(template.name)' has unknown dayType '\(template.dayType)'.")
            }
            validateBlocks(in: template, allBlockIDs: &allBlockIDs, errors: &errors, warnings: &warnings)
        }
        return allBlockIDs
    }

    private static func validateBlocks(
        in template: BackupSnapshot.TemplatePayload,
        allBlockIDs: inout Set<UUID>,
        errors: inout [String],
        warnings: inout [String]
    ) {
        for block in template.blocks {
            if !allBlockIDs.insert(block.id).inserted {
                errors.append("Duplicate block id: \(block.id) in template '\(template.name)'.")
            }
            if BlockCategory(rawValue: block.category) == nil {
                errors.append("Block '\(block.title)' has unknown category '\(block.category)'.")
            }
            if !(0..<24 * 60).contains(block.startMinutesFromMidnight) {
                errors.append("Block '\(block.title)' has invalid start time \(block.startMinutesFromMidnight).")
            }
            if block.durationMinutes <= 0 {
                errors.append("Block '\(block.title)' has non-positive duration \(block.durationMinutes).")
            }
            if block.notificationLeadMinutes < 0 {
                warnings.append(
                    "Block '\(block.title)' has negative notificationLeadMinutes; will clamp to 0."
                )
            }
        }
    }

    private static func validateCompletions(
        _ snapshot: BackupSnapshot,
        blockIDs: Set<UUID>,
        errors: inout [String],
        warnings: inout [String]
    ) {
        var completionIDs = Set<UUID>()
        for completion in snapshot.completions {
            if !completionIDs.insert(completion.id).inserted {
                errors.append("Duplicate completion id: \(completion.id).")
            }
            if !blockIDs.contains(completion.blockID) {
                warnings.append(
                    "Completion references unknown blockID \(completion.blockID); will be skipped."
                )
            }
        }
    }

    private static func validateHydration(_ snapshot: BackupSnapshot, errors: inout [String]) {
        var hydrationIDs = Set<UUID>()
        for log in snapshot.hydration {
            if !hydrationIDs.insert(log.id).inserted {
                errors.append("Duplicate hydration log id: \(log.id).")
            }
            if log.milliliters <= 0 {
                errors.append("Hydration log has non-positive milliliters \(log.milliliters).")
            }
        }
    }

    private static func validateHousekeeping(
        _ snapshot: BackupSnapshot,
        errors: inout [String],
        warnings: inout [String]
    ) {
        var housekeepingIDs = Set<UUID>()
        for task in snapshot.housekeeping {
            if !housekeepingIDs.insert(task.id).inserted {
                errors.append("Duplicate housekeeping task id: \(task.id).")
            }
            if HousekeepingRecurrence(rawValue: task.recurrence) == nil {
                errors.append(
                    "Housekeeping task '\(task.title)' has unknown recurrence '\(task.recurrence)'."
                )
            }
            if task.escalationDays < 0 {
                warnings.append(
                    "Housekeeping task '\(task.title)' has negative escalationDays; will clamp to 0."
                )
            }
        }
    }

    private static func validateTrips(
        _ snapshot: BackupSnapshot,
        errors: inout [String],
        warnings: inout [String]
    ) {
        var tripIDs = Set<UUID>()
        for trip in snapshot.trips {
            if !tripIDs.insert(trip.id).inserted {
                errors.append("Duplicate trip id: \(trip.id).")
            }
            if trip.startDate > trip.endDate {
                errors.append("Trip '\(trip.name)' has startDate after endDate.")
            }
            for milestone in trip.milestones where milestone.daysBefore < 0 {
                warnings.append(
                    "Trip '\(trip.name)' milestone '\(milestone.title)' has "
                    + "negative daysBefore; will clamp to 0."
                )
            }
        }
    }

    private static func validateMood(_ snapshot: BackupSnapshot, warnings: inout [String]) {
        guard let entries = snapshot.mood else { return }
        for (index, entry) in entries.enumerated()
            where MoodLogStore.Mood(rawValue: entry.mood) == nil {
            warnings.append("Mood entry #\(index) has unknown mood '\(entry.mood)'; will be skipped.")
        }
    }

    private static func validateMoodGoal(_ snapshot: BackupSnapshot, warnings: inout [String]) {
        if let goal = snapshot.moodWeeklyGoal, !MoodWeeklyGoalStore.allowedRange.contains(goal) {
            warnings.append("Mood weekly goal \(goal) is outside the allowed range; will clamp.")
        }
    }

    private static func validateHousekeepingLog(_ snapshot: BackupSnapshot, warnings: inout [String]) {
        guard let logMap = snapshot.housekeepingCompletionLog else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        for (room, days) in logMap {
            for dayKey in days where formatter.date(from: dayKey) == nil {
                warnings.append(
                    "Housekeeping log room '\(room)' has malformed dayKey '\(dayKey)'; will be skipped."
                )
            }
        }
    }
}
