import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Renders a `Trip` to a single-file PDF summary: cover page, milestones,
/// and a documents inventory. Returns the PDF as bytes so the caller can
/// hand it to `UIActivityViewController` or save it.
///
/// iOS-only: uses `UIGraphicsPDFRenderer` which isn't part of watchOS UIKit.
/// The file is excluded from the watchOS targets via `#if`.
@MainActor
public enum TripPDFExporter {

    public static func render(trip: Trip, calendar: Calendar = .autoupdatingCurrent) -> Data {
        let pageSize = CGSize(width: 612, height: 792)  // US Letter (PDFKit default).
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        return renderer.pdfData { context in
            context.beginPage()
            var cursor = drawCover(trip: trip, in: pageSize, calendar: calendar)
            cursor = drawMilestones(trip: trip, in: pageSize, startingAt: cursor, context: context)
            _ = drawDocuments(trip: trip, in: pageSize, startingAt: cursor, context: context)
        }
    }

    // MARK: - Sections

    private static func drawCover(trip: Trip, in pageSize: CGSize, calendar: Calendar) -> CGFloat {
        var cursor = margin
        // Cover photo banner: full-bleed at top of page, capped at 200pt
        // height so the title block always fits below it on US-Letter.
        if let data = trip.coverPhotoData, let image = UIImage(data: data) {
            let bannerHeight: CGFloat = 200
            let bannerRect = CGRect(
                x: margin,
                y: margin,
                width: pageSize.width - 2 * margin,
                height: bannerHeight
            )
            image.draw(in: bannerRect)
            cursor = margin + bannerHeight + 16
        }

        let title = trip.name as NSString
        title.draw(
            at: CGPoint(x: margin, y: cursor),
            withAttributes: titleAttributes
        )
        cursor += 36

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let lines = [
            "Destination: \(trip.destinationName)",
            "From \(formatter.string(from: trip.startDate)) to \(formatter.string(from: trip.endDate))",
        ]
        for line in lines {
            (line as NSString).draw(
                at: CGPoint(x: margin, y: cursor),
                withAttributes: bodyAttributes
            )
            cursor += 22
        }
        return cursor + 16
    }

    private static func drawMilestones(
        trip: Trip,
        in pageSize: CGSize,
        startingAt initialY: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var cursor = initialY
        cursor = drawHeader("Milestones", at: cursor, pageSize: pageSize, context: context)

        if trip.milestones.isEmpty {
            ("No milestones" as NSString).draw(
                at: CGPoint(x: margin, y: cursor),
                withAttributes: bodyAttributes
            )
            return cursor + 22
        }

        let sorted = trip.milestones.sorted { $0.daysBefore > $1.daysBefore }
        for milestone in sorted {
            cursor = newPageIfNeeded(cursor: cursor, pageSize: pageSize, context: context)
            let mark = milestone.isComplete ? "[x]" : "[ ]"
            let line = "\(mark) \(milestone.title) — \(milestone.daysBefore)d before"
            (line as NSString).draw(
                at: CGPoint(x: margin, y: cursor),
                withAttributes: bodyAttributes
            )
            cursor += 22
        }
        return cursor + 16
    }

    private static func drawDocuments(
        trip: Trip,
        in pageSize: CGSize,
        startingAt initialY: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var cursor = initialY
        cursor = drawHeader("Documents", at: cursor, pageSize: pageSize, context: context)

        if trip.documents.isEmpty {
            ("No documents stored" as NSString).draw(
                at: CGPoint(x: margin, y: cursor),
                withAttributes: bodyAttributes
            )
            return cursor + 22
        }

        let sorted = trip.documents.sorted { $0.addedAt > $1.addedAt }
        for document in sorted {
            cursor = newPageIfNeeded(cursor: cursor, pageSize: pageSize, context: context)
            let line = "• \(document.name) (\(document.kind.rawValue))"
            (line as NSString).draw(
                at: CGPoint(x: margin, y: cursor),
                withAttributes: bodyAttributes
            )
            cursor += 22
        }
        return cursor
    }

    // MARK: - Helpers

    private static let margin: CGFloat = 48
    private static let bottomMargin: CGFloat = 60

    private static let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 28),
        .foregroundColor: UIColor.black,
    ]
    private static let headerAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 16),
        .foregroundColor: UIColor.black,
    ]
    private static let bodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.black,
    ]

    private static func drawHeader(
        _ text: String,
        at cursor: CGFloat,
        pageSize: CGSize,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var nextCursor = newPageIfNeeded(cursor: cursor, pageSize: pageSize, context: context)
        (text as NSString).draw(
            at: CGPoint(x: margin, y: nextCursor),
            withAttributes: headerAttributes
        )
        nextCursor += 26
        return nextCursor
    }

    private static func newPageIfNeeded(
        cursor: CGFloat,
        pageSize: CGSize,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        if cursor + 40 > pageSize.height - bottomMargin {
            context.beginPage()
            return margin
        }
        return cursor
    }
}
#endif
