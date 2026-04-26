import PhotosUI
import SwiftUI

struct CoverPhotoSection: View {
    @Bindable var viewModel: TripDetailViewModel
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        Section {
            if let data = viewModel.trip.coverPhotoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
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

struct PackingListSection: View {
    @Bindable var viewModel: TripDetailViewModel
    @Binding var newItemTitle: String

    var body: some View {
        Section {
            ForEach(viewModel.sortedPackingItems) { item in
                Button {
                    viewModel.togglePackingItem(item)
                } label: {
                    HStack {
                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isPacked ? Color.green : Color.secondary)
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
                    viewModel.deletePackingItem(viewModel.sortedPackingItems[idx])
                }
            }

            HStack {
                TextField(
                    text: $newItemTitle,
                    prompt: Text("trip.packing.field.placeholder", bundle: .main)
                ) {
                    Text("trip.packing.field.label", bundle: .main)
                }
                Button {
                    viewModel.addPackingItem(title: newItemTitle)
                    newItemTitle = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(Text("trip.packing.action.add", bundle: .main))
                .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("trip.detail.section.packing", bundle: .main)
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

struct MarineSection: View {
    let viewModel: TripDetailViewModel

    var body: some View {
        if let service = viewModel.marineService,
           let lat = viewModel.trip.destinationLatitude,
           let lon = viewModel.trip.destinationLongitude {
            Section {
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
        }
    }
}

struct MilestoneRow: View {
    let milestone: TripMilestone
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
        }
    }
}

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
                Text(LocalizedStringKey("trip.document.kind.\(document.kind.rawValue)"))
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
