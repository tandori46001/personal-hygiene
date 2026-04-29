import XCTest
import SwiftData

@testable import PersonalHygiene

@MainActor
final class ImportantDaySeederTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([ImportantDay.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    func test_seeds_loadsBundleForLocale() {
        let seeds = ImportantDaySeeder.seeds(for: "es")
        XCTAssertGreaterThan(seeds.count, 5, "ES bundle should ship more than 5 seeded days")
        XCTAssertTrue(seeds.contains { $0.name.lowercased().contains("madre") })
        XCTAssertTrue(seeds.contains { $0.name == "Navidad" })
    }

    func test_seeds_fallsBackToEnForUnknownLocale() {
        let seeds = ImportantDaySeeder.seeds(for: "xx")
        XCTAssertGreaterThan(seeds.count, 0, "Unknown locale should fall back to English")
        XCTAssertTrue(seeds.contains { $0.name == "Christmas" })
    }

    func test_seedIfEmpty_insertsRowsWhenTableEmpty() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let before = (try? context.fetch(FetchDescriptor<ImportantDay>()))?.count ?? 0
        XCTAssertEqual(before, 0)

        ImportantDaySeeder.seedIfEmpty(in: context, languageCode: "en")

        let after = (try? context.fetch(FetchDescriptor<ImportantDay>()))?.count ?? 0
        XCTAssertGreaterThan(after, 0)
    }

    func test_seedIfEmpty_isIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext

        ImportantDaySeeder.seedIfEmpty(in: context, languageCode: "en")
        let firstCount = (try? context.fetch(FetchDescriptor<ImportantDay>()))?.count ?? 0
        XCTAssertGreaterThan(firstCount, 0)

        // Second call should NOT duplicate.
        ImportantDaySeeder.seedIfEmpty(in: context, languageCode: "en")
        let secondCount = (try? context.fetch(FetchDescriptor<ImportantDay>()))?.count ?? 0
        XCTAssertEqual(firstCount, secondCount)
    }

    func test_seedIfEmpty_preservesUserCustomizations() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // User adds a custom day before seeder runs (edge case).
        let custom = ImportantDay(
            name: "Wedding",
            dayRule: .anniversary(year: 2020, month: 6, day: 15),
            isCustom: true
        )
        context.insert(custom)
        try context.save()

        // Seeder must NOT touch anything because the table is non-empty.
        ImportantDaySeeder.seedIfEmpty(in: context, languageCode: "en")

        let all = try context.fetch(FetchDescriptor<ImportantDay>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Wedding")
    }
}
