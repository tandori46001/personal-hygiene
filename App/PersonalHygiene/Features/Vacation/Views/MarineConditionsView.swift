import SwiftUI

struct MarineConditionsView: View {

    let latitude: Double
    let longitude: Double
    let service: any MarineWeatherService

    @State private var conditions: MarineConditions?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        Form {
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("trip.marine.loading", bundle: .main)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let errorMessage {
                Section {
                    ErrorBanner(message: errorMessage, onDismiss: { self.errorMessage = nil })
                }
            } else if let conditions {
                Section {
                    if let height = conditions.waveHeightMeters {
                        LabeledContent {
                            Text(verbatim: String(format: "%.1f m", height))
                        } label: {
                            Text("trip.marine.waveHeight", bundle: .main)
                        }
                    }
                    if let period = conditions.wavePeriodSeconds {
                        LabeledContent {
                            Text(verbatim: String(format: "%.1f s", period))
                        } label: {
                            Text("trip.marine.wavePeriod", bundle: .main)
                        }
                    }
                    if let direction = conditions.waveDirectionDegrees {
                        LabeledContent {
                            Text(verbatim: "\(Int(direction))°")
                        } label: {
                            Text("trip.marine.waveDirection", bundle: .main)
                        }
                    }
                    if let temperature = conditions.seaSurfaceTemperatureCelsius {
                        LabeledContent {
                            Text(verbatim: String(format: "%.1f °C", temperature))
                        } label: {
                            Text("trip.marine.seaTemp", bundle: .main)
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("trip.marine.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            conditions = try await service.current(at: latitude, longitude: longitude)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
