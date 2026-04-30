import SwiftData
@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class HousekeepingServiceTests: XCTestCase {

    func test_upsert_andAllTasks_returnsInserted() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHousekeepingService(context: container.mainContext)
        let task = HousekeepingTask(title: "Vacuum", recurrence: .weekly)
        try service.upsert(task)

        let all = try service.allTasks()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.title, "Vacuum")
        XCTAssertEqual(all.first?.recurrence, .weekly)
    }

    func test_markDone_setsLastCompletedAt() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHousekeepingService(context: container.mainContext)
        let task = HousekeepingTask(title: "Vacuum", recurrence: .weekly)
        try service.upsert(task)

        try service.markDone(task, at: Date(timeIntervalSince1970: 1_000_000))
        let fetched = try service.allTasks().first
        XCTAssertEqual(fetched?.lastCompletedAt, Date(timeIntervalSince1970: 1_000_000))
    }

    func test_delete_removesTask() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHousekeepingService(context: container.mainContext)
        let task = HousekeepingTask(title: "Vacuum", recurrence: .weekly)
        try service.upsert(task)
        try service.delete(task)
        XCTAssertTrue(try service.allTasks().isEmpty)
    }
}
