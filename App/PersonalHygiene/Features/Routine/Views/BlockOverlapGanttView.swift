import SwiftUI

/// Round-22 slice T5.26: tiny graphical Gantt-style strip showing each
/// block's time span across a 24h horizon. Overlapping segments render in
/// red so the user can see the collision at a glance — the round-21
/// textual "A ↔ B · 30 min" line lives alongside this.
struct BlockOverlapGanttView: View {

    let blocks: [Block]

    private var sortedBlocks: [Block] {
        blocks.sorted { $0.startMinutesFromMidnight < $1.startMinutesFromMidnight }
    }

    private var conflicts: Set<UUID> {
        BlockConflictDetector.conflictingIDs(in: blocks)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.06))
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                ForEach(sortedBlocks) { block in
                    let frac = Double(block.startMinutesFromMidnight) / Double(24 * 60)
                    let widthFrac = max(0.005, Double(block.durationMinutes) / Double(24 * 60))
                    let isConflict = conflicts.contains(block.id)
                    Rectangle()
                        .fill(isConflict ? Color.red.opacity(0.7) : Color.accentColor.opacity(0.55))
                        .frame(width: max(2, width * widthFrac), height: 12)
                        .offset(x: width * frac)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
        }
        .frame(height: 14)
        .accessibilityLabel(Text("templateEditor.gantt.a11y", bundle: .main))
    }
}
