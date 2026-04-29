import Foundation
import SwiftData

/// Round-26: nuclear option for users whose store gets into a bad state
/// (e.g. after importing a malformed backup pre-validation, or a stale
/// migration). Wipes:
///
/// - All `@Model` rows in SwiftData (templates, blocks, completions,
///   hydration, housekeeping, trips, milestones, documents).
/// - The mood log + weekly goal in UserDefaults.
/// - The template archive flags in UserDefaults.
/// - The housekeeping completion log per-room day-keys.
/// - The watch hydration pending taps queue.
/// - The "most recent backup" pointer.
/// - The diagnostics + refresh trace ring buffers.
///
/// **Does NOT touch:**
/// - Onboarding completion flag (re-running onboarding mid-reset is more
///   confusing than helpful).
/// - Theme preference (cosmetic, no data risk).
/// - Notification permission status (out of our control).
@MainActor
public enum FullDataResetter {

    public static func resetEverything(in context: ModelContext) throws {
        try wipeSwiftData(context)
        wipeUserDefaults()
    }

    private static func wipeSwiftData(_ context: ModelContext) throws {
        let templates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        templates.forEach(context.delete)
        let trips = try context.fetch(FetchDescriptor<Trip>())
        trips.forEach(context.delete)
        let completions = try context.fetch(FetchDescriptor<BlockCompletion>())
        completions.forEach(context.delete)
        let hydration = try context.fetch(FetchDescriptor<HydrationLog>())
        hydration.forEach(context.delete)
        let housekeeping = try context.fetch(FetchDescriptor<HousekeepingTask>())
        housekeeping.forEach(context.delete)
        try context.save()
        NotificationCenter.default.post(name: .routineDataChanged, object: nil)
    }

    private static func wipeUserDefaults() {
        MoodLogStore.clear()
        MoodWeeklyGoalStore.clear()
        TemplateArchiveStore.clear()
        let appGroup = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
        HousekeepingCompletionLog.clear(in: appGroup)
        WatchHydrationGlanceStore.clearPending(in: appGroup)
        MostRecentBackupStore.clear()
        DiagnosticsErrorLog.shared.clear()
        // CacheResetter handles its own bag of weather/currency caches.
        CacheResetter.resetAll()
    }
}
