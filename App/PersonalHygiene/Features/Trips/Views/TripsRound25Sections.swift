import SwiftUI

/// Round-25 slice T5.37: Diagnostics row that surfaces docs about to
/// expire. Reads its input via the `documents:` parameter; renders nothing
/// when none are due. Lives in the Trips feature folder so the view +
/// helper sit together.
struct TripDocumentExpirySection: View {

    let documents: [TripDocumentExpiryReminder.Document]

    var body: some View {
        let due = TripDocumentExpiryReminder.documentsExpiringWithin(
            leadDays: 30,
            documents: documents
        )
        if !due.isEmpty {
            Section {
                ForEach(due) { doc in
                    let days = TripDocumentExpiryReminder.daysUntilExpiry(for: doc) ?? 0
                    HStack {
                        Text(verbatim: doc.title)
                            .font(.callout)
                        Spacer()
                        Text("trips.document.expiresIn \(days)", bundle: .main)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(days <= 7 ? .red : .orange)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("trips.document.expiry.title", bundle: .main)
            } footer: {
                Text("trips.document.expiry.footer", bundle: .main)
            }
        }
    }
}
