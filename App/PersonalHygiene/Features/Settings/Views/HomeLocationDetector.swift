@preconcurrency import CoreLocation
import Foundation
import Observation

/// Round-27 follow-up: one-shot wrapper around `CLLocationManager` that
/// fetches the device's current location and reverse-geocodes it to a
/// human-readable address for the Home Location settings page. Handles
/// the auth dance + delegates back via `@Observable` properties so the
/// SwiftUI form re-renders automatically.
@Observable
@MainActor
final class HomeLocationDetector: NSObject {

    enum Status: Equatable {
        case idle
        case requestingAuth
        case detecting
        case ready(name: String, latitude: Double, longitude: Double)
        case denied
        case failed(String)
    }

    var status: Status = .idle

    private let manager: CLLocationManager
    private let geocoder: CLGeocoder

    override init() {
        self.manager = CLLocationManager()
        self.geocoder = CLGeocoder()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Kicks off the one-shot fetch. Asks for `whenInUse` if needed,
    /// then `requestLocation()` on the manager. Result lands in `status`
    /// asynchronously.
    func detect() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .requestingAuth
            manager.requestWhenInUseAuthorization()
            // The delegate callback will invoke `detect()` again once
            // authorization resolves.
        case .denied, .restricted:
            status = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            status = .detecting
            manager.requestLocation()
        @unknown default:
            status = .failed("unknown auth state")
        }
    }
}

extension HomeLocationDetector: @preconcurrency CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let auth = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch auth {
            case .authorizedWhenInUse, .authorizedAlways:
                if case .requestingAuth = self.status { self.detect() }
            case .denied, .restricted:
                self.status = .denied
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            await self?.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.status = .failed(message)
        }
    }

    @MainActor
    private func reverseGeocode(_ location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let name = Self.formatName(from: placemarks.first) ?? Self.fallbackName(from: location)
            status = .ready(
                name: name,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            status = .ready(
                name: Self.fallbackName(from: location),
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    private static func formatName(from placemark: CLPlacemark?) -> String? {
        guard let placemark else { return nil }
        var parts: [String] = []
        if let line1 = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap({ $0 }).joined(separator: " ").nonEmpty {
            parts.append(line1)
        }
        if let locality = placemark.locality { parts.append(locality) }
        if let country = placemark.country { parts.append(country) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private static func fallbackName(from location: CLLocation) -> String {
        String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
