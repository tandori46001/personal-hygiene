import XCTest

@testable import PersonalHygiene

final class BirthdayLeadStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "BirthdayLeadStoreTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        defaults.removeObject(forKey: UserDefaultsBirthdayLeadStore.storageKey)
        super.tearDown()
    }

    func test_unsetByDefault() {
        let store = UserDefaultsBirthdayLeadStore(defaults: defaults)
        XCTAssertNil(store.leadDays(for: "abc"))
    }

    func test_setAndReadBack() {
        let store = UserDefaultsBirthdayLeadStore(defaults: defaults)
        store.setLeadDays(14, for: "alice")
        XCTAssertEqual(store.leadDays(for: "alice"), 14)
    }

    func test_setNilClearsValue() {
        let store = UserDefaultsBirthdayLeadStore(defaults: defaults)
        store.setLeadDays(14, for: "alice")
        store.setLeadDays(nil, for: "alice")
        XCTAssertNil(store.leadDays(for: "alice"))
    }

    func test_clamp_negativeIsClearedNotStored() {
        let store = UserDefaultsBirthdayLeadStore(defaults: defaults)
        store.setLeadDays(7, for: "alice")
        store.setLeadDays(-1, for: "alice")
        XCTAssertNil(store.leadDays(for: "alice"))
    }
}

@MainActor
final class BirthdaysViewModelLeadDaysTests: XCTestCase {

    private struct StubContacts: ContactsService {
        let status: ContactsAuthorizationStatus
        let contacts: [BirthdayContact]
        var isAvailable: Bool { true }
        func authorizationStatus() -> ContactsAuthorizationStatus { status }
        func requestAccess() async throws -> Bool { true }
        func birthdayContacts() async throws -> [BirthdayContact] { contacts }
    }

    func test_leadDays_returnsDefaultWithoutOverride() {
        let leadStore = InMemoryBirthdayLeadStore()
        let vm = BirthdaysViewModel(
            service: StubContacts(status: .authorized, contacts: []),
            leadStore: leadStore,
            defaultLeadDays: 7
        )
        let contact = BirthdayContact(identifier: "1", displayName: "A", month: 4, day: 25, year: 1980)
        XCTAssertEqual(vm.leadDays(for: contact), 7)
        XCTAssertFalse(vm.hasOverride(contact))
    }

    func test_setLeadDays_persistsThroughStore() {
        let leadStore = InMemoryBirthdayLeadStore()
        let vm = BirthdaysViewModel(
            service: StubContacts(status: .authorized, contacts: []),
            leadStore: leadStore,
            defaultLeadDays: 7
        )
        let contact = BirthdayContact(identifier: "1", displayName: "A", month: 4, day: 25, year: 1980)
        vm.setLeadDays(14, for: contact)
        XCTAssertEqual(vm.leadDays(for: contact), 14)
        XCTAssertTrue(vm.hasOverride(contact))
        vm.clearLeadDays(for: contact)
        XCTAssertEqual(vm.leadDays(for: contact), 7)
    }
}
