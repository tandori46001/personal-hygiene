import Foundation

/// Round-25: moved from `App/PersonalHygiene/Features/Settings/...` into
/// `Shared/` so widget + watch + diagnostics targets (which only compile
/// `Shared/`) can read the value. Bumped manually when
/// `Localizable.xcstrings` adds/removes keys; the
/// `BundleLocalizationLookupTests` cross-check guards correctness, and
/// `scripts/check-i18n-coverage.sh` keeps the per-locale count in sync.
public enum LocalizationKeyCount {
    public static let total = 997
}
