import Foundation

/// Round-15 slice 27: pure helper for the TemplateEditor footer that shows
/// "Total: Xh Ym · N blocks". No persistence — caller passes the blocks.
public enum TemplateDurationCalculator {

    public static func totalMinutes(_ blocks: [Block]) -> Int {
        blocks.reduce(0) { $0 + max(0, $1.durationMinutes) }
    }

    public static func formatted(_ totalMinutes: Int) -> String {
        guard totalMinutes > 0 else { return "0m" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}
