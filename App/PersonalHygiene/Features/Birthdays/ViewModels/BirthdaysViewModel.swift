import Foundation
import Observation

@Observable
@MainActor
final class BirthdaysViewModel {

    private let service: any ContactsService
    private let leadStore: any BirthdayLeadStore
    private let calendar: Calendar
    private let windowDays: Int

    var status: ContactsAuthorizationStatus = .notDetermined
    var upcoming: [UpcomingBirthdays.Upcoming] = []
    var errorMessage: String?

    let defaultLeadDays: Int

    init(
        service: any ContactsService,
        leadStore: any BirthdayLeadStore = InMemoryBirthdayLeadStore(),
        defaultLeadDays: Int = UserDefaultsBirthdayLeadStore.defaultLeadDays,
        windowDays: Int = 60,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.service = service
        self.leadStore = leadStore
        self.defaultLeadDays = defaultLeadDays
        self.windowDays = windowDays
        self.calendar = calendar
    }

    func leadDays(for contact: BirthdayContact) -> Int {
        leadStore.leadDays(for: contact.identifier) ?? defaultLeadDays
    }

    func hasOverride(_ contact: BirthdayContact) -> Bool {
        leadStore.leadDays(for: contact.identifier) != nil
    }

    func setLeadDays(_ value: Int, for contact: BirthdayContact) {
        leadStore.setLeadDays(max(0, value), for: contact.identifier)
    }

    func clearLeadDays(for contact: BirthdayContact) {
        leadStore.setLeadDays(nil, for: contact.identifier)
    }

    func reloadStatus() {
        status = service.authorizationStatus()
    }

    func requestAccess() async {
        do {
            _ = try await service.requestAccess()
            reloadStatus()
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reload(now: Date = Date()) async {
        guard status == .authorized || status == .limited else {
            upcoming = []
            return
        }
        do {
            let contacts = try await service.birthdayContacts()
            upcoming = UpcomingBirthdays.upcoming(
                from: contacts,
                on: now,
                windowDays: windowDays,
                calendar: calendar
            )
        } catch {
            errorMessage = error.localizedDescription
            upcoming = []
        }
    }
}
