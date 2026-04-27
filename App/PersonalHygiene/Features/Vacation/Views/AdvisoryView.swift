import SwiftUI

struct AdvisoryView: View {

    let links: [TravelAdvisoryLink]
    let destination: String

    /// Backwards-compatible single-link initializer kept for previews / tests
    /// that haven't migrated to the multi-source list API.
    init(link: TravelAdvisoryLink) {
        self.init(links: [link], destination: link.displayName)
    }

    init(links: [TravelAdvisoryLink], destination: String) {
        self.links = links
        self.destination = destination
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(verbatim: destination)
                } label: {
                    Text("trip.advisory.label.destination", bundle: .main)
                }
            } footer: {
                Text("trip.advisory.multi.footer", bundle: .main)
            }

            Section {
                ForEach(Array(links.enumerated()), id: \.offset) { _, link in
                    Link(destination: link.url) {
                        HStack {
                            Image(systemName: "exclamationmark.shield")
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: link.source)
                                    .font(.body)
                                Text(verbatim: link.url.host ?? link.url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            Text("trip.advisory.openSource \(link.source)", bundle: .main)
                        )
                    }
                }
            } header: {
                Text("trip.advisory.section.sources", bundle: .main)
            } footer: {
                Text("trip.advisory.footer", bundle: .main)
            }
        }
        .navigationTitle(Text("trip.advisory.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
    }
}
