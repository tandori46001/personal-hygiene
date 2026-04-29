import SwiftData
import SwiftUI

/// Round-26 SettingsView wires the **Reset all data** destructive action.
/// Lives at the bottom of Settings, gated behind a confirm dialog. Wipes
/// SwiftData + UserDefaults state via `FullDataResetter.resetEverything`,
/// leaving onboarding flag + theme preference untouched.
extension SettingsView {

    @ViewBuilder
    var round26ResetAllDataRow: some View {
        ResetAllDataButton()
    }
}

private struct ResetAllDataButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingConfirm = false
    @State private var resetError: String?

    var body: some View {
        Section {
            Button(role: .destructive) {
                showingConfirm = true
            } label: {
                Label {
                    Text("settings.data.resetAll", bundle: .main)
                } icon: {
                    Image(systemName: "trash.circle")
                }
            }
            if let resetError {
                Text(verbatim: resetError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("settings.data.resetAll.footer", bundle: .main)
        }
        .confirmationDialog(
            Text("settings.data.resetAll.confirm.title", bundle: .main),
            isPresented: $showingConfirm,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                do {
                    try FullDataResetter.resetEverything(in: modelContext)
                    resetError = nil
                } catch {
                    resetError = error.localizedDescription
                }
            } label: {
                Text("settings.data.resetAll.confirm.button", bundle: .main)
            }
            Button(role: .cancel) {} label: {
                Text("common.cancel", bundle: .main)
            }
        } message: {
            Text("settings.data.resetAll.confirm.message", bundle: .main)
        }
    }
}
