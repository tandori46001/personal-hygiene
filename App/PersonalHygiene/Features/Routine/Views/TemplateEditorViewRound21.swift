import SwiftUI

/// Round-21 routine wires:
/// - T4.19 `conflictOverlapList`: textual list of overlapping pairs with
///   minute counts. Surfaces above the block list when at least one pair
///   overlaps.
/// - T4.22 `csvImportButton`: paste a CSV via UIPasteboard and insert the
///   parsed blocks. Warnings (skipped rows, fallback categories) surface in
///   a confirmation sheet.
extension TemplateEditorView {

    @ViewBuilder
    func conflictOverlapList() -> some View {
        let overlaps = BlockConflictOverlap.overlaps(in: viewModel.sortedBlocks)
        if !overlaps.isEmpty {
            let titleByID = Dictionary(
                uniqueKeysWithValues: viewModel.sortedBlocks.map { ($0.id, $0.title) }
            )
            Section {
                ForEach(overlaps, id: \.firstID) { overlap in
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text(verbatim: BlockConflictOverlap.summary(
                            for: overlap,
                            titleByID: titleByID
                        ))
                        .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("templateEditor.conflicts.title", bundle: .main)
            } footer: {
                Text("templateEditor.conflicts.footer", bundle: .main)
            }
        }
    }
}
