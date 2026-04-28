import SwiftUI

/// Round-21 slice T5.25: glanceable hydration row on the watch. Reads
/// today's mL total from `WatchHydrationGlanceStore` (mirrored by iPhone)
/// and lets the user enqueue a pending tap from the wrist.
struct HydrationGlanceWatchView: View {

    @State private var total: Int = WatchHydrationGlanceStore.todayTotal()
    @State private var pending: [Int] = WatchHydrationGlanceStore.pendingTaps()
    /// Round-22 slice T6.31: hydration goal pulled from the iPhone via the
    /// shared App Group `@AppStorage("hydration.goal.ml")`.
    @AppStorage(
        "hydration.goal.ml",
        store: UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    )
    private var goalMilliliters: Int = HydrationGoal.default.dailyMilliliters

    private var progressFraction: Double {
        guard goalMilliliters > 0 else { return 0 }
        return min(1, Double(total) / Double(goalMilliliters))
    }

    var body: some View {
        List {
            Section {
                LabeledContent {
                    Text(verbatim: "\(total) / \(goalMilliliters) ml")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.tint)
                } label: {
                    Text("watch.hydration.todayTotal", bundle: .main)
                }
                ProgressView(value: progressFraction)
                    .tint(.tint)
                if !pending.isEmpty {
                    HStack {
                        let totalPending = pending.reduce(0, +)
                        Text("watch.hydration.pending \(totalPending)", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("watch.hydration.pending.count \(pending.count)", bundle: .main)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                    Button(role: .destructive) {
                        // Round-22 slice T6.30: clears pending taps from
                        // the wrist (e.g. after the user noticed they
                        // double-tapped). iPhone reconciliation skips the
                        // cleared queue on next foreground.
                        WatchHydrationGlanceStore.clearPending()
                        pending = []
                    } label: {
                        Label {
                            Text("watch.hydration.pending.clear", bundle: .main)
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
            } header: {
                Text("watch.hydration.title", bundle: .main)
            }

            Section {
                ForEach([150, 250, 330], id: \.self) { amount in
                    Button {
                        WatchHydrationGlanceStore.appendPendingTap(amountMl: amount)
                        pending = WatchHydrationGlanceStore.pendingTaps()
                    } label: {
                        Label {
                            Text(verbatim: "+\(amount) ml")
                        } icon: {
                            Image(systemName: "drop.fill")
                        }
                    }
                }
            } footer: {
                Text("watch.hydration.footer", bundle: .main)
            }
        }
        .navigationTitle(Text("watch.hydration.title", bundle: .main))
        .onAppear {
            total = WatchHydrationGlanceStore.todayTotal()
            pending = WatchHydrationGlanceStore.pendingTaps()
        }
    }
}
