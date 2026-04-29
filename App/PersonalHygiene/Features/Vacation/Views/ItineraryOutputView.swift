import SwiftUI
import UIKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Round 27 WS-A A8: post-wizard "Generate" screen. Shows the assembled
/// prompt + 2 actions:
/// - Apple Intelligence on-device (when available iOS 18.1+)
/// - Copy to clipboard for paste into Claude.ai / ChatGPT / Perplexity
struct ItineraryOutputView: View {

    let request: TripItineraryRequest
    let trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var generatedText: String?
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var copiedToast = false

    private var prompt: String {
        ItineraryPromptBuilder.build(request: request, trip: trip)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("itinerary.output.preview", bundle: .main)
                        .font(.subheadline.bold())
                    Text(verbatim: prompt)
                        .font(.system(.caption, design: .monospaced))
                        .padding(12)
                        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        .textSelection(.enabled)

                    Divider()

                    actionsSection

                    if let result = generatedText {
                        Divider()
                        Text("itinerary.output.result", bundle: .main)
                            .font(.subheadline.bold())
                        Text(verbatim: result)
                            .padding(12)
                            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            .textSelection(.enabled)
                    }
                    if let err = generationError {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle(Text("itinerary.output.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.done", bundle: .main)
                    }
                }
            }
            .overlay(alignment: .top) {
                if copiedToast {
                    Text("itinerary.output.copied", bundle: .main)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 8)
                }
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 10) {
            #if canImport(FoundationModels)
            if isAppleFMAvailable {
                Button {
                    Task { await runOnDevice() }
                } label: {
                    Label {
                        Text("itinerary.output.action.appleFM", bundle: .main)
                    } icon: {
                        Image(systemName: "apple.logo")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
            #endif

            Button {
                UIPasteboard.general.string = prompt
                copiedToast = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    copiedToast = false
                }
            } label: {
                Label {
                    Text("itinerary.output.action.copy", bundle: .main)
                } icon: {
                    Image(systemName: "doc.on.clipboard")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if isGenerating {
                ProgressView()
            }
        }
    }

    private var isAppleFMAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    private func runOnDevice() async {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else {
                generationError = String(
                    localized: "itinerary.output.error.unavailable",
                    bundle: .main
                )
                return
            }
            isGenerating = true
            generationError = nil
            defer { isGenerating = false }
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                generatedText = response.content
            } catch {
                generationError = error.localizedDescription
            }
        } else {
            generationError = String(
                localized: "itinerary.output.error.unavailable",
                bundle: .main
            )
        }
        #endif
    }
}
