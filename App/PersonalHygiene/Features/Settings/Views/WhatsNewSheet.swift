import SwiftUI

/// Lists the most recent user-visible additions (widget, Siri shortcut,
/// notification controls). Reuses the onboarding tip strings so the wording
/// stays consistent between the welcome flow and the "What's new" entry.
struct WhatsNewSheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                tip(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "onboarding.tip.widget.title",
                    body: "onboarding.tip.widget.body"
                )
                tip(
                    systemImage: "mic.fill",
                    title: "onboarding.tip.siri.title",
                    body: "onboarding.tip.siri.body"
                )
                tip(
                    systemImage: "bell.badge.fill",
                    title: "onboarding.tip.notifications.title",
                    body: "onboarding.tip.notifications.body"
                )
            }
            .navigationTitle(Text("settings.about.whatsNew", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.done", bundle: .main)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tip(systemImage: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title, bundle: .main)
                    .font(.headline)
                Text(body, bundle: .main)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
