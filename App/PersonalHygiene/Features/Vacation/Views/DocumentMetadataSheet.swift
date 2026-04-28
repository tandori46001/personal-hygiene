import SwiftUI

/// Captured immediately after a successful scan — the user picks a name and a
/// kind for the bytes, then we hand both to the document store.
struct DocumentMetadataSheet: View {
    @Environment(\.dismiss) private var dismiss

    let bytes: Data
    let onCommit: (_ name: String, _ kind: TripDocumentKind) -> Void

    @State private var name: String = ""
    @State private var kind: TripDocumentKind = .other

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    text: $name,
                    prompt: Text("trip.document.field.name.placeholder", bundle: .main)
                ) {
                    Text("trip.document.field.name", bundle: .main)
                }
                Picker(selection: $kind) {
                    ForEach(TripDocumentKind.allCases, id: \.self) { value in
                        Text(localizedKey: "trip.document.kind.\(value.rawValue)")
                            .tag(value)
                    }
                } label: {
                    Text("trip.document.field.kind", bundle: .main)
                }
            }
            .navigationTitle(Text("trip.document.metadata.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onCommit(name, kind)
                        dismiss()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
