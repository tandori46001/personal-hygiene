import SwiftUI

struct TemplateListView: View {
    @Bindable var viewModel: TemplateListViewModel
    let repository: any RoutineRepository
    /// When set to `true` from the outside, auto-presents the new-template
    /// sheet on next render. Used by Today empty-state CTA to land directly
    /// on the form. Reset to `false` after presenting.
    var autoPresentNewTemplate: Binding<Bool>?

    @State private var showingNewTemplateSheet = false
    @State private var newTemplateName = ""
    @State private var newTemplateDayType: DayType = .weekday
    @State private var pendingDelete: RoutineTemplate?

    var body: some View {
        // L004: no inner `NavigationStack`. This view is a tab-root inside
        // iOS 18 TabView's "More" overflow, which already wraps its content
        // in a stack — adding a second one produced two stacked back chevrons
        // on every push into TemplateEditorView. Round-12 slice 6 captured
        // this regression via the new `scripts/check-tabroots.py` audit.
        List {
            if viewModel.templates.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("templateList.empty.title", bundle: .main)
                    } icon: {
                        Image(systemName: "calendar.badge.plus")
                    }
                } description: {
                    Text("templateList.empty.description", bundle: .main)
                }
            }

            ForEach(viewModel.templates) { template in
                NavigationLink {
                    TemplateEditorView(
                        viewModel: TemplateEditorViewModel(template: template, repository: repository)
                    )
                } label: {
                    TemplateRow(
                        template: template,
                        onActivate: { viewModel.setActive(template, for: template.dayType) }
                    )
                }
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.duplicate(template)
                    } label: {
                        Label {
                            Text("templateList.action.duplicate", bundle: .main)
                        } icon: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    .tint(.blue)
                }
            }
            .onDelete(perform: deleteTemplates)
        }
        .navigationTitle(Text("templateList.title", bundle: .main))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewTemplateSheet = true
                } label: {
                    Label {
                        Text("a11y.action.addTemplate", bundle: .main)
                    } icon: {
                        Image(systemName: "plus")
                    }
                    .labelStyle(.iconOnly)
                }
                .accessibilityLabel(Text("a11y.action.addTemplate", bundle: .main))
            }
        }
        .onAppear {
            viewModel.reload()
            if autoPresentNewTemplate?.wrappedValue == true {
                showingNewTemplateSheet = true
                autoPresentNewTemplate?.wrappedValue = false
            }
        }
        .onChange(of: autoPresentNewTemplate?.wrappedValue ?? false) { _, newValue in
            if newValue {
                showingNewTemplateSheet = true
                autoPresentNewTemplate?.wrappedValue = false
            }
        }
        .sheet(isPresented: $showingNewTemplateSheet) {
            NewTemplateSheet(
                name: $newTemplateName,
                dayType: $newTemplateDayType,
                onCreate: createTemplate,
                onCancel: { showingNewTemplateSheet = false }
            )
        }
        .confirmationDialog(
            Text(deleteConfirmKey, bundle: .main),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { template in
            Button(role: .destructive) {
                viewModel.delete(template)
                pendingDelete = nil
            } label: {
                Text("common.delete", bundle: .main)
            }
            Button(role: .cancel) {
                pendingDelete = nil
            } label: {
                Text("common.cancel", bundle: .main)
            }
        }
    }

    private func createTemplate() {
        let name = newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        _ = viewModel.createTemplate(name: name, dayType: newTemplateDayType)
        newTemplateName = ""
        newTemplateDayType = .weekday
        showingNewTemplateSheet = false
    }

    private func deleteTemplates(at offsets: IndexSet) {
        // Stage the first template only — confirmation dialog gates the actual
        // delete. Multi-row swipe is rare and we'd rather confirm one at a time
        // than auto-confirm the rest.
        if let index = offsets.first {
            pendingDelete = viewModel.templates[index]
        }
    }

    private var deleteConfirmKey: LocalizedStringKey {
        let name = pendingDelete?.name ?? ""
        let count = pendingDelete?.blocks.count ?? 0
        return "templateList.delete.confirm.title \(name) \(count)"
    }
}

private struct TemplateRow: View {
    let template: RoutineTemplate
    let onActivate: () -> Void

    /// Round-18 slice 7: compact summary string "Start–End · N blocks · Total Xh".
    private var summary: String? {
        let blocks = template.sortedBlocks
        guard let first = blocks.first, let last = blocks.last else { return nil }
        let endMinutes = last.startMinutesFromMidnight + last.durationMinutes
        let totalMinutes = TemplateDurationCalculator.totalMinutes(blocks)
        let totalString = TemplateDurationCalculator.formatted(totalMinutes)
        let startStr = Self.format(minutes: first.startMinutesFromMidnight)
        let endStr = Self.format(minutes: endMinutes)
        return "\(startStr)–\(endStr) · \(blocks.count) · \(totalString)"
    }

    private static func format(minutes: Int) -> String {
        let bounded = min(24 * 60 - 1, max(0, minutes))
        let hours = bounded / 60
        let mins = bounded % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.body)
                Text(localizedKey: "dayType.\(template.dayType.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let summary {
                    Text(verbatim: summary)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if template.isActive {
                Label {
                    Text("templateList.active", bundle: .main)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.green)
                .accessibilityLabel(Text("a11y.template.active", bundle: .main))
            } else {
                Button(action: onActivate) {
                    Text("templateList.action.activate", bundle: .main)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
    }
}

private struct NewTemplateSheet: View {
    @Binding var name: String
    @Binding var dayType: DayType
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    text: $name,
                    prompt: Text("templateList.new.name.placeholder", bundle: .main)
                ) {
                    Text("templateList.new.name", bundle: .main)
                }
                Picker(selection: $dayType) {
                    ForEach(DayType.allCases, id: \.self) { type in
                        Text(localizedKey: "dayType.\(type.rawValue)").tag(type)
                    }
                } label: {
                    Text("templateList.new.dayType", bundle: .main)
                }
            }
            .navigationTitle(Text("templateList.new.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onCreate) {
                        Text("common.create", bundle: .main)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
