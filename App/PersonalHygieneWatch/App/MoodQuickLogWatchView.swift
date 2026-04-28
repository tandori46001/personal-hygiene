import SwiftUI
import WatchKit

/// Round-21 slice T5.26: mirrors the iPhone Today screen's 5-emoji mood
/// quick-log onto the watch. Writes through `MoodLogStore` against the App
/// Group suite so iPhone + watch see the same log.
struct MoodQuickLogWatchView: View {

    @State private var todayMood: String?

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("watch.mood.title", bundle: .main)
                    .font(.headline)
                HStack(spacing: 4) {
                    ForEach(MoodLogStore.Mood.allCases, id: \.rawValue) { mood in
                        Button {
                            MoodLogStore.record(mood, in: sharedDefaults)
                            todayMood = MoodLogStore.todayEntry(defaults: sharedDefaults)?.mood
                            WKInterfaceDeviceWrap.success()
                        } label: {
                            Text(verbatim: mood.emoji)
                                .font(.title3)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 4)
                                .background(
                                    todayMood == mood.rawValue
                                        ? Color.accentColor.opacity(0.18)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("watch.mood.footer", bundle: .main)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(Text("watch.mood.title", bundle: .main))
        .onAppear {
            todayMood = MoodLogStore.todayEntry(defaults: sharedDefaults)?.mood
        }
    }
}

/// Indirection so the haptic call site reads the same on both flavours; the
/// wrap exists so future preview targets can stub it out without disturbing
/// the view body.
enum WKInterfaceDeviceWrap {
    static func success() {
        WKInterfaceDevice.current().play(.success)
    }
}
