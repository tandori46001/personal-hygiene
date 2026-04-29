import SwiftUI

/// Round 27 WS-B B6: surfaces a locale-seeded or custom important day
/// (Mother's Day, Christmas, anniversary etc.) on Today.
struct ImportantDayRow: View {

    let entry: ImportantDayResolver.UpcomingEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.isCustom ? "star.fill" : "calendar.badge.exclamationmark")
                .foregroundStyle(entry.isCustom ? .yellow : .orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.name)
                    .font(.headline)
                    .lineLimit(1)
                if entry.daysUntil == 0 {
                    Text("today.importantDay.todayBang", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .bold()
                } else {
                    Text("today.importantDay.inDays \(entry.daysUntil)", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
