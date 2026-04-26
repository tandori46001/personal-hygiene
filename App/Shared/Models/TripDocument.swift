import Foundation
import SwiftData

public enum TripDocumentKind: String, CaseIterable, Codable, Sendable {
    case passport
    case visa
    case insurance
    case ticket
    case reservation
    case other
}

/// Metadata for a scanned document. The actual bytes live in the Keychain
/// under `keychainItemID`; this @Model only stores the pointer + display info.
@Model
public final class TripDocument {
    public var id: UUID
    public var name: String
    public var kind: TripDocumentKind
    public var addedAt: Date
    /// Identifier for the Keychain item that stores the encrypted PDF/image bytes.
    public var keychainItemID: String

    public var trip: Trip?

    public init(
        id: UUID = UUID(),
        name: String,
        kind: TripDocumentKind,
        addedAt: Date = Date(),
        keychainItemID: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.addedAt = addedAt
        self.keychainItemID = keychainItemID
    }
}
