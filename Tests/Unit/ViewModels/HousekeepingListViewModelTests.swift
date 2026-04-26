import XCTest

@testable import PersonalHygiene

@MainActor
final class HousekeepingListViewModelTests: XCTestCase {

    func test_add_appendsTask() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "Vacuum", recurrence: .weekly, escalationDays: 2)
        XCTAssertEqual(vm.tasks.map(\.title), ["Vacuum"])
    }

    func test_add_ignoresEmptyTitle() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "  ", recurrence: .weekly, escalationDays: 2)
        XCTAssertTrue(vm.tasks.isEmpty)
    }

    func test_markDone_setsLastCompletedAt() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "Vacuum", recurrence: .weekly, escalationDays: 2)
        guard let task = vm.tasks.first else {
            XCTFail("Expected task")
            return
        }
        vm.markDone(task, now: Date(timeIntervalSince1970: 1_000_000))
        XCTAssertEqual(vm.tasks.first?.lastCompletedAt, Date(timeIntervalSince1970: 1_000_000))
    }

    func test_delete_removesTask() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "Vacuum", recurrence: .weekly, escalationDays: 2)
        guard let task = vm.tasks.first else {
            XCTFail("Expected task")
            return
        }
        vm.delete(task)
        XCTAssertTrue(vm.tasks.isEmpty)
    }
}
