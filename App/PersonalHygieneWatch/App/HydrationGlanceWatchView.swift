import SwiftUI

/// Round-21 slice T5.25: glanceable hydration row on the watch. Reads
/// today's mL total from `WatchHydrationGlanceStore` (mirrored by iPhone)
/// and lets the user enqueue a pending tap from the wrist.
struct HydrationGlanceWatchView: View {

    @State private var total: Int = WatchHydrationGlanceStore.todayTotal()
    @State private var pending: [Int] = WatchHydrationGlanceStore.pendingTaps()

    var body: some View {
        List {
            Section {
                LabeledContent {
                    Text(verbatim: "\(total) ml")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.tint)
                } label: {
                    Text("watch.hydration.todayTotal", bundle: .main)
                }
                if !pending.isEmpty {
                    let totalPending = pending.reduce(0, +)
                    Text("watch.hydration.pending \(totalPending)", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.orange)
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
