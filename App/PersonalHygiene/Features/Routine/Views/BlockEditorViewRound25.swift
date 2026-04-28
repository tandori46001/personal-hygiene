import SwiftUI

/// Round-25 slice T3.19 (deferred from round 24): per-block follow-up
/// override surface in BlockEditorView. Only renders when the block's
/// category is `.medication` and the block has a stable identifier
/// (`editingBlockID != nil`). New blocks need to be saved first; the
/// override applies on subsequent edits.
extension BlockEditorView {

    @ViewBuilder
    func followUpOverrideSection() -> some View {
        if viewModel.category == .medication, let blockID = viewModel.editingBlockID {
            FollowUpOverrideRow(blockID: blockID)
        }
    }
}

private struct FollowUpOverrideRow: View {
    let blockID: UUID
    @State private var selection: Int

    init(blockID: UUID) {
        self.blockID = blockID
        let stored = PerBlockFollowUpOverrideStore.minutes(for: blockID) ?? 0
        _selection = State(initialValue: stored)
    }

    var body: some View {
        Section {
            Picker(selection: $selection) {
                Text("blockEditor.followUp.useDefault", bundle: .main).tag(0)
                ForEach(MedicationFollowUpDelayStore.allowedMinutes, id: \.self) { value in
                    Text("blockEditor.followUp.minutes \(value)", bundle: .main).tag(value)
                }
            } label: {
                Text("blockEditor.followUp.title", bundle: .main)
            }
            .onChange(of: selection) { _, newValue in
                if newValue == 0 {
                    PerBlockFollowUpOverrideStore.set(nil, for: blockID)
                } else {
                    PerBlockFollowUpOverrideStore.set(newValue, for: blockID)
                }
            }
        } footer: {
            Text("blockEditor.followUp.footer", bundle: .main)
        }
    }
}
