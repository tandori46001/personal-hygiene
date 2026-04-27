import SwiftUI

/// Round-12 SettingsView sections (mute toggles, pause, theme, marine TTL).
/// Hosted in an extension to keep the main `SettingsView` body under the
/// SwiftLint type-body cap.
extension SettingsView {

    @ViewBuilder
    var categoryMuteSection: some View {
        Section {
            ForEach(NotificationCategoryMuteStore.Category.allCases, id: \.self) { cat in
                Toggle(
                    isOn: Binding(
                        get: { !NotificationCategoryMuteStore.isMuted(cat) },
                        set: { NotificationCategoryMuteStore.setMuted(!$0, for: cat) }
                    )
                ) {
                    Text(LocalizedStringKey("settings.mute.\(cat.rawValue)"), bundle: .main)
                }
            }
        } header: {
            Text("settings.section.mute", bundle: .main)
        } footer: {
            Text("settings.section.mute.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var pauseSection: some View {
        Section {
            if let until = PauseNotificationsStore.pausedUntil(),
               PauseNotificationsStore.isPaused() {
                pauseActiveRow(until: until)
            } else {
                pauseMenu
            }
        } header: {
            Text("settings.section.pause", bundle: .main)
        } footer: {
            Text("settings.section.pause.footer", bundle: .main)
        }
    }

    @ViewBuilder
    private func pauseActiveRow(until: Date) -> some View {
        HStack {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(
                "settings.pause.activeUntil \(until.formatted(date: .abbreviated, time: .shortened))",
                bundle: .main
            )
            .font(.caption)
            Spacer()
            Button {
                PauseNotificationsStore.clear()
            } label: {
                Text("settings.pause.resume", bundle: .main)
            }
            .buttonStyle(.bordered)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var pauseMenu: some View {
        Menu {
            Button {
                PauseNotificationsStore.pauseForHours(1)
            } label: {
                Text("settings.pause.choice.1h", bundle: .main)
            }
            Button {
                PauseNotificationsStore.pauseForHours(4)
            } label: {
                Text("settings.pause.choice.4h", bundle: .main)
            }
            Button {
                PauseNotificationsStore.pauseForHours(24)
            } label: {
                Text("settings.pause.choice.24h", bundle: .main)
            }
        } label: {
            Label {
                Text("settings.pause.action", bundle: .main)
            } icon: {
                Image(systemName: "pause.circle")
            }
        }
    }

    @ViewBuilder
    var themeSection: some View {
        Section {
            Picker(selection: $themeOverride) {
                Text("settings.theme.system", bundle: .main).tag("system")
                Text("settings.theme.light", bundle: .main).tag("light")
                Text("settings.theme.dark", bundle: .main).tag("dark")
            } label: {
                Text("settings.theme.label", bundle: .main)
            }
            Picker(selection: $marineHours) {
                ForEach(MarineForecastFreshnessStore.allowedHours, id: \.self) { hours in
                    Text(LocalizedStringResource("settings.marine.freshness.\(hours)"))
                        .tag(hours)
                }
            } label: {
                Text("settings.marine.freshness.label", bundle: .main)
            }
        } header: {
            Text("settings.section.appearance", bundle: .main)
        }
    }
}
