import PhotosUI
import SwiftUI

/// Round 32 (K01): inline `Section { ... }` blocks from `TripDetailView.body`
/// extracted into `@ViewBuilder` properties so the parent view's body fits
/// under SwiftLint's `type_body_length` 300-line threshold without the
/// `// swiftlint:disable` paragraph that round 28 added. No behavior change —
/// purely structural decomposition. The sections still read the parent's
/// `@State` properties because extensions on the same type can access them.
extension TripDetailView {

    @ViewBuilder
    var summarySection: some View {
        Section {
            TextField(
                text: $viewModel.draftName,
                prompt: Text("trips.field.name.placeholder", bundle: .main)
            ) {
                Text("trips.field.name", bundle: .main)
            }
            LocationAutocompleteField(
                name: $viewModel.draftDestination,
                latitude: $viewModel.draftDestinationLatitude,
                longitude: $viewModel.draftDestinationLongitude
            )
            if viewModel.draftDestinationLatitude != nil {
                DestinationMapPreview(
                    name: viewModel.draftDestination,
                    latitude: viewModel.draftDestinationLatitude,
                    longitude: viewModel.draftDestinationLongitude
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
            DismissingDatePicker(selection: $viewModel.draftStartDate) {
                Text("trips.field.startDate", bundle: .main)
            }
            DismissingDatePicker(
                selection: $viewModel.draftEndDate,
                minimumDate: viewModel.draftStartDate
            ) {
                Text("trips.field.endDate", bundle: .main)
            }
        } header: {
            // Round 27 follow-up: explicit pencil icon in the section header
            // so the user understands the fields are tappable + editable.
            HStack(spacing: 6) {
                Image(systemName: "pencil.circle")
                    .foregroundStyle(.tint)
                Text("trip.detail.section.summary", bundle: .main)
            }
        } footer: {
            let days = viewModel.daysUntilDeparture()
            if days > 0 {
                Text("trip.detail.countdown.\(days)", bundle: .main)
            }
        }
    }

    @ViewBuilder
    func milestonesSection(milestoneSheet: Binding<MilestoneSheetState?>) -> some View {
        Section {
            if viewModel.sortedMilestones.isEmpty {
                Text("trip.detail.milestones.empty", bundle: .main)
                    .foregroundStyle(.secondary)
                Button {
                    viewModel.addStandardMilestoneBundle()
                } label: {
                    Label {
                        Text("trip.milestone.action.addBundle", bundle: .main)
                    } icon: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            } else {
                ForEach(viewModel.sortedMilestones) { milestone in
                    Button {
                        milestoneSheet.wrappedValue = .edit(milestone)
                    } label: {
                        MilestoneRow(
                            milestone: milestone,
                            hasFired: hasFired(milestone),
                            onToggle: { viewModel.toggleMilestoneCompletion(milestone) }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteMilestones)
            }
            Button {
                milestoneSheet.wrappedValue = .create
            } label: {
                Label {
                    Text("trip.milestone.action.add", bundle: .main)
                } icon: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        } header: {
            Text("trip.detail.section.milestones", bundle: .main)
        }
    }

    /// Round 35 IA redesign: collapses the round-12 `TripCompletionSection`
    /// and round-12 `NextMilestoneSection` into one "My progress" section.
    /// Both inner blocks are independently conditional — the section itself
    /// only renders when at least one of them has content, so a trip with no
    /// milestones and no packing items doesn't show an empty header.
    @ViewBuilder
    var progressSection: some View {
        let pct = viewModel.completionFraction()
        let next = viewModel.nextDueMilestone()
        if pct != nil || next != nil {
            Section {
                if let pct {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                            Text("trip.detail.completion.title", bundle: .main)
                                .font(.body.bold())
                            Spacer()
                            Text(verbatim: "\(Int(pct * 100))%")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: pct)
                            .tint(pct >= 1.0 ? .green : .accentColor)
                            .accessibilityLabel(
                                Text(LocalizedStringResource(
                                    "a11y.trip.completion \(Int(pct * 100))"
                                ))
                            )
                    }
                    .accessibilityElement(children: .combine)
                }
                if let next {
                    HStack(spacing: 10) {
                        Image(systemName: "flag.checkered")
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("trip.detail.nextMilestone.title", bundle: .main)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(next.title)
                                .font(.headline)
                            Text("trip.detail.nextMilestone.daysBefore.\(next.daysBefore)", bundle: .main)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.toggleMilestoneCompletion(next)
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text("today.action.markDone", bundle: .main))
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("trip.detail.section.progress", bundle: .main)
            }
        }
    }

    /// Round 35 IA redesign: collapses 4 single-row navigation sections
    /// (auto-itinerary, marine, currency, advisory) plus the wizard button
    /// into one "About your destination" section. Each row is independently
    /// gated by its required service/data; the section is always rendered
    /// because the wizard button is unconditional.
    @ViewBuilder
    func destinationInfoSection(showingWizard: Binding<Bool>) -> some View {
        Section {
            if let generator = viewModel.itineraryGenerator {
                NavigationLink {
                    ItineraryView(
                        trip: viewModel.trip,
                        generator: generator,
                        store: viewModel.itineraryStore
                    )
                } label: {
                    Label {
                        Text("trip.itinerary.title", bundle: .main)
                    } icon: {
                        Image(systemName: "wand.and.stars")
                    }
                }
            }
            // Round 27 WS-A: wizard works on every device via clipboard
            // fallback — no Apple Intelligence required.
            Button {
                showingWizard.wrappedValue = true
            } label: {
                Label {
                    Text("itinerary.wizard.entry", bundle: .main)
                } icon: {
                    Image(systemName: "sparkles.rectangle.stack")
                }
            }
            if let service = viewModel.marineService,
               let lat = viewModel.trip.destinationLatitude,
               let lon = viewModel.trip.destinationLongitude {
                NavigationLink {
                    MarineConditionsView(latitude: lat, longitude: lon, service: service)
                } label: {
                    Label {
                        Text("trip.marine.title", bundle: .main)
                    } icon: {
                        Image(systemName: "water.waves")
                    }
                }
            }
            if let currency = viewModel.currencyService {
                NavigationLink {
                    CurrencyView(service: currency)
                } label: {
                    Label {
                        Text("trip.currency.title", bundle: .main)
                    } icon: {
                        Image(systemName: "dollarsign.arrow.circlepath")
                    }
                }
            }
            if !viewModel.advisoryLinks.isEmpty {
                NavigationLink {
                    AdvisoryView(
                        links: viewModel.advisoryLinks,
                        destination: viewModel.trip.destinationName
                    )
                } label: {
                    Label {
                        Text("trip.advisory.title", bundle: .main)
                    } icon: {
                        Image(systemName: "exclamationmark.shield")
                    }
                }
            }
        } header: {
            Text("trip.detail.section.destinationInfo", bundle: .main)
        } footer: {
            Text("trip.detail.section.destinationInfo.footer", bundle: .main)
        }
    }

    @ViewBuilder
    func documentsSection(showingScanner: Binding<Bool>) -> some View {
        Section {
            if viewModel.sortedDocuments.isEmpty {
                Text("trip.detail.documents.empty", bundle: .main)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.sortedDocuments) { document in
                    if let store = viewModel.documentStore {
                        NavigationLink {
                            DocumentPreviewView(document: document, store: store)
                        } label: {
                            DocumentRow(document: document)
                        }
                    } else {
                        DocumentRow(document: document)
                    }
                }
                .onDelete(perform: deleteDocuments)
            }
            if viewModel.documentStore != nil {
                Button {
                    showingScanner.wrappedValue = true
                } label: {
                    Label {
                        Text("trip.document.action.scan", bundle: .main)
                    } icon: {
                        Image(systemName: "doc.viewfinder")
                    }
                }
            }
        } header: {
            Text("trip.detail.section.documents", bundle: .main)
        }
    }
}
