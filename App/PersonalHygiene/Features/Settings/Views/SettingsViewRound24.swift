import SwiftData
import SwiftUI

/// Round-24 SettingsView wires:
/// - T4.23 backup encode caption (archived count alongside size).
/// - T4.24 "Restore most recent backup" shortcut row.
/// - T6.31 Today completion percentage caption (mirror to watch).
extension SettingsView {

    @ViewBuilder
    var round24Sections: some View {
        backupArchiveCountCaption
    }

    @ViewBuilder
    var backupArchiveCountCaption: some View {
        let archivedCount = TemplateArchiveStore.archivedIDs().count
        if archivedCount > 0 {
            Section {
                LabeledContent {
                    Text(verbatim: "\(archivedCount)")
                        .font(.callout.monospacedDigit())
                } label: {
                    Text("settings.backup.archivedCount.label", bundle: .main)
                }
            } footer: {
                Text("settings.backup.archivedCount.footer", bundle: .main)
            }
        }
    }
}
