import Foundation
import Observation

@Observable
@MainActor
final class BirthdaysViewModel {

    private let service: any ContactsService
    private let calendar: Calendar
    private let windowDays: Int

    var status: ContactsAuthorizationStatus = .notDetermined
    var upcoming: [UpcomingBirthdays.Upcoming] = []
    var errorMessage: String?

    init(service: any ContactsService, windowDays: Int = 60, calendar: Calendar = .autoupdatingCurrent) {
        self.service = service
        self.windowDays = windowDays
        self.calendar = calendar
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
