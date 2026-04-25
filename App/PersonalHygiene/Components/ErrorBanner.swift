import SwiftUI

/// A compact inline banner used to surface a recoverable error to the user
/// from inside a `List` or `Form` section.
struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?

    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .font(.callout)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Label {
                        Text("common.dismiss", bundle: .main)
                    } icon: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("common.dismiss", bundle: .main))
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
