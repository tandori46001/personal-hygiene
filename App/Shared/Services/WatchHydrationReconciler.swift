import Foundation

/// Round-22 slice T2.12: drains `WatchHydrationGlanceStore.pendingTaps()`
/// into the iPhone-side `HydrationService` on app foreground. Watch users
/// can log water from the wrist offline; iPhone replays those taps next
/// time it opens.
///
/// Stays decoupled from SwiftData by taking a `HydrationService` instance.
/// Failures during a single tap don't abort the run — best-effort drain
/// followed by a single `clearPending()` if the whole batch landed.
@MainActor
public enum WatchHydrationReconciler {

    @discardableResult
    public static func drain(
        into service: any HydrationService,
        now: Date = Date()
    ) -> Int {
        let pending = WatchHydrationGlanceStore.pendingTaps()
        guard !pending.isEmpty else { return 0 }
        var landed = 0
        for amount in pending {
            do {
                try service.log(milliliters: amount, at: now)
                landed += 1
            } catch {
                // First failure stops the drain so a partial flush doesn't
                // misalign the queue against SwiftData state.
                break
            }
        }
        if landed == pending.count {
            WatchHydrationGlanceStore.clearPending()
        } else if landed > 0 {
            // Trim the queue to only the unlanded tail so a re-attempt on
            // next foreground doesn't double-log already-flushed taps.
            let remaining = Array(pending.dropFirst(landed))
            WatchHydrationGlanceStore.clearPending()
            for amount in remaining {
                WatchHydrationGlanceStore.appendPendingTap(amountMl: amount)
            }
        }
        return landed
    }
}
