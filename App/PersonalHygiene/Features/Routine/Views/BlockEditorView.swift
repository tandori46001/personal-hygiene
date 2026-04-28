import SwiftUI

struct BlockEditorView: View {
    @Bindable var viewModel: BlockEditorViewModel
    let onSave: (BlockEditorViewModel) -> Void
    let onCancel: () -> Void
    /// Round-20 slice T4.20: optional provider returning up to 5 recent
    /// titles for the currently-selected category. When nil, the
    /// "Suggest from history" menu is hidden.
    var titleSuggestions: ((BlockCategory) -> [String])?

    @Environment(\.dismiss) private var dismiss
    @State private var showingDiscardConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $viewModel.title,
                        prompt: Text("blockEditor.field.title.placeholder", bundle: .main)
                    ) {
                        Text("blockEditor.field.title", bundle: .main)
                    }
                    Picker(selection: $viewModel.category) {
                        ForEach(BlockCategory.allCases, id: \.self) { category in
                            Text(localizedKey: "category.\(category.rawValue)").tag(category)
                        }
                    } label: {
                        Text("blockEditor.field.category", bundle: .main)
                    }
                    if let titleSuggestions {
                        let suggestions = titleSuggestions(viewModel.category)
                        if !suggestions.isEmpty {
                            Menu {
                                ForEach(suggestions, id: \.self) { title in
                                    Button {
                                        viewModel.title = title
                                    } label: {
                                        Text(verbatim: title)
                                    }
                                }
                            } label: {
                                Label {
                                    Text("blockEditor.action.suggest", bundle: .main)
                                } icon: {
                                    Image(systemName: "wand.and.stars")
                                }
                            }
                        }
                    }
                } header: {
                    Text("blockEditor.section.basics", bundle: .main)
                }

                Section {
                    HStack {
                        Text("blockEditor.field.startTime", bundle: .main)
                        Spacer()
                        Picker("", selection: $viewModel.startHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .accessibilityLabel(Text("a11y.startTime.hour", bundle: .main))
                        Text(verbatim: ":")
                            .accessibilityHidden(true)
                        Picker("", selection: $viewModel.startMinute) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .accessibilityLabel(Text("a11y.startTime.minute", bundle: .main))
                    }

                    Stepper(value: $viewModel.durationMinutes, in: 5...(24 * 60), step: 5) {
                        HStack {
                            Text("blockEditor.field.duration", bundle: .main)
                            Spacer()
                            Text(verbatim: "\(viewModel.durationMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("blockEditor.section.timing", bundle: .main)
                }

                Section {
                    Stepper(value: $viewModel.notificationLeadMinutes, in: 0...60, step: 5) {
                        HStack {
                            Text("blockEditor.field.leadTime", bundle: .main)
                            Spacer()
                            Text(verbatim: "\(viewModel.notificationLeadMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle(isOn: $viewModel.isDeepFocus) {
                        Text("blockEditor.field.deepFocus", bundle: .main)
                    }
                } header: {
                    Text("blockEditor.section.alerts", bundle: .main)
                } footer: {
                    let count = viewModel.category == .medication ? 2 : 1
                    Text("blockEditor.notifications.footer.\(count)", bundle: .main)
                }

                Section {
                    TextField(
                        text: $viewModel.locationName,
                        prompt: Text("blockEditor.field.locationName.placeholder", bundle: .main)
                    ) {
                        Text("blockEditor.field.locationName", bundle: .main)
                    }
                    .textInputAutocapitalization(.words)

                    TextField(
                        text: $viewModel.latitudeText,
                        prompt: Text(verbatim: "0.000000")
                    ) {
                        Text("blockEditor.field.latitude", bundle: .main)
                    }
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    TextField(
                        text: $viewModel.longitudeText,
                        prompt: Text(verbatim: "0.000000")
                    ) {
                        Text("blockEditor.field.longitude", bundle: .main)
                    }
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    if !viewModel.isLocationValid {
                        Text("blockEditor.field.location.invalid", bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("blockEditor.section.location", bundle: .main)
                } footer: {
                    Text("blockEditor.section.location.footer", bundle: .main)
                }

                Section {
                    TextField(
                        text: $viewModel.notes,
                        prompt: Text("blockEditor.field.notes.placeholder", bundle: .main),
                        axis: .vertical
                    ) {
                        Text("blockEditor.field.notes", bundle: .main)
                    }
                    .lineLimit(3...)
                } header: {
                    Text("blockEditor.section.notes", bundle: .main)
                }
            }
            .navigationTitle(
                viewModel.editingBlockID == nil
                    ? Text("blockEditor.title.new", bundle: .main)
                    : Text("blockEditor.title.edit", bundle: .main)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if viewModel.hasUnsavedChanges {
                            showingDiscardConfirm = true
                        } else {
                            onCancel()
                            dismiss()
                        }
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(viewModel)
                        dismiss()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
            .confirmationDialog(
                Text("blockEditor.discardChanges.title", bundle: .main),
                isPresented: $showingDiscardConfirm,
                titleVisibility: .visible,
                actions: {
                    Button(role: .destructive) {
                        onCancel()
                        dismiss()
                    } label: {
                        Text("blockEditor.discardChanges.action", bundle: .main)
                    }
                    Button(role: .cancel) {} label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
            )
        }
    }

}

#Preview("New") {
    BlockEditorView(viewModel: BlockEditorViewModel(), onSave: { _ in }, onCancel: {})
}

#Preview("Edit") {
    let block = Block(
        title: "Aseo",
        category: .hygiene,
        startMinutesFromMidnight: 7 * 60,
        durationMinutes: 30
    )
    BlockEditorView(viewModel: BlockEditorViewModel(editing: block), onSave: { _ in }, onCancel: {})
}
