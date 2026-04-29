import SwiftUI

/// Round 27 WS-B B1: today + upcoming birthday surface for TodayView.
/// Mirrors the `TripCountdownRow` visual idiom for consistency.
struct BirthdayTodayRow: View {

    let entry: UpcomingBirthdays.Upcoming

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "gift.fill")
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.contact.displayName)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if entry.daysUntil == 0 {
                        Text("today.birthday.todayBang", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .bold()
                    } else {
                        Text("today.birthday.inDays \(entry.daysUntil)", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let age = computedAge(at: entry.nextOccurrence) {
                        Text(verbatim: "·")
                            .foregroundStyle(.tertiary)
                        Text("today.birthday.turning \(age)", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// Returns the age this person turns on `nextOccurrence`, or nil if
    /// the contact has no recorded birth year.
    private func computedAge(at next: Date) -> Int? {
        guard let birthYear = entry.contact.year else { return nil }
        let calendar = Calendar.autoupdatingCurrent
        let nextYear = calendar.component(.year, from: next)
        let age = nextYear - birthYear
        return age > 0 ? age : nil
    }
}
