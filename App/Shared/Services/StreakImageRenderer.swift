import Foundation

#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import UIKit

/// Round-23 slice T2.11: render a tiny "share streak as image" PNG for the
/// user's current positive-mood streak. Uses native `ImageRenderer` (round
/// 20 already established this pattern in the snapshot smoke tests).
@MainActor
public enum StreakImageRenderer {

    public static func renderStreak(
        days: Int,
        emoji: String = "🌟"
    ) -> Data? {
        let card = StreakCard(days: days, emoji: emoji)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return nil }
        return image.pngData()
    }
}

private struct StreakCard: View {
    let days: Int
    let emoji: String

    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: emoji)
                .font(.system(size: 64))
            Text(verbatim: "\(days)-day streak")
                .font(.system(size: 26, weight: .bold))
            Text(verbatim: "personal-hygiene")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 320, height: 320)
        .background(Color.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 24))
    }
}
#endif
