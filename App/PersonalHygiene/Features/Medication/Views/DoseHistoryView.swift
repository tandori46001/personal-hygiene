import SwiftData
import SwiftUI

/// Round-16: surfaces `MedicationDoseHistory` aggregator results in a plain
/// list. Read-only — adherence stats live elsewhere. Used as a deep-link
/// from the Medication tab and (round 17+) from a watch glance.
struct DoseHistoryView: View {

    let entries: [MedicationDoseHistory.Entry]

    var body: some View {
        List {
            if entries.isEmpty {
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
                ForEach(entries) { entry in
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
    }
}
