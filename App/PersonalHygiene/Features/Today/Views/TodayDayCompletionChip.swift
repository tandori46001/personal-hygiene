import SwiftUI

/// Round-25 slice T2.15: compact chip rendering today's completion as a
/// `XX%` pill in the navigation header. Companion to the existing
/// `TodayDayCompletionBar`. Pure presentational — caller passes done/total.
struct TodayDayCompletionChip: View {
    let done: Int
    let total: Int

    var body: some View {
        if total > 0 {
            let percent = TodayCompletionPercent.percent(done: done, total: total)
            Text(verbatim: "\(percent)%")
                .font(.caption.monospacedDigit().bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tint.opacity(0.18), in: Capsule())
                .foregroundStyle(tint)
                .accessibilityLabel(Text(
                    "today.dayCompletion.chip.a11y \(percent)",
                    bundle: .main
                ))
        }
    }

    private var tint: Color {
        let percent = TodayCompletionPercent.percent(done: done, total: total)
        switch percent {
        case 85...: return .green
        case 50...: return .blue
        default: return .orange
        }
    }
}
