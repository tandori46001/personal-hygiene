import SwiftUI

/// "Now · HH:MM" hairline injected into the schedule list before the first
/// block whose start is in the future. Round 9 surface; extracted from
/// TodayView in round 11 to keep the main file under SwiftLint's file
/// length cap.
struct NowMarkerRow: View {
    let nowMinutes: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(formattedTime(minutes: nowMinutes))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.red)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(.red)
                .frame(height: 1)
            Text("today.now.line", bundle: .main)
                .font(.caption2.bold())
                .foregroundStyle(.red)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("today.now.line", bundle: .main))
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

/// Single row in the Today schedule list. Surfaces done/skip/snooze/focus
/// badges + tap-to-toggle done. `compact` hides the category dot, category
/// caption, and duration text — bound from `TodayView`'s `compactMode` toggle.
struct BlockTimelineRow: View {
    let block: Block
    let isDone: Bool
    let isSkipped: Bool
    let isSnoozedToday: Bool
    var compact: Bool = false
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isDone
                    ? Text("today.action.unmarkDone", bundle: .main)
                    : Text("today.action.markDone", bundle: .main)
            )
            .disabled(isSkipped)

            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel(spokenTime(minutes: block.startMinutesFromMidnight))
            if !compact {
                BlockCategoryDot(category: block.category)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(block.title)
                    .font(.body)
                    .strikethrough(isDone || isSkipped, color: .secondary)
                if !compact {
                    Text(localizedKey: "category.\(block.category.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isSnoozedToday {
                Image(systemName: "alarm")
                    .foregroundStyle(.blue)
                    .accessibilityLabel(Text("today.snoozedToday", bundle: .main))
            }
            if isSkipped {
                Image(systemName: "moon.zzz")
                    .foregroundStyle(.orange)
                    .accessibilityLabel(Text("today.action.skipToday", bundle: .main))
            }
            if block.isDeepFocus {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.purple)
                    .accessibilityLabel(Text("today.focus.deep", bundle: .main))
            }
            if !compact {
                Text(verbatim: "\(block.durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, compact ? 0 : 2)
        .opacity(isSkipped ? 0.6 : 1.0)
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func spokenTime(minutes: Int) -> Text {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        if let date = Calendar.autoupdatingCurrent.date(from: components) {
            return Text(date, format: .dateTime.hour().minute())
        }
        return Text(verbatim: formattedTime(minutes: minutes))
    }
}
