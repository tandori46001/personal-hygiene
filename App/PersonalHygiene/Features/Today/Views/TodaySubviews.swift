import SwiftUI

/// Subviews extracted from `TodayView` to keep that file under SwiftLint's
/// 500-line file-length cap after round-12 added context menu, category
/// filter, reset-day, and toast surfaces.
struct ProgressDetailSheet: View {

    let blocks: [Block]
    let isDone: (Block) -> Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(blocks) { block in
                HStack {
                    Image(systemName: isDone(block) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isDone(block) ? Color.green : Color.secondary)
                        .accessibilityHidden(true)
                    Text(block.title)
                        .strikethrough(isDone(block), color: .secondary)
                        .foregroundStyle(isDone(block) ? .secondary : .primary)
                    Spacer()
                    Text(formattedTime(minutes: block.startMinutesFromMidnight))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .navigationTitle(Text("today.summary.detail.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.done", bundle: .main)
                    }
                }
            }
        }
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

struct TripCountdownRow: View {
    let trip: Trip
    let daysUntil: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.name)
                    .font(.headline)
                if daysUntil == 0 {
                    Text("today.trip.departingToday", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("today.trip.daysUntil.\(daysUntil)", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(verbatim: trip.destinationName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ProgressSummaryRow: View {
    let done: Int
    let total: Int
    let nextBlock: Block?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: done == total ? "checkmark.circle.fill" : "circle.dotted")
                .foregroundStyle(done == total ? Color.green : Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("today.summary.title.\(done).\(total)", bundle: .main)
                    .font(.headline)
                ProgressView(value: Double(done), total: Double(max(total, 1)))
                    .progressViewStyle(.linear)
                if let nextBlock {
                    Text(
                        "today.summary.nextPreview \(formattedTime(nextBlock)) \(nextBlock.title)",
                        bundle: .main
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                } else {
                    Text("today.summary.dayDone", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedTime(_ block: Block) -> String {
        let hour = block.startMinutesFromMidnight / 60
        let minute = block.startMinutesFromMidnight % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct FocusActiveBanner: View {
    let window: DeepFocusFilter.FocusWindow

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.purple)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("today.focus.active", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(window.blockTitle)
                    .font(.headline)
            }
            Spacer()
            Text(window.end, format: .dateTime.hour().minute())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct BlockNowRow: View {
    let block: Block
    let label: Text
    let minutesUntilStart: Int?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                label
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(block.title)
                    .font(.title3)
                    .bold()
                Text(LocalizedStringKey("category.\(block.category.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let until = minutesUntilStart {
                    Text(Self.untilCaption(minutes: until), bundle: .main)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                }
            }
            Spacer()
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.title2, design: .monospaced))
                .accessibilityLabel(spokenTime(minutes: block.startMinutesFromMidnight))
        }
        .accessibilityElement(children: .combine)
    }

    /// Round-11: human-friendly "in N min" / "in 1h N min" / "now" caption
    /// for the upcoming block. Returns a localization key with `%lld` slots
    /// so EN/ES/FR formats can vary independently.
    static func untilCaption(minutes: Int) -> LocalizedStringKey {
        if minutes <= 0 { return "today.next.startingNow" }
        if minutes < 60 { return "today.next.inMinutes.\(minutes)" }
        let hours = minutes / 60
        let rem = minutes % 60
        if rem == 0 { return "today.next.inHours.\(hours)" }
        return "today.next.inHoursAndMinutes \(hours) \(rem)"
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func spokenTime(minutes: Int) -> Text {
        let hour = minutes / 60
        let minute = minutes % 60
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = Calendar.autoupdatingCurrent.date(from: components) {
            return Text(date, format: .dateTime.hour().minute())
        }
        return Text(verbatim: formattedTime(minutes: minutes))
    }
}
