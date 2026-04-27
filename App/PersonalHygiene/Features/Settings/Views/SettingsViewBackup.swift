import SwiftUI

/// Backup/restore section of SettingsView, factored out into an extension to
/// keep the main view's struct body under the SwiftLint type-body-length cap.
extension SettingsView {

    @ViewBuilder
    var backupSection: some View {
        Section {
            Button {
                exportBackup()
            } label: {
                Label {
                    Text("settings.backup.action.export", bundle: .main)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            Button(role: .destructive) {
                showingImporter = true
            } label: {
                Label {
                    Text("settings.backup.action.import", bundle: .main)
                } icon: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            if let backupError {
                Text(verbatim: backupError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("settings.section.backup", bundle: .main)
        } footer: {
            Text("settings.section.backup.footer", bundle: .main)
        }
    }
}
