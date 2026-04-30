import PDFKit
@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class TripPDFExporterTests: XCTestCase {

    private func tripFixture() -> Trip {
        let trip = Trip(
            name: "Mediterráneo",
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_500_000),
            destinationName: "Mallorca"
        )
        trip.milestones = [
            TripMilestone(title: "Buy currency", daysBefore: 7),
            TripMilestone(title: "Pack", daysBefore: 1, isComplete: true),
        ]
        trip.documents = [
            TripDocument(name: "Passport", kind: .passport, keychainItemID: "kc-1")
        ]
        return trip
    }

    func test_render_producesNonEmptyPDFData() {
        let trip = tripFixture()
        let bytes = TripPDFExporter.render(trip: trip)
        XCTAssertGreaterThan(bytes.count, 0)
        XCTAssertNotNil(PDFDocument(data: bytes))
    }

    func test_render_includesTripNameInPDF() throws {
        let trip = tripFixture()
        let bytes = TripPDFExporter.render(trip: trip)
        let pdf = try XCTUnwrap(PDFDocument(data: bytes))
        let combinedText = (0..<pdf.pageCount)
            .compactMap { pdf.page(at: $0)?.string }
            .joined(separator: "\n")
        XCTAssertTrue(combinedText.contains("Mediterráneo"))
        XCTAssertTrue(combinedText.contains("Mallorca"))
        XCTAssertTrue(combinedText.contains("Buy currency"))
        XCTAssertTrue(combinedText.contains("Passport"))
    }
}
