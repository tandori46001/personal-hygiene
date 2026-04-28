import SwiftUI

/// Round-19 fix for the SwiftUI gotcha where
/// `Text(LocalizedStringKey("prefix.\(rawValue)"))` (or the same with
/// `LocalizedStringResource`) treats the runtime interpolation as a `%@`
/// placeholder. SwiftUI then looks up the format key `"prefix.%@"`, fails,
/// and falls back to rendering the formatted string verbatim — so the user
/// sees raw keys like `category.work` or `housekeeping.recurrence.weekly`.
///
/// `Text(localizedKey:)` resolves the runtime-built key against
/// `Bundle.main` via `NSLocalizedString`, then renders the resolved string
/// as `verbatim` so SwiftUI doesn't try to re-interpret it. Use anywhere
/// the lookup key is constructed dynamically (typically from an enum's
/// `rawValue`).
public extension Text {
    init(localizedKey key: String, bundle: Bundle = .main) {
        let resolved = NSLocalizedString(key, bundle: bundle, value: key, comment: "")
        self.init(verbatim: resolved)
    }
}
