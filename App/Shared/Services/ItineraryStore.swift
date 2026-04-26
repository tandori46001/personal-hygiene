import Foundation

/// Persists the last `TripItinerary` generation per trip to disk so reopening
/// a trip detail surfaces the previous result without re-hitting the model.
///
/// One JSON file per `Trip.id` under Application Support so it survives app
/// restarts but stays out of iCloud Documents/Drive (these are notes, not
/// user-authored documents). Failures are swallowed — losing a cached
/// itinerary is harmless because the user can always regenerate.
public protocol ItineraryStore: Sendable {
    func load(for tripID: UUID) -> TripItinerary?
    func save(_ itinerary: TripItinerary, for tripID: UUID)
    func remove(for tripID: UUID)
}

public struct FileItineraryStore: ItineraryStore {

    private let directory: URL

    public init(directory: URL? = nil) {
        let fm = FileManager.default
        if let directory {
            self.directory = directory
        } else {
            let base =
                (try? fm.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )) ?? fm.temporaryDirectory
            self.directory = base.appendingPathComponent("Itineraries", isDirectory: true)
        }
        try? fm.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func load(for tripID: UUID) -> TripItinerary? {
        let url = fileURL(for: tripID)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TripItinerary.self, from: data)
    }

    public func save(_ itinerary: TripItinerary, for tripID: UUID) {
        let url = fileURL(for: tripID)
        guard let data = try? JSONEncoder().encode(itinerary) else { return }
        try? data.write(to: url, options: .atomic)
    }

    public func remove(for tripID: UUID) {
        let url = fileURL(for: tripID)
        try? FileManager.default.removeItem(at: url)
    }

    private func fileURL(for tripID: UUID) -> URL {
        directory.appendingPathComponent("\(tripID.uuidString).json")
    }
}

/// In-memory store for previews + tests.
public final class InMemoryItineraryStore: ItineraryStore, @unchecked Sendable {
    private var storage: [UUID: TripItinerary] = [:]
    private let lock = NSLock()

    public init() {}

    public func load(for tripID: UUID) -> TripItinerary? {
        lock.lock(); defer { lock.unlock() }
        return storage[tripID]
    }

    public func save(_ itinerary: TripItinerary, for tripID: UUID) {
        lock.lock(); defer { lock.unlock() }
        storage[tripID] = itinerary
    }

    public func remove(for tripID: UUID) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: tripID)
    }
}
