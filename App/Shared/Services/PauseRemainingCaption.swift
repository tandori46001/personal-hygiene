import Foundation

/// Round-25 slice T6.44: pure helper that returns a "pause ends in 23m"
/// caption used by both the watch settings page and the iPhone Settings
/// pause section.
public enum PauseRemainingCaption {

    public static func caption(
        pausedUntil: Date?,
        now: Date = Date()
    ) -> String? {
        guard let pausedUntil, pausedUntil > now else { return nil }
        let secondsLeft = Int(pausedUntil.timeIntervalSince(now))
        let minutes = max(0, secondsLeft / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            return String(format: "%dh %02dm", hours, remaining)
        }
        return "\(minutes)m"
    }
}
