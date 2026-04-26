import Foundation

/// Pairs `TripsRepository` with `KeychainStore`. The repository tracks
/// document metadata; the Keychain holds the encrypted bytes. Keeping them
/// behind one façade ensures we never end up with a metadata row that
/// points at a deleted Keychain item or vice-versa.
@MainActor
public final class TripDocumentStore {

    private let repository: any TripsRepository
    private let keychain: any KeychainStore

    public init(repository: any TripsRepository, keychain: any KeychainStore) {
        self.repository = repository
        self.keychain = keychain
    }

    public func add(
        name: String,
        kind: TripDocumentKind,
        bytes: Data,
        to trip: Trip,
        addedAt: Date = Date()
    ) throws -> TripDocument {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let keychainID = UUID().uuidString
        try keychain.write(bytes, for: keychainID)

        let document = TripDocument(
            name: trimmed.isEmpty ? "Untitled" : trimmed,
            kind: kind,
            addedAt: addedAt,
            keychainItemID: keychainID
        )
        do {
            try repository.addDocument(document, to: trip)
        } catch {
            try? keychain.delete(keychainID)
            throw error
        }
        return document
    }

    public func bytes(for document: TripDocument) throws -> Data {
        try keychain.read(document.keychainItemID)
    }

    public func remove(_ document: TripDocument) throws {
        let keychainID = document.keychainItemID
        try repository.deleteDocument(document)
        try keychain.delete(keychainID)
    }
}
