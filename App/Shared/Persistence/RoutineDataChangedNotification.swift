import Foundation

extension Notification.Name {
    /// Round-25 fix: posted by `SwiftDataRoutineRepository` after every
    /// successful `context.save()` (template create / delete / activate /
    /// block upsert / completion mark / etc.). Cross-tab observers
    /// (TodayView, MedicationComplianceView, the watch's TodayWatchView)
    /// listen via `.onReceive(NotificationCenter.default.publisher(for:))`
    /// to refresh their `@Observable` view models — without this, switching
    /// to Templates, creating/activating a template, then switching back
    /// to Today left `viewModel.activeTemplate` stuck at nil because iOS 18
    /// TabView's `.onAppear` doesn't reliably re-fire when tabs stay alive
    /// in the hierarchy.
    public static let routineDataChanged = Notification.Name("personalHygiene.routineDataChanged")
}
