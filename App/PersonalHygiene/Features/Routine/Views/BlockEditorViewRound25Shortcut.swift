import SwiftUI

/// Round-25 slice T7.50: ⌘⇧D keyboard shortcut for the block editor that
/// signals to the host TemplateEditor it should duplicate the currently
/// edited block. The shortcut posts a notification rather than mutating
/// state directly so the host can decide policy (allowed in active
/// templates only, etc.).
extension BlockEditorView {

    @ToolbarContentBuilder
    var round25DuplicateShortcut: some ToolbarContent {
        ToolbarItem(placement: .keyboard) {
            Button {
                if let blockID = viewModel.editingBlockID {
                    NotificationCenter.default.post(
                        name: .blockEditorDuplicateRequested,
                        object: nil,
                        userInfo: ["blockID": blockID]
                    )
                }
            } label: {
                Text("blockEditor.shortcut.duplicate", bundle: .main)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .opacity(0)
            .accessibilityHidden(true)
        }
    }
}

extension Notification.Name {
    static let blockEditorDuplicateRequested = Notification.Name("blockEditor.duplicate")
}
