@preconcurrency import XCTest

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

    func test_roomFilter_named_returnsOnlyMatchingRoom() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "Vacuum", recurrence: .weekly, escalationDays: 2, room: "Living")
        vm.add(title: "Sink", recurrence: .weekly, escalationDays: 2, room: "Kitchen")
        vm.add(title: "Mop", recurrence: .weekly, escalationDays: 2, room: "Living")

        vm.roomFilter = .named("Living")
        XCTAssertEqual(vm.filteredTasks.map(\.title).sorted(), ["Mop", "Vacuum"])
    }

    func test_roomFilter_unsorted_returnsTasksWithoutRoom() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "Vacuum", recurrence: .weekly, escalationDays: 2, room: "Kitchen")
        vm.add(title: "Sweep", recurrence: .weekly, escalationDays: 2)

        vm.roomFilter = .unsorted
        XCTAssertEqual(vm.filteredTasks.map(\.title), ["Sweep"])
    }

    func test_roomFilter_all_returnsEverything() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "Vacuum", recurrence: .weekly, escalationDays: 2, room: "Kitchen")
        vm.add(title: "Sweep", recurrence: .weekly, escalationDays: 2)
        XCTAssertEqual(vm.filteredTasks.count, 2)
    }

    func test_availableRooms_distinctSorted() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "A", recurrence: .weekly, escalationDays: 2, room: "Living")
        vm.add(title: "B", recurrence: .weekly, escalationDays: 2, room: "Kitchen")
        vm.add(title: "C", recurrence: .weekly, escalationDays: 2, room: "Living")
        XCTAssertEqual(vm.availableRooms, ["Kitchen", "Living"])
    }

    func test_addTask_trimsRoomAndStoresAsNilWhenBlank() {
        let service = InMemoryHousekeepingService()
        let vm = HousekeepingListViewModel(service: service)
        vm.add(title: "X", recurrence: .weekly, escalationDays: 2, room: "  ")
        XCTAssertNil(vm.tasks.first?.room)
    }
}
