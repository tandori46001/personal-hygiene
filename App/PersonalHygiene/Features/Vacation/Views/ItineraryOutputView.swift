import SwiftData
import SwiftUI
import UIKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Round 27 WS-A A8 (+ round 29 v2): post-wizard "Generate" screen. Shows
/// the assembled prompt + actions:
/// - Apple Intelligence on-device (when available iOS 26+) — persists output
/// - Copy prompt to clipboard
/// - Open in Claude.ai / ChatGPT / Perplexity (copies prompt + opens new chat)
struct ItineraryOutputView: View {

    let request: TripItineraryRequest
    @Bindable var trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var generatedText: String?
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var toastKey: LocalizedStringKey?

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
                        resultSection(result)
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
                if let key = toastKey {
                    Text(key, bundle: .main)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 8)
                }
            }
            .onAppear {
                generatedText = trip.itineraryGeneratedText
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
                copyPrompt(toast: "itinerary.output.copied")
            } label: {
                Label {
                    Text("itinerary.output.action.copy", bundle: .main)
                } icon: {
                    Image(systemName: "doc.on.clipboard")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            deepLinkButton(
                titleKey: "itinerary.output.action.claude",
                icon: "sparkle",
                url: URL(string: "https://claude.ai/new")
            )
            deepLinkButton(
                titleKey: "itinerary.output.action.chatgpt",
                icon: "bubble.left.and.text.bubble.right",
                url: URL(string: "https://chatgpt.com/")
            )
            deepLinkButton(
                titleKey: "itinerary.output.action.perplexity",
                icon: "magnifyingglass.circle",
                url: URL(string: "https://www.perplexity.ai/")
            )

            if isGenerating {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private func deepLinkButton(titleKey: LocalizedStringKey, icon: String, url: URL?) -> some View {
        Button {
            guard let url else { return }
            UIPasteboard.general.string = prompt
            UIApplication.shared.open(url)
            showToast("itinerary.output.openHint")
        } label: {
            Label {
                Text(titleKey, bundle: .main)
            } icon: {
                Image(systemName: icon)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private func resultSection(_ result: String) -> some View {
        Text("itinerary.output.result", bundle: .main)
            .font(.subheadline.bold())
        if let stamp = trip.itineraryGeneratedAt {
            Text(stamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        Text(verbatim: result)
            .padding(12)
            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .textSelection(.enabled)
        Button(role: .destructive) {
            trip.itineraryGeneratedText = nil
            trip.itineraryGeneratedAt = nil
            generatedText = nil
            try? modelContext.save()
        } label: {
            Text("itinerary.output.clear", bundle: .main)
                .font(.caption)
        }
    }

    private func copyPrompt(toast key: LocalizedStringKey) {
        UIPasteboard.general.string = prompt
        showToast(key)
    }

    private func showToast(_ key: LocalizedStringKey) {
        toastKey = key
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            toastKey = nil
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
                trip.itineraryGeneratedText = response.content
                trip.itineraryGeneratedAt = .now
                try? modelContext.save()
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
