import SwiftUI

/// Drop-in replacement for `DatePicker(.compact)` that auto-closes its
/// graphical popover when the user picks a date. iOS's stock compact
/// picker leaves the popover open until the user taps outside, which
/// reads as broken UX in modal sheets where the next field is right
/// below. This wrapper opens a popover-presented `.graphical` picker
/// and dismisses it as soon as `selection` changes.
///
/// Designed for use inside `Form` rows. Mirrors the native compact look
/// (label on the left, formatted-date pill on the right) so existing
/// trip sheets read identically.
struct DismissingDatePicker<Label: View>: View {

    @Binding var selection: Date
    var displayedComponents: DatePicker.Components = .date
    /// When non-nil, restricts the picker to dates `>=` this value. Mirrors
    /// the `in: someDate...` partial-range form `DatePicker` accepts natively.
    var minimumDate: Date?
    @ViewBuilder var label: () -> Label

    @State private var isPresented = false

    var body: some View {
        LabeledContent {
            Button {
                isPresented = true
            } label: {
                Text(selection, format: .dateTime.day().month(.abbreviated).year())
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .background(
                        Color(uiColor: .tertiarySystemFill),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPresented) {
                pickerContent
                    .presentationCompactAdaptation(.popover)
            }
        } label: {
            label()
        }
    }

    @ViewBuilder
    private var pickerContent: some View {
        Group {
            if let minimumDate {
                DatePicker(
                    "",
                    selection: $selection,
                    in: minimumDate...,
                    displayedComponents: displayedComponents
                )
            } else {
                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: displayedComponents
                )
            }
        }
        .datePickerStyle(.graphical)
        .labelsHidden()
        .padding()
        .onChange(of: selection) { _, _ in
            isPresented = false
        }
    }
}
