import SwiftUI

/// Round-22 slice T2.10: banner row surfacing
/// `HousekeepingStreakAutoSnooze.suggestedSnoozeDays(...)` when a room has a
/// 7+ day streak. Hidden when no qualifying streak exists.
struct HousekeepingStreakBanner: View {
    let rooms: [String]

    private struct Suggestion: Identifiable {
        let id = UUID()
        let room: String
        let streak: Int
        let snoozeDays: Int
    }

    private var suggestions: [Suggestion] {
        rooms.compactMap { room in
            let result = HousekeepingCompletionLog.suggestedSnoozeDays(room: room)
            guard result.snoozeDays > 0 else { return nil }
            return Suggestion(room: room, streak: result.currentStreak, snoozeDays: result.snoozeDays)
        }
    }

    var body: some View {
        let qualifying = suggestions
        if !qualifying.isEmpty {
            Section {
                ForEach(qualifying) { suggestion in
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: suggestion.room)
                                .font(.callout.bold())
                            Text(
                                "housekeeping.streak.banner \(suggestion.streak) \(suggestion.snoozeDays)",
                                bundle: .main
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("housekeeping.streak.banner.title", bundle: .main)
            } footer: {
                Text("housekeeping.streak.banner.footer", bundle: .main)
            }
        }
    }
}
