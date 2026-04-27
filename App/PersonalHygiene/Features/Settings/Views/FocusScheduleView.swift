import SwiftUI

struct FocusScheduleView: View {

    let store: any FocusScheduleStore

    @State private var windows: [ScheduledFocusWindow] = []
    @State private var editingWindow: ScheduledFocusWindow?

    /// Round-12 slice 37: detect overlapping windows that share at least one
    /// weekday. Returns the set of conflicting IDs so we can highlight rows.
    private var conflictingIDs: Set<UUID> {
        var result: Set<UUID> = []
        for (idx, lhs) in windows.enumerated() {
            for rhs in windows.dropFirst(idx + 1) {
                let sharesDay = !lhs.weekdays.isDisjoint(with: rhs.weekdays)
                let overlapStart = max(lhs.startMinutesFromMidnight, rhs.startMinutesFromMidnight)
                let overlapEnd = min(lhs.endMinutesFromMidnight, rhs.endMinutesFromMidnight)
                if sharesDay, overlapStart < overlapEnd {
                    result.insert(lhs.id)
                    result.insert(rhs.id)
                }
            }
        }
        return result
    }

    var body: some View {
        List {
            // Round-12 slice 38: "Right now" 60-min window from current time.
            Section {
                Button {
                    let cal = Calendar.autoupdatingCurrent
                    let now = Date()
                    let startMin = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
                    let endMin = min(24 * 60 - 1, startMin + 60)
                    let weekday = cal.component(.weekday, from: now)
                    let window = ScheduledFocusWindow(
                        label: String(localized: "settings.focus.rightNow.label"),
                        weekdays: [weekday],
                        startMinutesFromMidnight: startMin,
                        endMinutesFromMidnight: endMin
                    )
                    store.upsert(window)
                    reload()
                } label: {
                    Label {
                        Text("settings.focus.rightNow", bundle: .main)
                    } icon: {
                        Image(systemName: "moon.zzz.fill")
                    }
                }
            }

            if !conflictingIDs.isEmpty {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text("settings.focus.conflict.warning", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            if windows.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("settings.focus.empty.title", bundle: .main)
                    } icon: {
                        Image(systemName: "moon.zzz")
                    }
                } description: {
                    Text("settings.focus.empty.description", bundle: .main)
                }
            } else {
                ForEach(windows) { window in
                    Button {
                        editingWindow = window
                    } label: {
                        FocusWindowRow(window: window)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteWindows)
            }
        }
        .navigationTitle(Text("settings.focus.title", bundle: .main))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingWindow = ScheduledFocusWindow(
                        label: "",
                        weekdays: [2, 3, 4, 5, 6],  // Mon-Fri
                        startMinutesFromMidnight: 22 * 60,
                        endMinutesFromMidnight: 23 * 60 + 30
                    )
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text("settings.focus.action.add", bundle: .main))
            }
        }
        .sheet(item: $editingWindow) { window in
            FocusScheduleEditor(
                window: window,
                onSave: { updated in
                    store.upsert(updated)
                    reload()
                },
                onDelete: {
                    store.delete(id: window.id)
                    reload()
                }
            )
        }
        .onAppear { reload() }
    }

    private func reload() {
        windows = store.windows()
    }

    private func deleteWindows(at offsets: IndexSet) {
        for idx in offsets {
            store.delete(id: windows[idx].id)
        }
        reload()
    }
}

private struct FocusWindowRow: View {
    let window: ScheduledFocusWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: window.label.isEmpty ? "—" : window.label)
                .font(.body)
            HStack(spacing: 6) {
                Text(startDate, format: .dateTime.hour().minute())
                Text(verbatim: "→")
                    .accessibilityHidden(true)
                Text(endDate, format: .dateTime.hour().minute())
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            Text(verbatim: weekdaySummary(window.weekdays))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedLabel)
    }

    private var startDate: Date {
        dateAt(minutes: window.startMinutesFromMidnight)
    }

    private var endDate: Date {
        dateAt(minutes: window.endMinutesFromMidnight)
    }

    private func dateAt(minutes: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        let dayStart = cal.startOfDay(for: Date())
        return cal.date(byAdding: .minute, value: minutes, to: dayStart) ?? dayStart
    }

    private var combinedLabel: Text {
        let title = window.label.isEmpty
            ? Text("settings.focus.row.untitled", bundle: .main)
            : Text(verbatim: window.label)
        let startStr = startDate.formatted(date: .omitted, time: .shortened)
        let endStr = endDate.formatted(date: .omitted, time: .shortened)
        let timeRange = Text(
            "settings.focus.row.timeRange \(startStr) \(endStr)",
            bundle: .main
        )
        let days = Text(verbatim: weekdaySummary(window.weekdays))
        return title + Text(verbatim: ", ") + timeRange + Text(verbatim: ", ") + days
    }

    private func weekdaySummary(_ weekdays: Set<Int>) -> String {
        let symbols = Calendar.autoupdatingCurrent.shortStandaloneWeekdaySymbols
        return weekdays.sorted().compactMap { day in
            guard day >= 1, day <= symbols.count else { return nil }
            return symbols[day - 1]
        }.joined(separator: " ")
    }
}

private struct FocusScheduleEditor: View {

    let window: ScheduledFocusWindow
    let onSave: (ScheduledFocusWindow) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var label: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var weekdays: Set<Int>

    init(
        window: ScheduledFocusWindow,
        onSave: @escaping (ScheduledFocusWindow) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.window = window
        self.onSave = onSave
        self.onDelete = onDelete
        let cal = Calendar.autoupdatingCurrent
        let dayStart = cal.startOfDay(for: Date())
        self._label = State(initialValue: window.label)
        self._weekdays = State(initialValue: window.weekdays)
        self._startDate = State(
            initialValue: cal.date(byAdding: .minute, value: window.startMinutesFromMidnight, to: dayStart) ?? dayStart
        )
        self._endDate = State(
            initialValue: cal.date(byAdding: .minute, value: window.endMinutesFromMidnight, to: dayStart) ?? dayStart
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $label,
                        prompt: Text("settings.focus.field.label.placeholder", bundle: .main)
                    ) {
                        Text("settings.focus.field.label", bundle: .main)
                    }
                }

                Section {
                    DatePicker(
                        selection: $startDate,
                        displayedComponents: .hourAndMinute
                    ) {
                        Text("settings.focus.field.start", bundle: .main)
                    }
                    DatePicker(
                        selection: $endDate,
                        displayedComponents: .hourAndMinute
                    ) {
                        Text("settings.focus.field.end", bundle: .main)
                    }
                }

                Section {
                    weekdayRow(1, key: "settings.focus.weekday.sun")
                    weekdayRow(2, key: "settings.focus.weekday.mon")
                    weekdayRow(3, key: "settings.focus.weekday.tue")
                    weekdayRow(4, key: "settings.focus.weekday.wed")
                    weekdayRow(5, key: "settings.focus.weekday.thu")
                    weekdayRow(6, key: "settings.focus.weekday.fri")
                    weekdayRow(7, key: "settings.focus.weekday.sat")
                } header: {
                    Text("settings.focus.field.weekdays", bundle: .main)
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Text("common.delete", bundle: .main)
                    }
                }
            }
            .navigationTitle(Text("settings.focus.editor.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(buildResult())
                        dismiss()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func weekdayRow(_ value: Int, key: String) -> some View {
        Toggle(isOn: Binding(
            get: { weekdays.contains(value) },
            set: { newValue in
                if newValue { weekdays.insert(value) } else { weekdays.remove(value) }
            }
        )) {
            Text(LocalizedStringKey(key), bundle: .main)
        }
    }

    private func buildResult() -> ScheduledFocusWindow {
        let cal = Calendar.autoupdatingCurrent
        let startMin = cal.component(.hour, from: startDate) * 60 + cal.component(.minute, from: startDate)
        let endMin = cal.component(.hour, from: endDate) * 60 + cal.component(.minute, from: endDate)
        return ScheduledFocusWindow(
            id: window.id,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            weekdays: weekdays,
            startMinutesFromMidnight: startMin,
            endMinutesFromMidnight: max(startMin, endMin)
        )
    }
}
