#if canImport(VisionKit)
import PDFKit
import SwiftUI
import VisionKit

/// SwiftUI wrapper around `VNDocumentCameraViewController`. Returns the scanned
/// pages flattened into a single PDF blob so callers can hand it straight to
/// `TripDocumentStore.add(name:kind:bytes:to:)`.
struct DocumentScannerView: UIViewControllerRepresentable {

    enum Result {
        case success(Data)
        case failure(Error)
        case cancelled
    }

    let onFinish: (Result) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        private let onFinish: (Result) -> Void

        init(onFinish: @escaping (Result) -> Void) {
            self.onFinish = onFinish
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let pdf = PDFDocument()
            for index in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: index)
                if let page = PDFPage(image: image) {
                    pdf.insert(page, at: index)
                }
            }
            MainActor.assumeIsolated { controller.dismiss(animated: true) }
            if let data = pdf.dataRepresentation() {
                onFinish(.success(data))
            } else {
                onFinish(.failure(ScannerError.encodingFailed))
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            MainActor.assumeIsolated { controller.dismiss(animated: true) }
            onFinish(.cancelled)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            MainActor.assumeIsolated { controller.dismiss(animated: true) }
            onFinish(.failure(error))
        }
    }

    enum ScannerError: Error, LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed: "Could not turn scanned pages into a PDF."
            }
        }
    }
}
#endif
