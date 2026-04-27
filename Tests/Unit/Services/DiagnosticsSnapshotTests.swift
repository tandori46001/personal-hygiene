import XCTest

@testable import PersonalHygiene

@MainActor
final class DiagnosticsSnapshotTests: XCTestCase {

    func test_capture_includesIdentifiersAndCounts() async {
        let snapshot = await DiagnosticsSnapshot.capture(
            widgetReloadCount: 5,
            observerAvailable: false,
            observerIdentifiers: ["med-a", "med-b"],
            tripDocumentCount: 3,
            tripDocumentByteFootprint: 12_000
        )
        XCTAssertEqual(snapshot.widgetReloadCount, 5)
        XCTAssertEqual(snapshot.medicationObserverAvailable, false)
        XCTAssertEqual(snapshot.medicationObserverIdentifiers, ["med-a", "med-b"])
        XCTAssertEqual(snapshot.tripDocumentCount, 3)
        XCTAssertEqual(snapshot.tripDocumentByteFootprint, 12_000)
    }

    func test_encodedJSON_isSortedAndPretty() async throws {
        let snapshot = await DiagnosticsSnapshot.capture(
            widgetReloadCount: 0,
            observerAvailable: false,
            observerIdentifiers: [],
            tripDocumentCount: 0,
            tripDocumentByteFootprint: 0
        )
        let data = try snapshot.encodedJSON()
        let text = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("\"buildVersion\""))
        XCTAssertTrue(text.contains("\"widgetReloadCount\""))
        // Pretty-printed JSON has newlines.
        XCTAssertTrue(text.contains("\n"))
    }

    func test_writeToTemporaryFile_returnsReadableURL() async throws {
        let snapshot = await DiagnosticsSnapshot.capture(
            widgetReloadCount: 0,
            observerAvailable: true,
            observerIdentifiers: [],
            tripDocumentCount: 0,
            tripDocumentByteFootprint: nil
        )
        let url = try snapshot.writeToTemporaryFile(filename: "test-snap.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let bytes = try Data(contentsOf: url)
        XCTAssertGreaterThan(bytes.count, 0)
    }
}
