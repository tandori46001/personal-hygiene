import SwiftUI

/// Round-21 vacation wires:
/// - T3.15 `ItineraryDayForecastChip`: chip showing high/low + rain-prob for
///   one itinerary day, fed by `WeatherForecastCache`.
/// - T3.16 weather notes template extension on `TripNotesSection.NotesTemplate`.
struct ItineraryDayForecastChip: View {
    let forecast: WeatherForecast

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: forecast.symbolName)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
            Text(verbatim: Self.tempLabel(forecast))
                .font(.caption2.monospacedDigit())
            if forecast.precipitationProbability >= 0.2 {
                Text(verbatim: "·")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text(verbatim: "\(Int((forecast.precipitationProbability * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.08), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    static func tempLabel(_ forecast: WeatherForecast) -> String {
        let high = Int(forecast.highCelsius.rounded())
        let low = Int(forecast.lowCelsius.rounded())
        return "\(high)°/\(low)°"
    }
}

/// Round-21 slice T3.16: builds the Markdown body for the new "weather
/// forecast" notes template using cached forecasts. Pure helper so it can be
/// unit-tested without a real WeatherKit fetch.
public enum TripNotesWeatherTemplate {

    public static func body(
        for forecasts: [WeatherForecast],
        headline: String,
        rainTag: String,
        unavailable: String
    ) -> String {
        guard !forecasts.isEmpty else {
            return [headline, "- \(unavailable)"].joined(separator: "\n")
        }
        var lines = [headline]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        for forecast in forecasts {
            let dayLabel = formatter.string(from: forecast.day)
            var line = "- \(dayLabel) — \(Int(forecast.highCelsius.rounded()))°/\(Int(forecast.lowCelsius.rounded()))°"
            if forecast.precipitationProbability >= 0.3 {
                line += " · \(rainTag) \(Int((forecast.precipitationProbability * 100).rounded()))%"
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}
