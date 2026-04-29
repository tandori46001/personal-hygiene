import SwiftData
import SwiftUI

/// Round 27 WS-B B7: Settings page where the user toggles seeded
/// important days on/off and adds custom ones (wedding anniversary,
/// saint's day, family milestones, etc.).
struct ImportantDaysSettingsView: View {

    @Query(sort: [SortDescriptor(\ImportantDay.name)]) private var allDays: [ImportantDay]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddSheet = false

    var body: some View {
        Form {
            if !customDays.isEmpty {
                Section {
                    ForEach(customDays) { day in
                        row(for: day)
                    }
                    .onDelete { offsets in
                        delete(in: customDays, at: offsets)
                    }
                } header: {
                    Text("settings.importantDays.section.custom", bundle: .main)
                }
            }
            if !seededDays.isEmpty {
                Section {
                    ForEach(seededDays) { day in
                        row(for: day)
                    }
                } header: {
                    Text("settings.importantDays.section.seeded", bundle: .main)
                }
            }
        }
        .navigationTitle(Text("settings.importantDays.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label {
                        Text("settings.importantDays.add", bundle: .main)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddImportantDaySheet { name, rule in
                let day = ImportantDay(
                    name: name,
                    dayRule: rule,
                    localeRegion: nil,
                    enabled: true,
                    isCustom: true
                )
                modelContext.insert(day)
                try? modelContext.save()
            }
        }
    }

    private var customDays: [ImportantDay] {
        allDays.filter(\.isCustom)
    }

    private var seededDays: [ImportantDay] {
        allDays.filter { !$0.isCustom }
    }

    @ViewBuilder
    private func row(for day: ImportantDay) -> some View {
        let toggle = Binding<Bool>(
            get: { day.enabled },
            set: { newValue in
                day.enabled = newValue
                try? modelContext.save()
            }
        )
        Toggle(isOn: toggle) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: day.name)
                if let rule = day.dayRule {
                    Text(verbatim: AddImportantDaySheet.summary(for: rule))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func delete(in source: [ImportantDay], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(source[index])
        }
        try? modelContext.save()
    }
}

/// Round 27 WS-B B7 sub-sheet: form for adding either a fixed-month-day
/// rule or an anniversary (year + month + day). Keeps the surface
/// minimal — the seeded set covers nth-weekday rules; user-added
/// anniversaries default to fixed.
struct AddImportantDaySheet: View {

    let onSave: (String, DayRule) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var includeYear = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $name,
                        prompt: Text("settings.importantDays.add.name.placeholder", bundle: .main)
                    ) {
                        Text("settings.importantDays.add.name", bundle: .main)
                    }
                }
                Section {
                    DismissingDatePicker(selection: $date) {
                        Text("settings.importantDays.add.date", bundle: .main)
                    }
                    Toggle(isOn: $includeYear) {
                        Text("settings.importantDays.add.includeYear", bundle: .main)
                    }
                } footer: {
                    Text("settings.importantDays.add.footer", bundle: .main)
                }
            }
            .navigationTitle(Text("settings.importantDays.add.title", bundle: .main))
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
                        let rule = makeRule()
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), rule)
                        dismiss()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func makeRule() -> DayRule {
        let calendar = Calendar.autoupdatingCurrent
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        if includeYear, let year = comps.year {
            return .anniversary(year: year, month: month, day: day)
        }
        return .fixedMonthDay(month: month, day: day)
    }

    /// Human-readable, locale-aware summary of a `DayRule` for display
    /// in the settings list. Used by the row above + reused in tests.
    static func summary(for rule: DayRule) -> String {
        let calendar = Calendar.autoupdatingCurrent
        switch rule {
        case .fixedMonthDay(let month, let day):
            var comps = DateComponents()
            comps.year = 2024
            comps.month = month
            comps.day = day
            if let date = calendar.date(from: comps) {
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("MMMd")
                return formatter.string(from: date)
            }
            return "\(month)/\(day)"
        case .nthWeekdayOfMonth(let nth, let weekday, let month):
            return Self.formattedNth(nth: nth, weekday: weekday, month: month, calendar: calendar)
        case .lastWeekdayOfMonth(let weekday, let month):
            return Self.formattedLast(weekday: weekday, month: month, calendar: calendar)
        case .anniversary(let year, let month, let day):
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            if let date = calendar.date(from: comps) {
                return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
            }
            return "\(year)-\(month)-\(day)"
        }
    }

    private static func formattedNth(nth: Int, weekday: Int, month: Int, calendar: Calendar) -> String {
        let weekdayName = calendar.weekdaySymbols[max(0, min(6, weekday - 1))]
        let monthName = calendar.monthSymbols[max(0, min(11, month - 1))]
        return "\(nth)·\(weekdayName) — \(monthName)"
    }

    private static func formattedLast(weekday: Int, month: Int, calendar: Calendar) -> String {
        let weekdayName = calendar.weekdaySymbols[max(0, min(6, weekday - 1))]
        let monthName = calendar.monthSymbols[max(0, min(11, month - 1))]
        return "✕·\(weekdayName) — \(monthName)"
    }
}
