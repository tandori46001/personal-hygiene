import SwiftData
import SwiftUI
import WidgetKit

/// Bundle entry point for all watch complications shipped by personal-hygiene.
@main
struct PersonalHygieneWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextBlockComplication()
    }
}

/// Compact glanceable complication that shows the next scheduled block of the
/// day with its start time. Uses the shared `RoutineRepository` to read the
/// active template for today.
struct NextBlockComplication: Widget {
    let kind = "NextBlockComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextBlockProvider()) { entry in
            NextBlockEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("watch.complication.next.title", bundle: .main))
        .description(Text("watch.complication.next.description", bundle: .main))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct NextBlockEntry: TimelineEntry {
    let date: Date
    let block: NextBlockSnapshot?
}

/// Plain-Sendable snapshot of the relevant fields of a `Block`. Avoids
/// crossing actor boundaries with the `@Model` instance.
struct NextBlockSnapshot: Sendable, Hashable {
    let title: String
    let startMinutes: Int
    /// `true` when a Deep Focus window is active right now (block-derived OR
    /// scheduled). The complication shows a small `moon.zzz.fill` glyph when
    /// this is true so the wearer knows non-critical alerts are suppressed.
    var isFocusActive: Bool = false
}

struct NextBlockProvider: TimelineProvider {

    func placeholder(in _: Context) -> NextBlockEntry {
        NextBlockEntry(
            date: Date(),
            block: NextBlockSnapshot(title: "Aseo", startMinutes: 7 * 60)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextBlockEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<NextBlockEntry>) -> Void) {
        let now = Date()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        Task { @MainActor in
            let snapshot = Self.fetchNextBlockSnapshot(now: now)
            let entry = NextBlockEntry(date: now, block: snapshot)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    @MainActor
    private static func fetchNextBlockSnapshot(now: Date) -> NextBlockSnapshot? {
        guard let container = try? AppModelContainer.makeProduction() else { return nil }
        let context = ModelContext(container)
        let repository = SwiftDataRoutineRepository(context: context)
        let dayType = TodayViewModel.dayType(for: now, in: .autoupdatingCurrent)
        guard let template = try? repository.activeTemplate(for: dayType) else { return nil }
        let nowMinutes =
            Calendar.current.component(.hour, from: now) * 60
            + Calendar.current.component(.minute, from: now)
        guard let next = template.sortedBlocks.first(where: { $0.startMinutesFromMidnight > nowMinutes }) else {
            return nil
        }
        let scheduled = UserDefaultsFocusScheduleStore.appGroupOrStandard().windows()
        let focusActive = DeepFocusFilter.isFocusActive(
            at: now,
            in: template.sortedBlocks,
            scheduledWindows: scheduled,
            calendar: .autoupdatingCurrent
        )
        return NextBlockSnapshot(
            title: next.title,
            startMinutes: next.startMinutesFromMidnight,
            isFocusActive: focusActive
        )
    }
}

struct NextBlockEntryView: View {
    let entry: NextBlockEntry

    var body: some View {
        if let block = entry.block {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(formattedTime(minutes: block.startMinutes))
                        .font(.system(.headline, design: .monospaced))
                    if block.isFocusActive {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(.purple)
                            .font(.caption2)
                            .accessibilityHidden(true)
                    }
                }
                Text(block.title)
                    .font(.caption)
                    .lineLimit(2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(verbatim: voiceOverPhrase(for: block)))
        } else {
            Text("watch.complication.next.empty", bundle: .main)
                .font(.caption)
        }
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// Reuses the iOS Siri dialog phrasing so "next block" reads identically
    /// across the watch complication and Siri shortcut.
    private func voiceOverPhrase(for block: NextBlockSnapshot) -> String {
        let format = String(localized: "intent.whatsNext.upcoming.format")
        return String(format: format, block.title, formattedTime(minutes: block.startMinutes))
    }
}
