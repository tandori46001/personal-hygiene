import SwiftUI
import UIKit

/// Thin wrapper around `UIActivityViewController` so we can present it from
/// SwiftUI as a `.sheet`. Used for the trip PDF export flow.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
