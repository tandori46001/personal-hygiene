import SwiftUI

struct TemplateEditorView: View {
    @Bindable var viewModel: TemplateEditorViewModel

    @State private var blockEditor: BlockEditorViewModel?
    @State private var editingExistingBlock: Block?
    @State private var errorMessage: String?

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
                        Text(localizedDayType(dayType)).tag(dayType)
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
                    Button {
                        editingExistingBlock = block
                        blockEditor = BlockEditorViewModel(editing: block)
                    } label: {
                        BlockSummaryRow(block: block)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteBlocks)

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
            } header: {
                Text("templateEditor.section.blocks", bundle: .main)
            }
        }
        .navigationTitle(viewModel.template.name.isEmpty ? "" : viewModel.template.name)
        .toolbar {
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
                onCancel: {}
            )
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

    private func localizedDayType(_ dayType: DayType) -> LocalizedStringKey {
        LocalizedStringKey("dayType.\(dayType.rawValue)")
    }
}

private struct BlockSummaryRow: View {
    let block: Block

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey("category.\(block.category.rawValue)"))
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
