import PDFKit
import SwiftUI

/// Renders a `TripDocument` from its Keychain-stored bytes. PDFs go through
/// `PDFKitView`; raw image bytes (JPEG/PNG) fall back to `Image(uiImage:)`.
struct DocumentPreviewView: View {

    let document: TripDocument
    let store: TripDocumentStore

    @State private var bytes: Data?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView {
                    Label {
                        Text("trip.document.preview.error.title", bundle: .main)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                } description: {
                    Text(verbatim: loadError)
                }
            } else if let bytes {
                content(for: bytes)
            } else {
                ProgressView()
                    .accessibilityLabel(Text("trip.document.preview.loading", bundle: .main))
            }
        }
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
    }

    @ViewBuilder
    private func content(for bytes: Data) -> some View {
        if let pdf = PDFDocument(data: bytes) {
            PDFKitView(pdf: pdf)
                .ignoresSafeArea(edges: .bottom)
                .accessibilityLabel(
                    Text("trip.document.preview.pdf.\(pdf.pageCount).\(document.name)", bundle: .main)
                )
        } else if let image = UIImage(data: bytes) {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(
                        Text("trip.document.preview.image.\(document.name)", bundle: .main)
                    )
            }
        } else {
            ContentUnavailableView {
                Label {
                    Text("trip.document.preview.unsupported.title", bundle: .main)
                } icon: {
                    Image(systemName: "doc")
                }
            } description: {
                Text("trip.document.preview.unsupported.description", bundle: .main)
            }
        }
    }

    private func load() {
        do {
            bytes = try store.bytes(for: document)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let pdf: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = pdf
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdf
    }
}
