import SwiftUI

/// Round-22 slice T5.27: thin horizontal bar showing the percentage of the
/// day's blocks already marked done. Lives below the existing progress
/// summary row (which renders the `done / total` count).
struct TodayDayCompletionBar: View {
    let done: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(done) / Double(total)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ProgressView(value: fraction)
                .progressViewStyle(.linear)
                .tint(progressTint)
            Text("today.dayCompletion.caption \(Int((fraction * 100).rounded()))", bundle: .main)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var progressTint: Color {
        switch fraction {
        case 0.85...: .green
        case 0.5...: .blue
        default: .orange
        }
    }
}
