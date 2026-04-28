import SwiftUI

/// Round-25 slice T6.45: wrist-side mirror of the iPhone theme override.
/// Writes to the same shared `settings.theme` AppStorage key so a change
/// propagates back to the phone via the App Group suite (currently falls
/// back to local defaults until the entitlement ships).
struct WatchSettingsThemePicker: View {

    @AppStorage(
        "settings.theme",
        store: UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    )
    private var themeOverride: String = "system"

    var body: some View {
        Picker(selection: $themeOverride) {
            Text("settings.theme.system", bundle: .main).tag("system")
            Text("settings.theme.light", bundle: .main).tag("light")
            Text("settings.theme.dark", bundle: .main).tag("dark")
        } label: {
            Text("watch.settings.theme.title", bundle: .main)
        }
        .accessibilityLabel(Text("watch.settings.theme.title", bundle: .main))
    }
}
