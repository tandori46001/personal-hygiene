import SwiftUI

/// Round-24 slice T6.30: 5/10/15-minute snooze surface for the watch's
/// BlockDetailWatchView. WatchOS doesn't ship `Menu`, so the picks render
/// as a vertical stack of buttons. Hidden when no snooze callback is
/// wired (e.g. when the block isn't snoozable).
struct BlockDetailWatchSnoozeMenu: View {
    let onSnooze: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text("watch.detail.snooze.title", bundle: .main)
            } icon: {
                Image(systemName: "alarm")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach([5, 10, 15], id: \.self) { minutes in
                Button {
                    onSnooze(minutes)
                } label: {
                    Text("watch.detail.snooze.minutes \(minutes)", bundle: .main)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
