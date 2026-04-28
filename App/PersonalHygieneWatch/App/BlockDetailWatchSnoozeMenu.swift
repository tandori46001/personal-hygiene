import SwiftUI

/// Round-24 slice T6.30: 5/10/15-minute snooze menu surfaced from the
/// watch's BlockDetailWatchView. Hidden when no snooze callback is wired
/// (e.g. when the block isn't snoozable).
struct BlockDetailWatchSnoozeMenu: View {
    let onSnooze: (Int) -> Void

    var body: some View {
        Menu {
            ForEach([5, 10, 15], id: \.self) { minutes in
                Button {
                    onSnooze(minutes)
                } label: {
                    Text("watch.detail.snooze.minutes \(minutes)", bundle: .main)
                }
            }
        } label: {
            Label {
                Text("watch.detail.snooze.title", bundle: .main)
            } icon: {
                Image(systemName: "alarm")
            }
        }
        .buttonStyle(.bordered)
    }
}
