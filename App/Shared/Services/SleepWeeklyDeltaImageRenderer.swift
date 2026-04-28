import Foundation

#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import UIKit

/// Round-25 slice T2.14: render a "this week vs last week" PNG card the
/// user can share from `SleepDashboardView`. Mirrors `StreakImageRenderer`'s
/// pattern (`ImageRenderer` → `pngData()`).
@MainActor
public enum SleepWeeklyDeltaImageRenderer {

    public static func render(_ summary: SleepWeeklyDelta.Summary) -> Data? {
        let card = SleepDeltaCard(summary: summary)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return nil }
        return image.pngData()
    }
}

private struct SleepDeltaCard: View {
    let summary: SleepWeeklyDelta.Summary

    private var deltaLine: String {
        String(format: "%+.0f min", summary.delta)
    }

    private var arrow: String {
        if summary.delta > 5 { return "↑" }
        if summary.delta < -5 { return "↓" }
        return "→"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: arrow)
                .font(.system(size: 56, weight: .bold))
            Text(verbatim: deltaLine)
                .font(.system(size: 28, weight: .semibold).monospacedDigit())
            Text(verbatim: "vs last week")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(verbatim: "personal-hygiene · sleep")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(36)
        .frame(width: 320, height: 320)
        .background(Color.indigo.opacity(0.15), in: RoundedRectangle(cornerRadius: 24))
    }
}
#endif
