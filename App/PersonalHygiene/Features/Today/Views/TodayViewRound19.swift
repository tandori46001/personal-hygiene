import SwiftUI

/// Round-19 Today wires:
/// - T5.19 `tomorrowSection`: collapsed disclosure listing tomorrow's blocks
///   (next-day template). Renders nothing when no template exists for the
///   target day-type.
/// - T5.20 `moodQuickLogSection`: 5-emoji single-tap row that records a
///   mood entry into `MoodLogStore`, highlighting the most-recent today
///   entry so the user sees their selection persist across navigation.
extension TodayView {

    @ViewBuilder
    var tomorrowSection: some View {
        let blocks = viewModel.tomorrowBlocks()
        if !blocks.isEmpty {
            Section {
                DisclosureGroup {
                    ForEach(blocks) { block in
                        HStack {
                            Text(verbatim: Self.formattedTime(minutes: block.startMinutesFromMidnight))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                            Text(verbatim: block.title)
                                .font(.callout)
                            Spacer()
                            Text(localizedKey: "category.\(block.category.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    HStack {
                        Image(systemName: "sun.haze")
                            .foregroundStyle(.secondary)
                        Text("today.tomorrow.title", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(blocks.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var moodQuickLogSection: some View {
        Section {
            HStack(spacing: 4) {
                ForEach(MoodLogStore.Mood.allCases, id: \.rawValue) { mood in
                    Button {
                        MoodLogStore.record(mood)
                    } label: {
                        Text(verbatim: mood.emoji)
                            .font(.title2)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(
                                MoodLogStore.todayEntry()?.mood == mood.rawValue
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(localizedKey: "today.mood.\(mood.rawValue)"))
                }
            }
            .frame(maxWidth: .infinity)
        } header: {
            Text("today.mood.title", bundle: .main)
        } footer: {
            Text("today.mood.footer", bundle: .main)
        }
    }

    static func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
