import SwiftUI

/// Sheet used both to create a brand-new milestone and to edit an existing one.
struct MilestoneEditorView: View {

    enum Mode {
        case create
        case edit(TripMilestone)
    }

    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    let onCommit: (_ title: String, _ daysBefore: Int, _ isComplete: Bool) -> Void

    @State private var title: String
    @State private var daysBefore: Int
    @State private var isComplete: Bool

    init(
        mode: Mode,
        onCommit: @escaping (_ title: String, _ daysBefore: Int, _ isComplete: Bool) -> Void
    ) {
        self.mode = mode
        self.onCommit = onCommit
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _daysBefore = State(initialValue: 7)
            _isComplete = State(initialValue: false)
        case .edit(let milestone):
            _title = State(initialValue: milestone.title)
            _daysBefore = State(initialValue: milestone.daysBefore)
            _isComplete = State(initialValue: milestone.isComplete)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    text: $title,
                    prompt: Text("trip.milestone.field.title.placeholder", bundle: .main)
                ) {
                    Text("trip.milestone.field.title", bundle: .main)
                }

                Stepper(value: $daysBefore, in: 0...365) {
                    HStack {
                        Text("trip.milestone.field.daysBefore", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(daysBefore)")
                            .foregroundStyle(.secondary)
                    }
                }

                if case .edit = mode {
                    Toggle(isOn: $isComplete) {
                        Text("trip.milestone.field.isComplete", bundle: .main)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.cancel", bundle: .main)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onCommit(title, daysBefore, isComplete)
                        dismiss()
                    } label: {
                        Text("common.save", bundle: .main)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var navigationTitle: Text {
        switch mode {
        case .create: Text("trip.milestone.new.title", bundle: .main)
        case .edit: Text("trip.milestone.edit.title", bundle: .main)
        }
    }
}
