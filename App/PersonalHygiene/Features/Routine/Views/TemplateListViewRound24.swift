import SwiftUI

/// Round-24 routine wires:
/// - T5.25 `showArchivedToolbarButton`: toggle that flips a host @State so
///   the list re-renders with archived templates visible.
/// - T5.26 archive swipe action (rendered alongside the round-21 duplicate
///   swipe). Both rows surface from a helper `archiveSwipeAction(...)`.
/// - T5.27 + T5.28 helpers + restore button.
extension TemplateListView {

    @ViewBuilder
    func showArchivedToolbarButton(showingArchived: Binding<Bool>) -> some View {
        Button {
            showingArchived.wrappedValue.toggle()
        } label: {
            Label {
                Text(
                    showingArchived.wrappedValue
                        ? "templateList.archived.hide"
                        : "templateList.archived.show",
                    bundle: .main
                )
            } icon: {
                Image(systemName: showingArchived.wrappedValue ? "eye" : "archivebox")
            }
        }
    }

    @ViewBuilder
    func archiveSwipeAction(for template: RoutineTemplate) -> some View {
        let isArchived = TemplateArchiveStore.isArchived(template.id)
        Button {
            TemplateArchiveStore.setArchived(!isArchived, for: template.id)
        } label: {
            Label {
                Text(
                    isArchived
                        ? "templateList.action.unarchive"
                        : "templateList.action.archive",
                    bundle: .main
                )
            } icon: {
                Image(systemName: isArchived ? "tray.and.arrow.up" : "archivebox")
            }
        }
        .tint(.indigo)
    }

    /// Round-24 slice T5.27: filter helper used by the host body. When
    /// `showingArchived` is `false`, archived templates are hidden; when
    /// `true`, they are surfaced with a faded badge.
    static func filterTemplates(
        _ templates: [RoutineTemplate],
        showingArchived: Bool
    ) -> [RoutineTemplate] {
        let archivedIDs = TemplateArchiveStore.archivedIDs()
        if showingArchived { return templates }
        return templates.filter { !archivedIDs.contains($0.id) }
    }

    /// Round-24 slice T5.28: badge text rendered next to an archived
    /// template's name in the list. Returns nil for non-archived rows.
    static func archivedBadgeText(for template: RoutineTemplate) -> String? {
        TemplateArchiveStore.isArchived(template.id) ? "📁" : nil
    }
}
