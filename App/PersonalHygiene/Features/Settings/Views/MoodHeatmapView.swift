import SwiftUI

/// Round-23 slice T2.12: 7-column calendar heatmap. Cells with no entry
/// render as faint placeholders; cells with a score render in a green
/// gradient by score. Disclosed under "Mood log" in Settings.
struct MoodHeatmapView: View {

    let rows: [MoodHeatmapAggregator.Row]
    var cellSize: CGFloat = 14
    var cornerRadius: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { column in
                        let cell = column < row.cells.count ? row.cells[column] : nil
                        cellView(for: cell)
                    }
                }
            }
        }
        .accessibilityLabel(Text("settings.moodLog.heatmap.a11y", bundle: .main))
    }

    @ViewBuilder
    private func cellView(for cell: MoodHeatmapAggregator.Cell?) -> some View {
        let cornerShape = RoundedRectangle(cornerRadius: cornerRadius)
        if let cell, let score = cell.score {
            cornerShape
                .fill(Color.green.opacity(0.18 + 0.18 * (score - 1) / 4))
                .frame(width: cellSize, height: cellSize)
        } else {
            cornerShape
                .fill(Color.secondary.opacity(0.07))
                .frame(width: cellSize, height: cellSize)
        }
    }
}
