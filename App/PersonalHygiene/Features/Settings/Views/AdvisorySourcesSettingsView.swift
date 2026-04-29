import SwiftUI

/// Round 27 follow-up: Settings page where the user reorders the
/// travel-advisory sources used by trip-detail's multi-source advisory
/// section. Drag-to-reorder via SwiftUI's edit-mode + `.onMove`.
/// Backed by `AdvisoryOrderStore` (UserDefaults).
struct AdvisorySourcesSettingsView: View {

    @State private var order: [AdvisorySource] = AdvisoryOrderStore.currentOrder()
    @State private var editMode: EditMode = .active

    var body: some View {
        List {
            Section {
                ForEach(order) { source in
                    HStack(spacing: 12) {
                        Text(verbatim: flag(for: source))
                            .font(.title2)
                        Text(localizedKey: "settings.advisory.source.\(source.shortKey)")
                    }
                }
                .onMove(perform: move)
            } header: {
                Text("settings.advisory.sources.header", bundle: .main)
            } footer: {
                Text("settings.advisory.sources.footer", bundle: .main)
            }

            Section {
                Button(role: .destructive) {
                    AdvisoryOrderStore.reset()
                    order = AdvisoryOrderStore.defaultOrder
                } label: {
                    Label {
                        Text("settings.advisory.sources.reset", bundle: .main)
                    } icon: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
        }
        .navigationTitle(Text("settings.advisory.sources.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
    }

    private func move(from source: IndexSet, to destination: Int) {
        order.move(fromOffsets: source, toOffset: destination)
        AdvisoryOrderStore.setOrder(order)
    }

    private func flag(for source: AdvisorySource) -> String {
        switch source {
        case .stateDept: return "🇺🇸"
        case .canada: return "🇨🇦"
        case .ukFCDO: return "🇬🇧"
        case .australia: return "🇦🇺"
        case .exteriores: return "🇪🇸"
        }
    }
}

extension AdvisorySource {
    /// Short i18n-friendly key — independent of the persisted rawValue
    /// (which encodes a domain-style identifier). The xcstrings keys
    /// `settings.advisory.source.us` / `.canada` / etc. resolve via
    /// this short form.
    var shortKey: String {
        switch self {
        case .stateDept: "us"
        case .canada: "canada"
        case .ukFCDO: "uk"
        case .australia: "australia"
        case .exteriores: "spain"
        }
    }
}
