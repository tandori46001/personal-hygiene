import Foundation

public struct CurrencyConversion: Equatable, Sendable {
    public let from: String
    public let to: String
    public let rate: Double
    public let amountConverted: Double

    public init(from: String, to: String, rate: Double, amountConverted: Double) {
        self.from = from
        self.to = to
        self.rate = rate
        self.amountConverted = amountConverted
    }
}

public enum CurrencyError: Error, Equatable, LocalizedError {
    case invalidResponse
    case decodingFailed
    case rateNotFound

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: "The currency API returned a non-success response."
        case .decodingFailed: "Could not decode the currency response."
        case .rateNotFound: "No exchange rate found for the requested currency pair."
        }
    }
}

public protocol CurrencyService: Sendable {
    func convert(amount: Double, from: String, to: String) async throws -> CurrencyConversion
}

/// Frankfurter exchange-rate client. Free, key-less, ECB-sourced JSON. The
/// endpoint format is `https://api.frankfurter.app/latest?amount=…&from=…&to=…`.
public struct FrankfurterCurrencyService: CurrencyService {

    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func convert(amount: Double, from: String, to: String) async throws -> CurrencyConversion {
        var components = URLComponents(string: "https://api.frankfurter.app/latest")!
        components.queryItems = [
            URLQueryItem(name: "amount", value: String(amount)),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: to),
        ]
        guard let url = components.url else { throw CurrencyError.invalidResponse }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CurrencyError.invalidResponse
        }
        return try Self.parse(data, amount: amount, from: from, to: to)
    }

    static func parse(
        _ data: Data,
        amount: Double,
        from: String,
        to: String
    ) throws -> CurrencyConversion {
        do {
            let payload = try JSONDecoder().decode(FrankfurterPayload.self, from: data)
            guard let converted = payload.rates[to.uppercased()] else {
                throw CurrencyError.rateNotFound
            }
            // Frankfurter returns the converted amount in `rates[to]`; the per-unit
            // rate is therefore converted/amount when amount > 0.
            let rate = amount > 0 ? converted / amount : converted
            return CurrencyConversion(
                from: from.uppercased(),
                to: to.uppercased(),
                rate: rate,
                amountConverted: converted
            )
        } catch let error as CurrencyError {
            throw error
        } catch {
            throw CurrencyError.decodingFailed
        }
    }
}

private struct FrankfurterPayload: Decodable {
    let amount: Double
    let base: String
    let rates: [String: Double]
}
