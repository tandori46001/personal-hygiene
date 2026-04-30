@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class ContactsServiceTests: XCTestCase {

    func test_requestAccess_grantsByDefault() async throws {
        let service = InMemoryContactsService()
        let granted = try await service.requestAccess()
        XCTAssertTrue(granted)
        XCTAssertEqual(service.authorizationStatus(), .authorized)
    }

    func test_requestAccess_canBeDenied() async throws {
        let service = InMemoryContactsService(grantOnRequest: false)
        let granted = try await service.requestAccess()
        XCTAssertFalse(granted)
        XCTAssertEqual(service.authorizationStatus(), .denied)
    }

    func test_birthdayContacts_throwsWhenNotAuthorized() async {
        let service = InMemoryContactsService(
            contacts: [BirthdayContact(identifier: "1", displayName: "Sara", month: 4, day: 25, year: 1990)],
            status: .notDetermined
        )
        do {
            _ = try await service.birthdayContacts()
            XCTFail("Expected denied error")
        } catch let error as ContactsServiceError {
            XCTAssertEqual(error, .denied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_birthdayContacts_returnsListWhenAuthorized() async throws {
        let service = InMemoryContactsService(
            contacts: [
                BirthdayContact(identifier: "1", displayName: "Sara", month: 4, day: 25, year: 1990),
                BirthdayContact(identifier: "2", displayName: "Pablo", month: 1, day: 1, year: nil),
            ],
            status: .authorized
        )
        let results = try await service.birthdayContacts()
        XCTAssertEqual(results.count, 2)
    }
}
