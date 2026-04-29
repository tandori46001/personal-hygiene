@preconcurrency import Contacts
import Foundation

public enum ContactsAuthorizationStatus: String, Sendable {
    case notDetermined
    case denied
    case restricted
    case authorized
    case limited
}

public enum ContactsServiceError: Error, Equatable {
    case unavailable
    case denied
}

@MainActor
public protocol ContactsService {
    var isAvailable: Bool { get }
    func authorizationStatus() -> ContactsAuthorizationStatus
    /// Request access to read contacts. Returns `true` when the user
    /// authorized (full or limited).
    func requestAccess() async throws -> Bool
    /// All contacts that have a birthday set (with at least month + day).
    func birthdayContacts() async throws -> [BirthdayContact]
}

@MainActor
public final class CNContactsService: ContactsService {

    private let store: CNContactStore

    public init(store: CNContactStore = CNContactStore()) {
        self.store = store
    }

    public var isAvailable: Bool { true }

    public func authorizationStatus() -> ContactsAuthorizationStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorized: return .authorized
        case .limited: return .limited
        @unknown default: return .notDetermined
        }
    }

    public func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }

    public func birthdayContacts() async throws -> [BirthdayContact] {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.unifyResults = true

        var results: [BirthdayContact] = []
        try store.enumerateContacts(with: request) { contact, _ in
            guard let bday = contact.birthday,
                let month = bday.month,
                let day = bday.day
            else { return }
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            guard !name.isEmpty else { return }
            results.append(
                BirthdayContact(
                    identifier: contact.identifier,
                    displayName: name,
                    month: month,
                    day: day,
                    year: bday.year == NSNotFound ? nil : bday.year
                )
            )
        }
        return results
    }
}

@MainActor
public final class InMemoryContactsService: ContactsService {

    public var contacts: [BirthdayContact]
    public var status: ContactsAuthorizationStatus
    public var grantOnRequest: Bool

    public init(
        contacts: [BirthdayContact] = [],
        status: ContactsAuthorizationStatus = .notDetermined,
        grantOnRequest: Bool = true
    ) {
        self.contacts = contacts
        self.status = status
        self.grantOnRequest = grantOnRequest
    }

    public var isAvailable: Bool { true }

    public func authorizationStatus() -> ContactsAuthorizationStatus { status }

    public func requestAccess() async throws -> Bool {
        if grantOnRequest {
            status = .authorized
            return true
        }
        status = .denied
        return false
    }

    public func birthdayContacts() async throws -> [BirthdayContact] {
        guard status == .authorized || status == .limited else {
            throw ContactsServiceError.denied
        }
        return contacts
    }
}
