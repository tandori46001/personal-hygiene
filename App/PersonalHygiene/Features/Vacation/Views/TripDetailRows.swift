import PhotosUI
import SwiftUI

@MainActor
struct CoverPhotoSection: View {
    @Bindable var viewModel: TripDetailViewModel
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        Section {
            if let data = viewModel.trip.coverPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel(Text("trip.cover.label", bundle: .main))
            }
            HStack {
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label {
                        Text(
                            viewModel.trip.coverPhotoData == nil
                                ? "trip.cover.action.choose"
                                : "trip.cover.action.replace",
                            bundle: .main
                        )
                    } icon: {
                        Image(systemName: "photo")
                    }
                }
                if viewModel.trip.coverPhotoData != nil {
                    Spacer()
                    Button(role: .destructive) {
                        viewModel.updateCoverPhoto(nil)
                    } label: {
                        Text("trip.cover.action.remove", bundle: .main)
                    }
                    .buttonStyle(.borderless)
                }
            }
        } header: {
            Text("trip.detail.section.cover", bundle: .main)
        }
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    let compressed = Self.compressForStorage(data)
                    await MainActor.run {
                        viewModel.updateCoverPhoto(compressed)
                        pickerItem = nil
                    }
                }
            }
        }
    }

    private static func compressForStorage(_ data: Data) -> Data {
        // Re-encode to JPEG at 0.7 quality so we don't bloat the SwiftData
        // store with multi-MB HEIC images straight from the picker.
        guard let image = UIImage(data: data) else { return data }
        return image.jpegData(compressionQuality: 0.7) ?? data
    }
}

// Round 35 IA redesign: `NextMilestoneSection` (round 12 callout) inlined
// into `progressSection` in TripDetailFormSections.swift. Deleted here.

@MainActor
struct PackingListSection: View {
    @Bindable var viewModel: TripDetailViewModel
    @Binding var newItemTitle: String
    @Binding var newItemCategory: PackingCategory

    var body: some View {
        Section {
            // Round 27 redesign: wrapping FlowLayout centered, no
            // horizontal scroll. Fixes "Other" decalado + chip clipping
            // on smaller widths. Mirrors Today + Birthdays chip style.
            FlowLayout(spacing: 6, alignment: .center) {
                PackingChip(
                    label: Text("trip.packing.filter.all", bundle: .main),
                    iconName: "tray.full",
                    isSelected: viewModel.packingCategoryFilter == nil
                ) {
                    viewModel.packingCategoryFilter = nil
                }
                ForEach(PackingCategory.allCases, id: \.self) { cat in
                    PackingChip(
                        label: Text(localizedKey: "trip.packing.category.\(cat.rawValue)"),
                        iconName: cat.systemImage,
                        isSelected: viewModel.packingCategoryFilter == cat
                    ) {
                        viewModel.packingCategoryFilter = (viewModel.packingCategoryFilter == cat) ? nil : cat
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            ForEach(viewModel.filteredSortedPackingItems) { item in
                Button {
                    viewModel.togglePackingItem(item)
                } label: {
                    HStack {
                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isPacked ? Color.green : Color.secondary)
                            .accessibilityHidden(true)
                        Image(systemName: item.category.systemImage)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(item.title)
                            .strikethrough(item.isPacked, color: .secondary)
                            .foregroundStyle(item.isPacked ? .secondary : .primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                for idx in offsets {
                    viewModel.deletePackingItem(viewModel.filteredSortedPackingItems[idx])
                }
            }

            HStack {
                TextField(
                    text: $newItemTitle,
                    prompt: Text("trip.packing.field.placeholder", bundle: .main)
                ) {
                    Text("trip.packing.field.label", bundle: .main)
                }
                // Round-27 fix: icon-only picker so "Other" doesn't get
                // squeezed into a 2-line vertical wrap when the TextField
                // is being typed into (the menu's button width was too
                // narrow to fit the longest category label).
                Picker(selection: $newItemCategory) {
                    ForEach(PackingCategory.allCases, id: \.self) { cat in
                        Label {
                            Text(localizedKey: "trip.packing.category.\(cat.rawValue)")
                        } icon: {
                            Image(systemName: cat.systemImage)
                        }
                        .tag(cat)
                    }
                } label: {
                    Image(systemName: newItemCategory.systemImage)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                Button {
                    let item = PackingItem(
                        title: newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: newItemCategory
                    )
                    if !item.title.isEmpty {
                        viewModel.trip.packingItems.append(item)
                        viewModel.saveEdits()
                    }
                    newItemTitle = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(Text("trip.packing.action.add", bundle: .main))
                .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            HStack {
                Text("trip.detail.section.packing", bundle: .main)
                Spacer()
                if !viewModel.trip.packingItems.isEmpty {
                    Menu {
                        Button {
                            viewModel.markAllPacked()
                        } label: {
                            Label {
                                Text("trip.packing.action.markAllPacked", bundle: .main)
                            } icon: {
                                Image(systemName: "checkmark.square")
                            }
                        }
                        Button(role: .destructive) {
                            viewModel.resetAllPacking()
                        } label: {
                            Label {
                                Text("trip.packing.action.resetAll", bundle: .main)
                            } icon: {
                                Image(systemName: "arrow.uturn.backward.square")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.tint)
                    }
                    .accessibilityLabel(Text("trip.packing.action.menu", bundle: .main))
                }
            }
        } footer: {
            if !viewModel.trip.packingItems.isEmpty {
                Text(
                    "trip.packing.summary.\(viewModel.packedCount).\(viewModel.trip.packingItems.count)",
                    bundle: .main
                )
            }
        }
    }
}

// Round 35 IA redesign: `TripCompletionSection` and `MarineSection` (both
// round 12 single-section structs) inlined into `progressSection` and
// `destinationInfoSection` respectively in TripDetailFormSections.swift.

@MainActor
struct MilestoneRow: View {
    let milestone: TripMilestone
    /// `true` when the milestone's notification trigger date is in the past
    /// (computed from `tripStart - daysBefore`). Used to mark "already
    /// notified" with a small bell glyph so the user can tell ahead-of-trip
    /// reminders apart from upcoming ones at a glance.
    var hasFired: Bool = false
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(milestone.isComplete ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                milestone.isComplete
                    ? Text("trip.milestone.action.unmarkDone", bundle: .main)
                    : Text("trip.milestone.action.markDone", bundle: .main)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.body)
                Text("trip.milestone.daysBefore.\(milestone.daysBefore)", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if hasFired && !milestone.isComplete {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.blue)
                    .accessibilityLabel(Text("trip.milestone.alreadyNotified", bundle: .main))
            }
        }
    }
}

@MainActor
struct DocumentRow: View {
    let document: TripDocument

    var body: some View {
        HStack {
            Image(systemName: documentIconName)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.body)
                Text(localizedKey: "trip.document.kind.\(document.kind.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var documentIconName: String {
        switch document.kind {
        case .passport: "person.text.rectangle"
        case .visa: "doc.text.below.ecg"
        case .insurance: "cross.case"
        case .ticket: "ticket"
        case .reservation: "bed.double"
        case .other: "doc"
        }
    }
}

private struct PackingChip: View {
    let label: Text
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.caption)
                label
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
            .overlay(Capsule().strokeBorder(borderColor, lineWidth: 1))
            .foregroundStyle(Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var background: Color {
        isSelected ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.12)
    }

    private var borderColor: Color {
        isSelected ? Color.accentColor : Color.clear
    }
}
