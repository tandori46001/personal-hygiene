import Foundation

/// Snapshot of marine conditions at a point.
public struct MarineConditions: Equatable, Sendable {
    public let waveHeightMeters: Double?
    public let waveDirectionDegrees: Double?
    public let wavePeriodSeconds: Double?
    public let seaSurfaceTemperatureCelsius: Double?

    public init(
        waveHeightMeters: Double?,
        waveDirectionDegrees: Double?,
        wavePeriodSeconds: Double?,
        seaSurfaceTemperatureCelsius: Double?
    ) {
        self.waveHeightMeters = waveHeightMeters
        self.waveDirectionDegrees = waveDirectionDegrees
        self.wavePeriodSeconds = wavePeriodSeconds
        self.seaSurfaceTemperatureCelsius = seaSurfaceTemperatureCelsius
    }
}

public enum MarineWeatherError: Error, Equatable, LocalizedError {
    case invalidResponse
    case decodingFailed
    case offshoreOnly

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: "The marine API returned a non-success response."
        case .decodingFailed: "Could not decode the marine API response."
        case .offshoreOnly: "Marine data is only available for coastal coordinates."
        }
    }
}

public protocol MarineWeatherService: Sendable {
    func current(at latitude: Double, longitude: Double) async throws -> MarineConditions
}

/// Open-Meteo Marine API client. The endpoint is free, key-less, and serves
/// CORS-friendly JSON, so this is just a `URLSession` GET + JSON decode.
public struct OpenMeteoMarineService: MarineWeatherService {

    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func current(at latitude: Double, longitude: Double) async throws -> MarineConditions {
        var components = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(
                name: "current",
                value: "wave_height,wave_direction,wave_period,sea_surface_temperature"
            ),
        ]
        guard let url = components.url else { throw MarineWeatherError.invalidResponse }

        NetworkActivityCounter.shared.record(.openMeteo)
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MarineWeatherError.invalidResponse
        }
        return try Self.parse(data)
    }

    static func parse(_ data: Data) throws -> MarineConditions {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let payload = try decoder.decode(OpenMeteoMarinePayload.self, from: data)
            let current = payload.current
            // Open-Meteo returns null fields for points that aren't on water.
            let allNil =
                current.waveHeight == nil
                && current.waveDirection == nil
                && current.wavePeriod == nil
                && current.seaSurfaceTemperature == nil
            if allNil {
                throw MarineWeatherError.offshoreOnly
            }
            return MarineConditions(
                waveHeightMeters: current.waveHeight,
                waveDirectionDegrees: current.waveDirection,
                wavePeriodSeconds: current.wavePeriod,
                seaSurfaceTemperatureCelsius: current.seaSurfaceTemperature
            )
        } catch let error as MarineWeatherError {
            throw error
        } catch {
            throw MarineWeatherError.decodingFailed
        }
    }
}

private struct OpenMeteoMarinePayload: Decodable {
    let current: Current

    struct Current: Decodable {
        let waveHeight: Double?
        let waveDirection: Double?
        let wavePeriod: Double?
        let seaSurfaceTemperature: Double?
    }
}
