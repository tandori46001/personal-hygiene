import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Round-17 wires for `DiagnosticsView`: surfaces the `PendingNotificationsGroup`
/// classifier (round 14) by re-grouping the already-loaded `pendingDetails`
/// list into a category-keyed disclosure. This deepens the round-12
/// `PendingNotificationsByCategory` (counts only) into actual identifiers.
extension DiagnosticsView {

    @ViewBuilder
    var pendingByGroupSection: some View {
        if !pendingDetails.isEmpty {
            let grouped = PendingNotificationsGroup.grouped(pendingDetails.map(\.identifier))
            Section {
                DisclosureGroup(isExpanded: $pendingByGroupExpanded) {
                    ForEach(grouped, id: \.category) { entry in
                        DisclosureGroup {
                            ForEach(entry.identifiers, id: \.self) { identifier in
                                Button {
                                    UIPasteboard.general.string = identifier
                                } label: {
                                    HStack {
                                        Text(verbatim: identifier)
                                            .font(.caption2.monospaced())
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("settings.diagnostics.tapToCopy", bundle: .main))
                            }
                        } label: {
                            HStack {
                                let categoryKey = "settings.diagnostics.pendingByGroup.\(entry.category.rawValue)"
                                Text(LocalizedStringKey(categoryKey), bundle: .main)
                                Spacer()
                                Text(verbatim: "\(entry.identifiers.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("settings.diagnostics.section.pendingByGroup", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(grouped.reduce(0) { $0 + $1.identifiers.count })")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
