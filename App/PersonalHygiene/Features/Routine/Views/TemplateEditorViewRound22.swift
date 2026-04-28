import SwiftUI
import UIKit

/// Round-22 routine wires:
/// - T5.24 `csvImportFromClipboardButton`: parses the pasteboard via
///   `BlockCSVImporter.parse` and surfaces warnings via the host's
///   `csvImportWarnings` state binding.
/// - T5.26 `overlapGanttRow`: thin Gantt strip rendered above the
///   conflict overlap list.
/// - T5.29 `cascadeShiftRow`: stepper-driven `±N` minutes shift applied to
///   every block in the template.
extension TemplateEditorView {

    @ViewBuilder
    func csvImportFromClipboardButton(
        warningsBinding: Binding<[String]?>,
        errorBinding: Binding<String?>
    ) -> some View {
        Button {
            guard let pasted = UIPasteboard.general.string, !pasted.isEmpty else {
                errorBinding.wrappedValue = String(localized: "templateEditor.csvImport.empty")
                return
            }
            do {
                let warnings = try viewModel.importCSV(pasted)
                warningsBinding.wrappedValue = warnings
            } catch {
                errorBinding.wrappedValue = error.localizedDescription
            }
        } label: {
            Label {
                Text("templateEditor.csvImport.action", bundle: .main)
            } icon: {
                Image(systemName: "doc.on.clipboard")
            }
        }
    }

    @ViewBuilder
    func overlapGanttRow() -> some View {
        if !viewModel.sortedBlocks.isEmpty {
            Section {
                BlockOverlapGanttView(blocks: viewModel.sortedBlocks)
                    .padding(.vertical, 4)
            } header: {
                Text("templateEditor.gantt.title", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func cascadeShiftRow(errorBinding: Binding<String?>) -> some View {
        if viewModel.sortedBlocks.count >= 2 {
            Section {
                HStack {
                    Button {
                        do {
                            try viewModel.cascadeShift(byMinutes: -15)
                        } catch {
                            errorBinding.wrappedValue = error.localizedDescription
                        }
                    } label: {
                        Label {
                            Text("templateEditor.cascadeShift.minus", bundle: .main)
                        } icon: {
                            Image(systemName: "minus.circle")
                        }
                    }
                    Spacer()
                    Button {
                        do {
                            try viewModel.cascadeShift(byMinutes: 15)
                        } catch {
                            errorBinding.wrappedValue = error.localizedDescription
                        }
                    } label: {
                        Label {
                            Text("templateEditor.cascadeShift.plus", bundle: .main)
                        } icon: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            } header: {
                Text("templateEditor.cascadeShift.title", bundle: .main)
            } footer: {
                Text("templateEditor.cascadeShift.footer", bundle: .main)
            }
        }
    }
}

/// Round-22 slice T5.25: bottom sheet listing the warnings emitted by the
/// CSV importer. Hidden when warnings are nil; dismissed by tap.
struct CSVImportWarningsSheet: View {
    let warnings: [String]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if warnings.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("templateEditor.csvImport.warnings.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                        }
                    } description: {
                        Text("templateEditor.csvImport.warnings.empty.description", bundle: .main)
                    }
                } else {
                    Section {
                        ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(verbatim: warning)
                                    .font(.caption.monospaced())
                            }
                        }
                    } header: {
                        Text("templateEditor.csvImport.warnings.title", bundle: .main)
                    }
                }
            }
            .navigationTitle(Text("templateEditor.csvImport.action", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onDismiss) {
                        Text("common.done", bundle: .main)
                    }
                }
            }
        }
    }
}
