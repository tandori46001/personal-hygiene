import SwiftUI

/// Wraps subviews horizontally and breaks to new rows when they don't fit.
/// Used by the AI-itinerary wizard's MultiSelectChips, the Today category
/// filter, and the Birthdays relationship filter. Pure SwiftUI Layout — iOS 16+.
///
/// `alignment` controls per-row horizontal positioning:
/// - `.leading` (default) — chips align to the left of each row.
/// - `.center` — chips center within each row, useful when the row count is
///   small enough to fit on one row (Birthdays = 5 chips) so the bar reads
///   centered.
/// - `.trailing` — opposite of leading.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(in: bounds.width, subviews: subviews)
        var y: CGFloat = bounds.minY
        for row in rows {
            let rowHeight = row.indices
                .map { subviews[$0].sizeThatFits(.unspecified).height }
                .max() ?? 0
            let totalWidth = row.indices.reduce(CGFloat(0)) { acc, idx in
                acc + subviews[idx].sizeThatFits(.unspecified).width
            } + spacing * CGFloat(max(0, row.indices.count - 1))
            var x: CGFloat
            switch alignment {
            case .center:
                x = bounds.minX + (bounds.width - totalWidth) / 2
            case .trailing:
                x = bounds.maxX - totalWidth
            default:
                x = bounds.minX
            }
            for idx in row.indices {
                let size = subviews[idx].sizeThatFits(.unspecified)
                subviews[idx].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
    }

    private func computeRows(in maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        var x: CGFloat = 0
        for (idx, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
                x = 0
            }
            rows[rows.count - 1].indices.append(idx)
            x += size.width + spacing
        }
        return rows
    }
}
