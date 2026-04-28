import SwiftUI

/// Round-25 slice T6.41: circular ring view rendering today's completion
/// percentage. Reads from `TodayCompletionSnapshotStore` via the App
/// Group so the watch can show progress without re-traversing SwiftData.
struct WatchTodayCompletionRing: View {

    let done: Int
    let total: Int

    private var percent: Int {
        TodayCompletionPercent.percent(done: done, total: total)
    }

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(done) / Double(total)
    }

    var body: some View {
        if total > 0 {
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(percent)%")
                    .font(.system(.callout, design: .rounded).monospacedDigit().bold())
            }
            .frame(width: 56, height: 56)
            .accessibilityElement(children: .combine)
        }
    }

    private var ringColor: Color {
        switch percent {
        case 85...: return .green
        case 50...: return .blue
        default: return .orange
        }
    }
}
