import SwiftUI

/// Round-25 slice T3.18 + T3.22: pure-presentational captions for the
/// SleepDashboard. Each renders an empty view when its input data isn't
/// sufficient.
struct SleepConsistencyScoreCaption: View {
    let inputs: SleepConsistencyScore.Inputs

    var body: some View {
        if let score = SleepConsistencyScore.score(inputs) {
            let tier = SleepConsistencyScore.tier(for: score)
            HStack {
                Text("sleep.consistency.score \(score)", bundle: .main)
                    .font(.callout.monospacedDigit())
                Spacer()
                Text(tierKey(tier), bundle: .main)
                    .font(.caption)
                    .foregroundStyle(tierColor(tier))
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func tierKey(_ tier: SleepConsistencyScore.Tier) -> LocalizedStringKey {
        switch tier {
        case .excellent: return "sleep.consistency.tier.excellent"
        case .good: return "sleep.consistency.tier.good"
        case .poor: return "sleep.consistency.tier.poor"
        }
    }

    private func tierColor(_ tier: SleepConsistencyScore.Tier) -> Color {
        switch tier {
        case .excellent: return .green
        case .good: return .blue
        case .poor: return .orange
        }
    }
}

struct SleepDebtTrackerCaption: View {
    let summary: SleepDebtTracker.Summary

    private var formatted: String {
        let abs = Swift.abs(summary.debtMinutes)
        let hours = abs / 60
        let minutes = abs % 60
        let sign = summary.debtMinutes > 0 ? "+" : (summary.debtMinutes < 0 ? "−" : "")
        return "\(sign)\(hours)h \(String(format: "%02d", minutes))m"
    }

    private var color: Color {
        switch summary.debtMinutes {
        case ..<0: return .blue
        case 0...60: return .green
        case 61...240: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack {
            Text("sleep.debt.label", bundle: .main)
                .font(.callout)
            Spacer()
            Text(verbatim: formatted)
                .font(.callout.monospacedDigit())
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }
}
