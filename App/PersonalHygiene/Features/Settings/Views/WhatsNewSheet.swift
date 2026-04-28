import SwiftUI

/// Lists the most recent user-visible additions (widget, Siri shortcut,
/// notification controls). Reuses the onboarding tip strings so the wording
/// stays consistent between the welcome flow and the "What's new" entry.
struct WhatsNewSheet: View {

    @Environment(\.dismiss) private var dismiss
    /// Round-20 slice T5.23: track whether the user has scrolled to the
    /// bottom of the tip list. If they tap Done before scrolling, surface
    /// a confirm dialog so an accidental dismiss doesn't hide release notes
    /// the user hasn't read.
    @State private var hasReachedBottom = false
    @State private var showingDismissConfirm = false

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
                .onAppear { hasReachedBottom = true }
            }
            .navigationTitle(Text("settings.about.whatsNew", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if hasReachedBottom {
                            dismiss()
                        } else {
                            showingDismissConfirm = true
                        }
                    } label: {
                        Text("common.done", bundle: .main)
                    }
                }
            }
            .confirmationDialog(
                Text("whatsNew.dismiss.confirm.title", bundle: .main),
                isPresented: $showingDismissConfirm,
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    dismiss()
                } label: {
                    Text("whatsNew.dismiss.confirm.action", bundle: .main)
                }
                Button(role: .cancel) {} label: {
                    Text("common.cancel", bundle: .main)
                }
            } message: {
                Text("whatsNew.dismiss.confirm.message", bundle: .main)
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
