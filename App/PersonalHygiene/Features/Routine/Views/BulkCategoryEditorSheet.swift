import SwiftUI

/// Round-25 slice T5.29 (deferred from round 24): self-contained sheet
/// that lets the user pick a set of blocks + a target category, and then
/// applies the change in bulk via `BulkCategoryEditor.apply(...)`. Hosted
/// from TemplateEditorView's toolbar.
struct BulkCategoryEditorSheet: View {

    let blocks: [Block]
    let onApply: (Set<UUID>, BlockCategory) -> Void

    @State private var selected: Set<UUID> = []
    @State private var targetCategory: BlockCategory = .work
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $targetCategory) {
                        ForEach(BlockCategory.allCases, id: \.self) { category in
                            Text(localizedKey: "category.\(category.rawValue)").tag(category)
                        }
                    } label: {
                        Text("templateEditor.bulkEdit.category", bundle: .main)
                    }
                } header: {
                    Text("templateEditor.bulkEdit.targetSection", bundle: .main)
                }

                Section {
                    if blocks.isEmpty {
                        Text("templateEditor.bulkEdit.empty", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(blocks) { block in
                            blockRow(block)
                        }
                    }
                } header: {
                    Text(
                        "templateEditor.bulkEdit.selectedCount \(selected.count)",
                        bundle: .main
                    )
                }
            }
            .navigationTitle(Text("templateEditor.bulkEdit.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onApply(selected, targetCategory)
                        dismiss()
                    } label: {
                        Text("templateEditor.bulkEdit.apply", bundle: .main)
                    }
                    .disabled(selected.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func blockRow(_ block: Block) -> some View {
        Button {
            if selected.contains(block.id) {
                selected.remove(block.id)
            } else {
                selected.insert(block.id)
            }
        } label: {
            HStack {
                Image(systemName: selected.contains(block.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected.contains(block.id) ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading) {
                    Text(verbatim: block.title)
                        .font(.callout)
                    HStack(spacing: 4) {
                        Text(localizedKey: "category.\(block.category.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(verbatim: "·")
                            .foregroundStyle(.tertiary)
                        Text(verbatim: Self.formattedTime(minutes: block.startMinutesFromMidnight))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
    }

    static func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
