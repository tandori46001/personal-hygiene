import SwiftData
import SwiftUI

/// Round-16: surfaces `MedicationDoseHistory` aggregator results in a plain
/// list. Read-only — adherence stats live elsewhere. Used as a deep-link
/// from the Medication tab and (round 17+) from a watch glance.
///
/// Round-18 slices 9+10: gains a pull-to-refresh + a chip-row that filters
/// entries by `conceptIdentifier`. The view stores its own copy of the
/// loaded entries so refresh can re-fetch without re-instantiating the view.
struct DoseHistoryView: View {

    /// Round-18 slice 9: closure-based loader so refresh can re-fetch a
    /// fresh window without re-creating the view. Defaulted to a no-op
    /// returning the seeded `initialEntries` for callers that don't need
    /// refresh semantics (tests, previews).
    let loader: () -> [MedicationDoseHistory.Entry]

    @State private var entries: [MedicationDoseHistory.Entry]
    @State private var conceptFilter: String?

    init(
        entries: [MedicationDoseHistory.Entry],
        loader: @escaping () -> [MedicationDoseHistory.Entry] = { [] }
    ) {
        self._entries = State(initialValue: entries)
        // When the caller didn't supply a real loader, fall back to returning
        // the initial entries so pull-to-refresh keeps the same content rather
        // than blanking the list.
        let seeded = entries
        self.loader = {
            let next = loader()
            return next.isEmpty ? seeded : next
        }
    }

    private var availableConceptIdentifiers: [String] {
        Array(Set(entries.compactMap(\.conceptIdentifier))).sorted()
    }

    private var filteredEntries: [MedicationDoseHistory.Entry] {
        guard let conceptFilter else { return entries }
        return entries.filter { $0.conceptIdentifier == conceptFilter }
    }

    var body: some View {
        List {
            if !availableConceptIdentifiers.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(for: nil, title: Text("medication.dose.history.filter.all", bundle: .main))
                            ForEach(availableConceptIdentifiers, id: \.self) { concept in
                                chip(for: concept, title: Text(verbatim: concept))
                            }
                        }
                    }
                }
            }

            if filteredEntries.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("medication.dose.history.empty.title", bundle: .main)
                    } icon: {
                        Image(systemName: "pills")
                    }
                } description: {
                    Text("medication.dose.history.empty.description", bundle: .main)
                }
            } else {
                ForEach(filteredEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.blockTitle)
                                .font(.body)
                            Spacer()
                            Text(entry.completedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        if let concept = entry.conceptIdentifier {
                            Text(verbatim: concept)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle(Text("medication.dose.history.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            entries = loader()
            // If the active filter no longer matches any entry after a refresh,
            // drop it so the user isn't staring at an empty filtered list.
            if let active = conceptFilter, !availableConceptIdentifiers.contains(active) {
                conceptFilter = nil
            }
        }
    }

    @ViewBuilder
    private func chip(for concept: String?, title: Text) -> some View {
        let isSelected = (conceptFilter == concept)
        Button {
            conceptFilter = (conceptFilter == concept) ? nil : concept
        } label: {
            title
                .font(.caption.monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .buttonStyle(.plain)
    }
}
