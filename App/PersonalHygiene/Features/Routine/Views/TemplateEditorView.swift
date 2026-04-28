import SwiftUI

struct TemplateEditorView: View {
    @Bindable var viewModel: TemplateEditorViewModel

    @State private var blockEditor: BlockEditorViewModel?
    @State private var editingExistingBlock: Block?
    @State private var errorMessage: String?
    @State private var undoToastTimer: Task<Void, Never>?
    @State private var lastInsertedPresetTitleKey: String?
    /// Round-22 slice T5.25: warnings list emitted by the CSV importer.
    /// Non-nil = sheet visible.
    @State private var csvImportWarnings: [String]?
    /// Round-25 slice T5.29: bulk-category editor sheet visibility.
    @State private var showingBulkCategorySheet = false

    var body: some View {
        Form {
            Section {
                TextField(
                    text: $viewModel.name,
                    prompt: Text("templateEditor.field.name.placeholder", bundle: .main)
                ) {
                    Text("templateEditor.field.name", bundle: .main)
                }
                Picker(selection: $viewModel.dayType) {
                    ForEach(DayType.allCases, id: \.self) { dayType in
                        Text(localizedKey: "dayType.\(dayType.rawValue)").tag(dayType)
                    }
                } label: {
                    Text("templateEditor.field.dayType", bundle: .main)
                }
            } header: {
                Text("templateEditor.section.metadata", bundle: .main)
            }

            Section {
                if viewModel.sortedBlocks.isEmpty {
                    Text("templateEditor.empty", bundle: .main)
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.sortedBlocks) { block in
                    let conflicts = BlockConflictDetector.conflictingIDs(in: viewModel.sortedBlocks)
                    Button {
                        editingExistingBlock = block
                        blockEditor = BlockEditorViewModel(editing: block)
                    } label: {
                        BlockSummaryRow(block: block, hasConflict: conflicts.contains(block.id))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            do { try viewModel.duplicate(block) } catch {
                                errorMessage = error.localizedDescription
                            }
                        } label: {
                            Label {
                                Text("templateEditor.action.duplicateBlock", bundle: .main)
                            } icon: {
                                Image(systemName: "plus.square.on.square")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteBlocks)
                .onMove(perform: moveBlocks)

                Button {
                    editingExistingBlock = nil
                    blockEditor = BlockEditorViewModel()
                } label: {
                    Label {
                        Text("templateEditor.action.addBlock", bundle: .main)
                    } icon: {
                        Image(systemName: "plus.circle")
                    }
                }

                Menu {
                    ForEach(TemplatePresetSeeds.Preset.allCases, id: \.self) { preset in
                        Button {
                            do {
                                try viewModel.insertPreset(preset)
                                showUndoToast(for: preset)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        } label: {
                            Text(localizedKey: "templateEditor.preset.\(preset.rawValue)")
                        }
                    }
                } label: {
                    Label {
                        Text("templateEditor.action.insertPreset", bundle: .main)
                    } icon: {
                        Image(systemName: "wand.and.stars")
                    }
                }

                if viewModel.sortedBlocks.count >= 2 {
                    // Round-20 slice T4.18: collapse manual-edit gaps by
                    // re-anchoring every block back-to-back from the current
                    // first start time.
                    Button {
                        do { try viewModel.renumberStartTimes() } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Label {
                            Text("templateEditor.action.renumber", bundle: .main)
                        } icon: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                        }
                    }
                }

                // Round-22 slice T5.24: paste a CSV from clipboard +
                // surface warnings via the round-22 sheet.
                csvImportFromClipboardButton(
                    warningsBinding: $csvImportWarnings,
                    errorBinding: $errorMessage
                )

                // Round-25 slice T5.29: bulk-category edit. Hidden when
                // the template has fewer than 2 blocks (nothing to bulk-
                // edit).
                if viewModel.sortedBlocks.count >= 2 {
                    Button {
                        showingBulkCategorySheet = true
                    } label: {
                        Label {
                            Text("templateEditor.bulkEdit.action", bundle: .main)
                        } icon: {
                            Image(systemName: "checklist")
                        }
                    }
                }

                if let key = lastInsertedPresetTitleKey {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text(localizedKey: "templateEditor.preset.inserted.\(key)")
                            .font(.caption)
                        Spacer()
                        Button {
                            do {
                                try viewModel.undoLastPresetInsertion()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            cancelUndoToast()
                        } label: {
                            Text("common.undo", bundle: .main)
                        }
                        .buttonStyle(.borderless)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("templateEditor.section.blocks", bundle: .main)
            } footer: {
                // Round-15 slice 27: total duration footer.
                if !viewModel.sortedBlocks.isEmpty {
                    let totalMinutes = TemplateDurationCalculator.totalMinutes(viewModel.sortedBlocks)
                    let formatted = TemplateDurationCalculator.formatted(totalMinutes)
                    let blockCount = viewModel.sortedBlocks.count
                    Text(
                        "templateEditor.section.blocks.footer \(formatted) \(blockCount)",
                        bundle: .main
                    )
                    .font(.caption)
                }
            }
        }
        .navigationTitle(viewModel.template.name.isEmpty ? "" : viewModel.template.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    saveMetadata()
                } label: {
                    Text("common.save", bundle: .main)
                }
                .disabled(!viewModel.isValid)
            }
        }
        .sheet(item: $blockEditor) { editor in
            BlockEditorView(
                viewModel: editor,
                onSave: { saveBlock(from: $0) },
                onCancel: {},
                titleSuggestions: { viewModel.titleSuggestions(for: $0) }
            )
        }
        // Round-22 slice T5.25: warnings sheet for the CSV import flow.
        .sheet(
            isPresented: Binding(
                get: { csvImportWarnings != nil },
                set: { if !$0 { csvImportWarnings = nil } }
            )
        ) {
            CSVImportWarningsSheet(
                warnings: csvImportWarnings ?? [],
                onDismiss: { csvImportWarnings = nil }
            )
        }
        // Round-25 slice T5.29: bulk category edit sheet.
        .sheet(isPresented: $showingBulkCategorySheet) {
            BulkCategoryEditorSheet(blocks: viewModel.sortedBlocks) { selectedIDs, category in
                applyBulkCategory(ids: selectedIDs, category: category)
            }
        }
        .alert(
            Text("common.error", bundle: .main),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: { Button(action: { errorMessage = nil }, label: { Text("common.ok", bundle: .main) }) },
            message: { Text(errorMessage ?? "") }
        )
    }

    /// Round-18 slice 8: shows the inserted-preset toast for 4s, then dismisses.
    private func showUndoToast(for preset: TemplatePresetSeeds.Preset) {
        lastInsertedPresetTitleKey = preset.rawValue
        undoToastTimer?.cancel()
        undoToastTimer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled {
                lastInsertedPresetTitleKey = nil
            }
        }
    }

    private func cancelUndoToast() {
        undoToastTimer?.cancel()
        undoToastTimer = nil
        lastInsertedPresetTitleKey = nil
    }

    private func saveMetadata() {
        do {
            try viewModel.saveMetadata()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveBlock(from editor: BlockEditorViewModel) {
        do {
            if let existing = editingExistingBlock {
                try viewModel.update(existing, with: editor)
            } else {
                try viewModel.add(editor.snapshot())
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteBlocks(at offsets: IndexSet) {
        let blocks = viewModel.sortedBlocks
        for index in offsets {
            do {
                try viewModel.delete(blocks[index])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func moveBlocks(from source: IndexSet, to destination: Int) {
        do {
            try viewModel.move(fromOffsets: source, toOffset: destination)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Round-25 slice T5.29: bridges `BulkCategoryEditorSheet`'s onApply
    /// to the view-model's persisted bulk-category helper.
    private func applyBulkCategory(ids: Set<UUID>, category: BlockCategory) {
        do {
            try viewModel.applyBulkCategory(ids: ids, category: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}

private struct BlockSummaryRow: View {
    let block: Block
    var hasConflict: Bool = false

    var body: some View {
        HStack {
            BlockCategoryDot(category: block.category)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(block.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if hasConflict {
                        Label {
                            Text("templateEditor.conflict.chip", bundle: .main)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.orange)
                        .accessibilityLabel(Text("templateEditor.conflict.chip", bundle: .main))
                    }
                }
                Text(localizedKey: "category.\(block.category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(startDate, format: .dateTime.hour().minute())
                    .font(.system(.body, design: .monospaced))
                Text(verbatim: "\(block.durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var startDate: Date {
        let calendar = Calendar.current
        let components = DateComponents(
            hour: block.startMinutesFromMidnight / 60,
            minute: block.startMinutesFromMidnight % 60
        )
        return calendar.date(from: components) ?? Date()
    }
}

@MainActor
extension BlockEditorViewModel: Identifiable {
    nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
}
