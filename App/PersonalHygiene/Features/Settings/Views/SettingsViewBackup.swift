import SwiftUI

/// Backup/restore section of SettingsView, factored out into an extension to
/// keep the main view's struct body under the SwiftLint type-body-length cap.
extension SettingsView {

    @ViewBuilder
    var aboutSection: some View {
        Section {
            Button {
                showingWhatsNew = true
            } label: {
                Label {
                    Text("settings.about.whatsNew", bundle: .main)
                } icon: {
                    Image(systemName: "sparkles")
                }
            }
            Button {
                showingOnboardingRestartConfirm = true
            } label: {
                Label {
                    Text("settings.onboarding.restart", bundle: .main)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            Button(role: .destructive) {
                showingResetCustomizationsConfirm = true
            } label: {
                Label {
                    Text("settings.reset.allCustomizations", bundle: .main)
                } icon: {
                    Image(systemName: "arrow.counterclockwise.circle")
                }
            }
            if let diagnosticsActions {
                NavigationLink {
                    DiagnosticsView(viewModel: viewModel, actions: diagnosticsActions)
                } label: {
                    Label {
                        Text("settings.diagnostics.title", bundle: .main)
                    } icon: {
                        Image(systemName: "stethoscope")
                    }
                }
            }
        } header: {
            Text("settings.section.about", bundle: .main)
        } footer: {
            Text(verbatim: BuildInfo.shortDescriptor)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

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
