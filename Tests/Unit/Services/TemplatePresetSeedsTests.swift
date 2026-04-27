@testable import PersonalHygiene
import XCTest

final class TemplatePresetSeedsTests: XCTestCase {

    func test_morningRoutine_hasExpectedSeeds() {
        let seeds = TemplatePresetSeeds.Preset.morningRoutine.seeds
        XCTAssertFalse(seeds.isEmpty)
        XCTAssertTrue(seeds.contains { $0.title == "Breakfast" })
    }

    func test_workday_hasDeepWork() {
        let seeds = TemplatePresetSeeds.Preset.workday.seeds
        XCTAssertTrue(seeds.contains { $0.title == "Deep work" })
    }

    func test_allCases_haveAtLeastOneSeed() {
        for preset in TemplatePresetSeeds.Preset.allCases {
            XCTAssertFalse(preset.seeds.isEmpty, "\(preset) should not be empty")
        }
    }

    func test_seeds_haveMonotonicStartTimes() {
        for preset in TemplatePresetSeeds.Preset.allCases {
            let starts = preset.seeds.map(\.startMinutesFromMidnight)
            let sorted = starts.sorted()
            XCTAssertEqual(starts, sorted, "\(preset) seeds should be in ascending start order")
        }
    }
}
