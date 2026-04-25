import Foundation
import Observation

/// Edits an existing `Block` or builds a new one from form state.
///
/// Time is exposed as `startHour` + `startMinute` for picker UIs but persisted
/// as a single `startMinutesFromMidnight: Int` on `Block`.
@Observable
@MainActor
final class BlockEditorViewModel {

    var title: String
    var category: BlockCategory
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int
    var notes: String
    var notificationLeadMinutes: Int
    var isDeepFocus: Bool

    let editingBlockID: UUID?

    init() {
        self.title = ""
        self.category = .hygiene
        self.startHour = 7
        self.startMinute = 0
        self.durationMinutes = 30
        self.notes = ""
        self.notificationLeadMinutes = 15
        self.isDeepFocus = false
        self.editingBlockID = nil
    }

    init(editing block: Block) {
        self.title = block.title
        self.category = block.category
        self.startHour = block.startMinutesFromMidnight / 60
        self.startMinute = block.startMinutesFromMidnight % 60
        self.durationMinutes = block.durationMinutes
        self.notes = block.notes ?? ""
        self.notificationLeadMinutes = block.notificationLeadMinutes
        self.isDeepFocus = block.isDeepFocus
        self.editingBlockID = block.id
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (0..<24).contains(startHour)
            && (0..<60).contains(startMinute)
            && durationMinutes > 0
            && durationMinutes <= 24 * 60
            && notificationLeadMinutes >= 0
    }

    var startMinutesFromMidnight: Int {
        startHour * 60 + startMinute
    }

    /// Returns a new `Block` with the current form state.
    /// For edits, the caller should mutate the existing block instead of inserting this one.
    func snapshot() -> Block {
        Block(
            id: editingBlockID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            startMinutesFromMidnight: startMinutesFromMidnight,
            durationMinutes: durationMinutes,
            notes: notes.isEmpty ? nil : notes,
            notificationLeadMinutes: notificationLeadMinutes,
            isDeepFocus: isDeepFocus
        )
    }

    /// Apply the form state in-place to an existing `Block` (preferred for edits).
    func apply(to block: Block) {
        block.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        block.category = category
        block.startMinutesFromMidnight = startMinutesFromMidnight
        block.durationMinutes = durationMinutes
        block.notes = notes.isEmpty ? nil : notes
        block.notificationLeadMinutes = notificationLeadMinutes
        block.isDeepFocus = isDeepFocus
    }
}
