import SwiftUI

/// Bottom sheet shown when the user taps a block in `TodayView`. Surfaces
/// title + start + duration + category + optional medication concept +
/// quick actions (mark done / skip today). Round-11 addition.
struct BlockDetailSheet: View {

    let block: Block
    let isDone: Bool
    let isSkipped: Bool
    let onToggleDone: () -> Void
    let onToggleSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                actionsSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.done", bundle: .main)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var infoSection: some View {
        Section {
            LabeledContent {
                Text(verbatim: Self.formattedTime(minutes: block.startMinutesFromMidnight))
                    .font(.system(.body, design: .monospaced))
            } label: {
                Text("blockDetail.label.start", bundle: .main)
            }
            LabeledContent {
                Text(verbatim: "\(block.durationMinutes) min")
            } label: {
                Text("blockDetail.label.duration", bundle: .main)
            }
            LabeledContent {
                Text(LocalizedStringKey("category.\(block.category.rawValue)"))
            } label: {
                Text("blockDetail.label.category", bundle: .main)
            }
            if let concept = block.medicationConceptIdentifier, !concept.isEmpty {
                LabeledContent {
                    Text(verbatim: concept)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                } label: {
                    Text("blockDetail.label.medicationConcept", bundle: .main)
                }
            }
            if block.isDeepFocus {
                Label {
                    Text("today.focus.deep", bundle: .main)
                } icon: {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.purple)
                }
            }
        } header: {
            Text(block.title)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            Button {
                onToggleDone()
                dismiss()
            } label: {
                Label {
                    Text(
                        isDone ? "today.action.unmarkDone" : "today.action.markDone",
                        bundle: .main
                    )
                } icon: {
                    Image(systemName: isDone ? "arrow.uturn.backward" : "checkmark.circle")
                }
            }
            .disabled(isSkipped)
            Button(role: .destructive) {
                onToggleSkip()
                dismiss()
            } label: {
                Label {
                    Text(
                        isSkipped ? "today.action.unskipToday" : "today.action.skipToday",
                        bundle: .main
                    )
                } icon: {
                    Image(systemName: "moon.zzz")
                }
            }
            // Round-18 slice 11: medication-aware skip with explicit "skip
            // this dose" wording so the user understands the follow-up
            // notification will be suppressed (skipping the block strips
            // the followup from the day's schedule via NotificationCoordinator).
            if block.medicationConceptIdentifier != nil, !isDone {
                Button(role: .destructive) {
                    if !isSkipped { onToggleSkip() }
                    dismiss()
                } label: {
                    Label {
                        Text("today.action.skipDose", bundle: .main)
                    } icon: {
                        Image(systemName: "pills.circle")
                    }
                }
                .disabled(isSkipped)
            }
        }
    }

    static func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
