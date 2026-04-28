import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Round-18 slices 18+19+20 wires for `DiagnosticsView`:
/// - tap-to-copy on the existing pending-by-group identifier rows;
/// - export pending-by-group as CSV (one row per identifier);
/// - export a one-pager PDF bundling snapshot + last 50 refresh-trace +
///   last 10 auth-timeline entries.
extension DiagnosticsView {

    /// Round-18 wires: CSV + PDF export rows. Sits inside the existing
    /// `advancedDisclosureSection` (round-10) at the very bottom.
    @ViewBuilder
    var round18ExportSection: some View {
        Section {
            Button {
                let csv = Self.pendingByGroupCSV(pendingDetails: pendingDetails)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("pending-by-group-\(Int(Date().timeIntervalSince1970)).csv")
                try? csv.data(using: .utf8)?.write(to: url, options: .atomic)
                snapshotExportURL = url
            } label: {
                Label {
                    Text("settings.diagnostics.exportPendingCSV", bundle: .main)
                } icon: {
                    Image(systemName: "tablecells")
                }
            }
            .disabled(pendingDetails.isEmpty)

            Button {
                let pdf = Self.onePagerPDF(
                    snapshotHistory: snapshotHistory,
                    refreshTrace: refreshTrace,
                    authTimeline: authTimeline
                )
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("diagnostics-one-pager-\(Int(Date().timeIntervalSince1970)).pdf")
                try? pdf.write(to: url, options: .atomic)
                snapshotExportURL = url
            } label: {
                Label {
                    Text("settings.diagnostics.exportOnePagerPDF", bundle: .main)
                } icon: {
                    Image(systemName: "doc.richtext")
                }
            }
        }
    }

    /// Round-18 slice 19: serialize the current `pendingDetails` list to a
    /// CSV string with header `category,identifier,triggerDate`. Empty when
    /// nothing pending. Used by the share-sheet button below.
    static func pendingByGroupCSV(
        pendingDetails: [DiagnosticsSnapshot.PendingNotificationSummary]
    ) -> String {
        let grouped = PendingNotificationsGroup.grouped(pendingDetails.map(\.identifier))
        var lines = ["category,identifier,triggerDate"]
        let triggerByID = Dictionary(uniqueKeysWithValues:
            pendingDetails.map { ($0.identifier, $0.triggerDate) }
        )
        let formatter = ISO8601DateFormatter()
        for entry in grouped {
            for identifier in entry.identifiers {
                let triggerString = triggerByID[identifier]
                    .flatMap { $0.map(formatter.string(from:)) } ?? ""
                let escaped = identifier.replacingOccurrences(of: ",", with: ";")
                lines.append("\(entry.category.rawValue),\(escaped),\(triggerString)")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Round-18 slice 20: assemble a single-page PDF that bundles the most
    /// useful pieces of the diagnostics snapshot for sharing as one artifact.
    /// Returns the PDF bytes; the caller writes them to a tmp file + share.
    @MainActor
    static func onePagerPDF(
        snapshotHistory: [DiagnosticsSnapshot],
        refreshTrace: [RefreshTraceLog.Entry],
        authTimeline: [NotificationAuthTimelineLog.Entry]
    ) -> Data {
        #if canImport(UIKit) && !os(watchOS)
        let pageSize = CGSize(width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { ctx in
            drawOnePagerContents(
                ctx: ctx,
                pageSize: pageSize,
                snapshotHistory: snapshotHistory,
                refreshTrace: refreshTrace,
                authTimeline: authTimeline
            )
        }
        #else
        return Data()
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    private static func drawOnePagerContents(
        ctx: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        snapshotHistory: [DiagnosticsSnapshot],
        refreshTrace: [RefreshTraceLog.Entry],
        authTimeline: [NotificationAuthTimelineLog.Entry]
    ) {
        ctx.beginPage()
        let title = NSString(string: "Diagnostics one-pager")
        title.draw(at: CGPoint(x: 36, y: 36), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 18),
        ])

        let header = NSString(string:
            "Build: \(BuildInfo.shortDescriptor)\n"
            + "Captured: \(Date().formatted(date: .abbreviated, time: .standard))"
        )
        header.draw(at: CGPoint(x: 36, y: 60), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
        ])

        var cursorY: CGFloat = 110
        cursorY = drawSection(
            title: "Snapshot history (last \(min(3, snapshotHistory.count)))",
            rows: snapshotHistory.prefix(3).map { snap in
                "\(snap.snapshotAt.formatted(date: .abbreviated, time: .shortened))"
                + "  build \(snap.commitSHA)  pending \(snap.pendingCount)"
            },
            origin: CGPoint(x: 36, y: cursorY),
            pageSize: pageSize
        )
        cursorY += 12
        cursorY = drawSection(
            title: "Refresh trace (last 50)",
            rows: refreshTrace.prefix(50).map { entry in
                "\(entry.timestamp.formatted(date: .omitted, time: .standard))"
                + "  \(entry.kind.rawValue)  scheduled=\(entry.scheduledCount)"
            },
            origin: CGPoint(x: 36, y: cursorY),
            pageSize: pageSize
        )
        cursorY += 12
        _ = drawSection(
            title: "Auth timeline (last 10)",
            rows: authTimeline.prefix(10).map { entry in
                "\(entry.timestamp.formatted(date: .abbreviated, time: .shortened))"
                + "  status=\(entry.statusRawValue)"
            },
            origin: CGPoint(x: 36, y: cursorY),
            pageSize: pageSize
        )
    }
    #endif

    #if canImport(UIKit) && !os(watchOS)
    private static func drawSection(
        title: String,
        rows: [String],
        origin: CGPoint,
        pageSize: CGSize
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
        ]
        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Menlo", size: 9) ?? UIFont.systemFont(ofSize: 9),
        ]
        var y = origin.y
        let titleNS = NSString(string: title)
        titleNS.draw(at: CGPoint(x: origin.x, y: y), withAttributes: titleAttrs)
        y += 16
        let lineHeight: CGFloat = 11
        let bottomMargin: CGFloat = 36
        for row in rows {
            if y + lineHeight > pageSize.height - bottomMargin { break }
            let rowNS = NSString(string: row)
            rowNS.draw(at: CGPoint(x: origin.x, y: y), withAttributes: rowAttrs)
            y += lineHeight
        }
        return y
    }
    #endif
}
