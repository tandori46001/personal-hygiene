import SwiftUI
import WatchKit

/// Round-23 slice T7 housekeeping: extracted from `ContentView.swift` so
/// the watch app file stays under SwiftLint's 500-line cap. Round-22 +
/// round-23 detail surface (toggle done/skip + optional skip-rest-of-day).
struct BlockDetailWatchView: View {
    let block: Block
    let isDone: Bool
    let isSkipped: Bool
    let onToggleDone: () -> Void
    let onToggleSkip: () -> Void
    /// Round-23 slice T5.29: optional cascade-skip from the wrist.
    var onSkipRestOfDay: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header
                Divider()
                actionButtons
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(Text("watch.detail.title", bundle: .main))
        .onDisappear {
            // Round-22 slice T6.34: light click haptic on swipe-back.
            WKInterfaceDevice.current().play(.click)
        }
    }

    @ViewBuilder
    private var header: some View {
        Text(block.title)
            .font(.headline)
        Label {
            Text(localizedKey: "category.\(block.category.rawValue)")
        } icon: {
            Image(systemName: "tag")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        Label {
            Text(verbatim: formattedTime(minutes: block.startMinutesFromMidnight))
                + Text(verbatim: " · \(block.durationMinutes) min")
        } icon: {
            Image(systemName: "clock")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button {
            onToggleDone()
            dismiss()
        } label: {
            Label {
                Text(isDone ? "today.action.unmarkDone" : "today.action.markDone", bundle: .main)
            } icon: {
                Image(systemName: isDone ? "arrow.uturn.backward" : "checkmark.circle")
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSkipped)

        Button(role: .destructive) {
            onToggleSkip()
            dismiss()
        } label: {
            Label {
                Text(isSkipped ? "today.action.unskipToday" : "today.action.skipToday", bundle: .main)
            } icon: {
                Image(systemName: "moon.zzz")
            }
        }
        .buttonStyle(.bordered)

        if let onSkipRestOfDay {
            Button(role: .destructive) {
                onSkipRestOfDay()
                dismiss()
            } label: {
                Label {
                    Text("today.action.skipRest", bundle: .main)
                } icon: {
                    Image(systemName: "forward.end")
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
