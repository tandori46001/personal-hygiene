import Foundation
import Security

public enum KeychainError: Error, Equatable {
    case unhandled(OSStatus)
    case itemNotFound
    case dataNotFound
}

/// Minimal `Data` blob store keyed by `String`. Used to persist scanned
/// document bytes outside of SwiftData, encrypted at rest by iOS Keychain.
@MainActor
public protocol KeychainStore {
    func write(_ data: Data, for key: String) throws
    func read(_ key: String) throws -> Data
    func delete(_ key: String) throws
}

@MainActor
public final class SecKeychainStore: KeychainStore {

    public let service: String

    public init(service: String = "com.tandori46001.personalhygiene.documents") {
        self.service = service
    }

    public func write(_ data: Data, for key: String) throws {
        try delete(key)
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    public func read(_ key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw KeychainError.dataNotFound }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unhandled(status)
        }
    }

    public func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }
}

/// In-memory fake — used in unit tests and previews.
@MainActor
public final class InMemoryKeychainStore: KeychainStore {

    public private(set) var items: [String: Data] = [:]

    public init() {}

    public func write(_ data: Data, for key: String) throws {
        items[key] = data
    }

    public func read(_ key: String) throws -> Data {
        guard let data = items[key] else { throw KeychainError.itemNotFound }
        return data
    }

    public func delete(_ key: String) throws {
        items.removeValue(forKey: key)
    }
}
