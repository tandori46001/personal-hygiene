import SwiftUI

/// Round-17 SettingsView wires: surface UIs for stores that landed in
/// rounds 13-14 without a settings entry — quiet hours (round 14) and the
/// backup auto-frequency picker (round 13). Each is rendered as a normal
/// `Section` and is hooked into `SettingsView.body` from the round-17 patch.
extension SettingsView {

    @ViewBuilder
    var quietHoursSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { QuietHoursStore.isEnabled() },
                set: { QuietHoursStore.setEnabled($0) }
            )) {
                Text("settings.quietHours.toggle", bundle: .main)
            }

            if QuietHoursStore.isEnabled() {
                quietHoursStartRow
                quietHoursEndRow
                Button(role: .destructive) {
                    QuietHoursStore.setStartMinutes(QuietHoursStore.defaultStartMinutes)
                    QuietHoursStore.setEndMinutes(QuietHoursStore.defaultEndMinutes)
                    QuietHoursStore.setEnabled(false)
                } label: {
                    Label {
                        Text("settings.quietHours.reset", bundle: .main)
                    } icon: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
        } header: {
            Text("settings.section.quietHours", bundle: .main)
        } footer: {
            Text("settings.section.quietHours.footer", bundle: .main)
        }
    }

    @ViewBuilder
    private var quietHoursStartRow: some View {
        DatePicker(
            selection: Binding(
                get: { Self.dateFromMinutes(QuietHoursStore.startMinutes()) },
                set: { QuietHoursStore.setStartMinutes(Self.minutesFromDate($0)) }
            ),
            displayedComponents: .hourAndMinute
        ) {
            Text("settings.quietHours.start", bundle: .main)
        }
    }

    @ViewBuilder
    private var quietHoursEndRow: some View {
        DatePicker(
            selection: Binding(
                get: { Self.dateFromMinutes(QuietHoursStore.endMinutes()) },
                set: { QuietHoursStore.setEndMinutes(Self.minutesFromDate($0)) }
            ),
            displayedComponents: .hourAndMinute
        ) {
            Text("settings.quietHours.end", bundle: .main)
        }
    }

    @ViewBuilder
    var backupAutoFrequencySection: some View {
        Section {
            Picker(
                selection: Binding(
                    get: { BackupAutoFrequencyStore.current() },
                    set: { BackupAutoFrequencyStore.set($0) }
                )
            ) {
                ForEach(BackupAutoFrequencyStore.Frequency.allCases, id: \.self) { freq in
                    Text(localizedKey: "settings.backup.autoFrequency.\(freq.rawValue)")
                        .tag(freq)
                }
            } label: {
                Text("settings.backup.autoFrequency.label", bundle: .main)
            }
        } header: {
            Text("settings.section.backup.autoFrequency", bundle: .main)
        } footer: {
            Text("settings.section.backup.autoFrequency.footer", bundle: .main)
        }
    }

    private static func dateFromMinutes(_ minutes: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        let dayStart = cal.startOfDay(for: Date())
        return cal.date(byAdding: .minute, value: minutes, to: dayStart) ?? dayStart
    }

    private static func minutesFromDate(_ date: Date) -> Int {
        let cal = Calendar.autoupdatingCurrent
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }
}
