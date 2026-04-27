import SwiftUI

/// Round-12 helpers extracted from `TripDetailView` to keep the main view
/// type body under SwiftLint's 300-line cap.
struct TripDetailExportPayload: Identifiable {
    let id = UUID()
    let url: URL
}

extension TripDetailView {

    @ViewBuilder
    var tripActionMenu: some View {
        Menu {
            Button {
                exportPDF()
            } label: {
                Label {
                    Text("trip.action.share", bundle: .main)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            if viewModel.isStillActive() {
                Button(role: .destructive) {
                    showingArchiveConfirm = true
                } label: {
                    Label {
                        Text("trip.action.archive", bundle: .main)
                    } icon: {
                        Image(systemName: "archivebox")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel(Text("trip.action.menu", bundle: .main))
    }

    func exportPDF() {
        let bytes = TripPDFExporter.render(trip: viewModel.trip)
        let safeName = viewModel.trip.name
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let filename = "\(safeName.isEmpty ? "Trip" : safeName).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try bytes.write(to: url, options: .atomic)
            pendingExport = TripDetailExportPayload(url: url)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    func deleteMilestones(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.deleteMilestone(viewModel.sortedMilestones[idx])
        }
    }

    func deleteDocuments(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.deleteDocument(viewModel.sortedDocuments[idx])
        }
    }

    /// A milestone "has fired" when its computed notification trigger date
    /// (`tripStart - daysBefore` at 09:00 local) is in the past.
    func hasFired(_ milestone: TripMilestone) -> Bool {
        let cal = Calendar.autoupdatingCurrent
        let tripStart = viewModel.trip.startDate
        guard let triggerDay = cal.date(byAdding: .day, value: -milestone.daysBefore, to: tripStart) else {
            return false
        }
        let dayStart = cal.startOfDay(for: triggerDay)
        guard let triggerAtNine = cal.date(byAdding: .hour, value: 9, to: dayStart) else {
            return false
        }
        return triggerAtNine <= Date()
    }
}

/// Round-12 slice 9: notes section (Markdown rendered below the field).
struct TripNotesSection: View {
    @Bindable var viewModel: TripDetailViewModel

    var body: some View {
        Section {
            TextField(
                text: $viewModel.draftNotes,
                prompt: Text("trip.notes.placeholder", bundle: .main),
                axis: .vertical
            ) {
                Text("trip.notes.label", bundle: .main)
            }
            .lineLimit(3...8)
            if !viewModel.trip.notes.isEmpty {
                Text(.init(viewModel.trip.notes))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("trip.detail.section.notes", bundle: .main)
        } footer: {
            Text("trip.detail.section.notes.footer", bundle: .main)
        }
    }
}
