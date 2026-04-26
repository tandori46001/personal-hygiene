import SwiftData
import SwiftUI
import WidgetKit

/// Bundle entry point for the iOS WidgetKit extension. iOS-side widgets are
/// kept separate from `PersonalHygieneWatchWidgets` because the supported
/// `WidgetFamily`s differ (system small/medium on iPhone, accessory* on
/// watchOS), even when both target the same "next block" data.
@main
struct PersonalHygieneWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextBlockHomeWidget()
        DeepFocusHomeWidget()
    }
}

struct NextBlockHomeWidget: Widget {
    let kind = "NextBlockHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextBlockHomeProvider()) { entry in
            NextBlockHomeView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("widget.nextBlock.title", bundle: .main))
        .description(Text("widget.nextBlock.description", bundle: .main))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextBlockHomeEntry: TimelineEntry {
    let date: Date
    let block: NextBlockHomeSnapshot?
}

struct NextBlockHomeSnapshot: Sendable, Hashable {
    let title: String
    let startMinutes: Int
    let category: String
    let isCurrent: Bool
}

struct NextBlockHomeProvider: TimelineProvider {

    private static let demoEntry = NextBlockHomeEntry(
        date: Date(),
        block: NextBlockHomeSnapshot(
            title: "Aseo",
            startMinutes: 7 * 60,
            category: "hygiene",
            isCurrent: false
        )
    )

    func placeholder(in _: Context) -> NextBlockHomeEntry { Self.demoEntry }

    func getSnapshot(in _: Context, completion: @escaping (NextBlockHomeEntry) -> Void) {
        completion(Self.demoEntry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<NextBlockHomeEntry>) -> Void) {
        let now = Date()
        let snapshot = Self.fetchSnapshot(now: now)
        let entry = NextBlockHomeEntry(date: now, block: snapshot)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private static func fetchSnapshot(now: Date) -> NextBlockHomeSnapshot? {
        // Build a fresh `ModelContainer` + `ModelContext` directly here so we
        // don't have to cross into the @MainActor-isolated repository wrapper
        // from the (non-isolated) `TimelineProvider` callback queue.
        let configuration = ModelConfiguration(
            schema: AppModelContainer.schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        guard
            let container = try? ModelContainer(
                for: AppModelContainer.schema,
                configurations: [configuration]
            )
        else { return nil }
        let context = ModelContext(container)
        let weekday = Calendar.autoupdatingCurrent.component(.weekday, from: now)
        let dayType: DayType = (weekday == 1 || weekday == 7) ? .weekend : .weekday
        let descriptor = FetchDescriptor<RoutineTemplate>()
        guard let templates = try? context.fetch(descriptor) else { return nil }
        let active = templates.first { $0.isActive && $0.dayType == dayType }
        guard let template = active else { return nil }
        guard let resolved = NextBlockResolver.resolve(in: template, at: now) else { return nil }
        return NextBlockHomeSnapshot(
            title: resolved.block.title,
            startMinutes: resolved.startMinutesFromMidnight,
            category: resolved.block.category.rawValue,
            isCurrent: resolved.isCurrent
        )
    }
}

struct NextBlockHomeView: View {

    let entry: NextBlockHomeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let block = entry.block {
            switch family {
            case .systemSmall: smallView(for: block)
            default: mediumView(for: block)
            }
        } else {
            ContentUnavailableView {
                Label {
                    Text("widget.nextBlock.empty.title", bundle: .main)
                } icon: {
                    Image(systemName: "calendar")
                }
            }
        }
    }

    @ViewBuilder
    private func smallView(for block: NextBlockHomeSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.isCurrent ? "today.now" : "today.next", bundle: .main)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(formattedTime(minutes: block.startMinutes))
                .font(.system(.title, design: .monospaced))
                .bold()
            Text(block.title)
                .font(.caption)
                .lineLimit(2)
            Text(LocalizedStringKey("category.\(block.category)"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func mediumView(for block: NextBlockHomeSnapshot) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.isCurrent ? "today.now" : "today.next", bundle: .main)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formattedTime(minutes: block.startMinutes))
                    .font(.system(.largeTitle, design: .monospaced))
                    .bold()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(LocalizedStringKey("category.\(block.category)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

// MARK: - Deep Focus widget (small)

struct DeepFocusHomeWidget: Widget {
    let kind = "DeepFocusHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeepFocusHomeProvider()) { entry in
            DeepFocusHomeView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("widget.deepFocus.title", bundle: .main))
        .description(Text("widget.deepFocus.description", bundle: .main))
        .supportedFamilies([.systemSmall])
    }
}

struct DeepFocusHomeEntry: TimelineEntry {
    let date: Date
    let state: DeepFocusHomeSnapshot
}

enum DeepFocusHomeSnapshot: Sendable, Hashable {
    case active(title: String, endMinutes: Int)
    case upcoming(startMinutes: Int)
    case idle
}

struct DeepFocusHomeProvider: TimelineProvider {

    func placeholder(in _: Context) -> DeepFocusHomeEntry {
        DeepFocusHomeEntry(date: Date(), state: .idle)
    }

    func getSnapshot(in _: Context, completion: @escaping (DeepFocusHomeEntry) -> Void) {
        completion(DeepFocusHomeEntry(date: Date(), state: .idle))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<DeepFocusHomeEntry>) -> Void) {
        let now = Date()
        let snapshot = Self.fetchSnapshot(now: now)
        let entry = DeepFocusHomeEntry(date: now, state: snapshot)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private static func fetchSnapshot(now: Date) -> DeepFocusHomeSnapshot {
        let calendar = Calendar.autoupdatingCurrent
        let configuration = ModelConfiguration(
            schema: AppModelContainer.schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        guard
            let container = try? ModelContainer(
                for: AppModelContainer.schema,
                configurations: [configuration]
            )
        else { return .idle }
        let context = ModelContext(container)
        let weekday = calendar.component(.weekday, from: now)
        let dayType: DayType = (weekday == 1 || weekday == 7) ? .weekend : .weekday
        guard let templates = try? context.fetch(FetchDescriptor<RoutineTemplate>()) else {
            return .idle
        }
        guard let template = templates.first(where: { $0.isActive && $0.dayType == dayType }) else {
            return .idle
        }

        let scheduledStore = UserDefaultsFocusScheduleStore()
        let scheduled = scheduledStore.windows()
        if let active = DeepFocusFilter.activeWindow(
            at: now,
            in: template.sortedBlocks,
            scheduledWindows: scheduled,
            calendar: calendar
        ) {
            let endMinutes = calendar.component(.hour, from: active.end) * 60
                + calendar.component(.minute, from: active.end)
            return .active(title: active.blockTitle, endMinutes: endMinutes)
        }

        // No active window — surface the *next* deep-focus block start, if any.
        let nowMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)
        if let next = template.sortedBlocks.first(where: {
            $0.isDeepFocus && $0.startMinutesFromMidnight > nowMinutes
        }) {
            return .upcoming(startMinutes: next.startMinutesFromMidnight)
        }
        return .idle
    }
}

struct DeepFocusHomeView: View {

    let entry: DeepFocusHomeEntry

    var body: some View {
        switch entry.state {
        case .active(let title, let endMinutes):
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("widget.deepFocus.active", bundle: .main)
                        .font(.caption2)
                } icon: {
                    Image(systemName: "moon.zzz.fill")
                }
                .foregroundStyle(.purple)
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                Text(LocalizedStringResource("widget.deepFocus.until \(formattedTime(minutes: endMinutes))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .upcoming(let startMinutes):
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("widget.deepFocus.upcoming", bundle: .main)
                        .font(.caption2)
                } icon: {
                    Image(systemName: "moon.zzz")
                }
                .foregroundStyle(.secondary)
                Text(formattedTime(minutes: startMinutes))
                    .font(.system(.title, design: .monospaced))
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .idle:
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("widget.deepFocus.idle", bundle: .main)
                        .font(.caption2)
                } icon: {
                    Image(systemName: "moon.zzz")
                }
                .foregroundStyle(.secondary)
                Text("widget.deepFocus.idle.description", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
