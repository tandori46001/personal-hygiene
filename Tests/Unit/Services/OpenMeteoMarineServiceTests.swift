@preconcurrency import XCTest

@testable import PersonalHygiene

final class OpenMeteoMarineServiceTests: XCTestCase {

    func test_parse_extractsAllFields() throws {
        let jsonString = """
            {
              "current": {
                "wave_height": 1.4,
                "wave_direction": 270,
                "wave_period": 6.2,
                "sea_surface_temperature": 18.1
              }
            }
            """
        let json = Data(jsonString.utf8)

        let result = try OpenMeteoMarineService.parse(json)

        XCTAssertEqual(result.waveHeightMeters, 1.4)
        XCTAssertEqual(result.waveDirectionDegrees, 270)
        XCTAssertEqual(result.wavePeriodSeconds, 6.2)
        XCTAssertEqual(result.seaSurfaceTemperatureCelsius, 18.1)
    }

    func test_parse_throwsOffshoreOnlyWhenAllNull() {
        let jsonString = """
            {
              "current": {
                "wave_height": null,
                "wave_direction": null,
                "wave_period": null,
                "sea_surface_temperature": null
              }
            }
            """
        let json = Data(jsonString.utf8)

        XCTAssertThrowsError(try OpenMeteoMarineService.parse(json)) { error in
            XCTAssertEqual(error as? MarineWeatherError, .offshoreOnly)
        }
    }

    func test_parse_throwsDecodingFailedOnGarbage() {
        let json = Data("not-json".utf8)
        XCTAssertThrowsError(try OpenMeteoMarineService.parse(json)) { error in
            XCTAssertEqual(error as? MarineWeatherError, .decodingFailed)
        }
    }
}
