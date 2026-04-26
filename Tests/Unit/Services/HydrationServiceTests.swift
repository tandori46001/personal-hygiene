import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class HydrationServiceTests: XCTestCase {

    func test_log_persistsEntryWhenMillilitersPositive() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHydrationService(context: container.mainContext)

        try service.log(milliliters: 250, at: Date())
        let entries = try service.logs(between: .distantPast, and: .distantFuture)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.milliliters, 250)
    }

    func test_log_ignoresZeroOrNegative() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHydrationService(context: container.mainContext)

        try service.log(milliliters: 0, at: Date())
        try service.log(milliliters: -100, at: Date())
        XCTAssertTrue(try service.logs(between: .distantPast, and: .distantFuture).isEmpty)
    }

    func test_logs_filtersByRange() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHydrationService(context: container.mainContext)

        let early = Date(timeIntervalSince1970: 0)
        let mid = Date(timeIntervalSince1970: 1_000_000)
        let late = Date(timeIntervalSince1970: 2_000_000)

        try service.log(milliliters: 100, at: early)
        try service.log(milliliters: 200, at: mid)
        try service.log(milliliters: 300, at: late)

        let filtered = try service.logs(
            between: Date(timeIntervalSince1970: 500_000),
            and: Date(timeIntervalSince1970: 1_500_000)
        )
        XCTAssertEqual(filtered.map(\.milliliters), [200])
    }

    func test_deleteAllLogs_clearsStore() throws {
        let container = try AppModelContainer.makeInMemory()
        let service = SwiftDataHydrationService(context: container.mainContext)
        try service.log(milliliters: 250, at: Date())
        try service.deleteAllLogs()
        XCTAssertTrue(try service.logs(between: .distantPast, and: .distantFuture).isEmpty)
    }
}
