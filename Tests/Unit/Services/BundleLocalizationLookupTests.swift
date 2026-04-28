@testable import PersonalHygiene
import SwiftUI
import XCTest

/// Round-19 / L006 guard tests. SwiftUI's `Text(LocalizedStringKey("foo.\(x)"))`
/// converts the interpolation into a `%@` placeholder and looks up
/// `"foo.%@"`, not the runtime key. These tests don't exercise SwiftUI
/// directly (it would require a render harness) — instead they confirm the
/// resolved lookup against `Bundle.main` works for every dynamic-key shape
/// the app uses, so a future refactor that reintroduces the bug is caught.
@MainActor
final class BundleLocalizationLookupTests: XCTestCase {

    /// Each `BlockCategory.rawValue` must resolve to a non-key value via
    /// the `Text(localizedKey:)` codepath (`NSLocalizedString`), confirming
    /// the xcstrings file holds the discrete-suffix translations.
    func test_blockCategory_discreteSuffixKeysResolve() {
        for category in BlockCategory.allCases {
            let key = "category.\(category.rawValue)"
            let resolved = NSLocalizedString(key, bundle: .main, value: key, comment: "")
            XCTAssertNotEqual(resolved, key, "Missing translation for \(key) — UI will render the raw key.")
        }
    }

    /// Same for housekeeping recurrence, day type, packing category, document
    /// kind, and birthday relationship — every other enum the app surfaces.
    func test_otherEnumDiscreteSuffixKeysResolve() {
        let cases: [(prefix: String, values: [String])] = [
            ("housekeeping.recurrence.", HousekeepingRecurrence.allCases.map(\.rawValue)),
            ("dayType.", DayType.allCases.map(\.rawValue)),
            ("trip.packing.category.", PackingCategory.allCases.map(\.rawValue)),
            ("trip.document.kind.", TripDocumentKind.allCases.map(\.rawValue)),
            ("birthdays.relationship.", BirthdayRelationship.allCases.map(\.rawValue)),
            ("settings.backup.autoFrequency.", BackupAutoFrequencyStore.Frequency.allCases.map(\.rawValue)),
        ]
        for (prefix, values) in cases {
            for value in values {
                let key = "\(prefix)\(value)"
                let resolved = NSLocalizedString(key, bundle: .main, value: key, comment: "")
                XCTAssertNotEqual(resolved, key, "Missing translation for \(key) — UI will render the raw key.")
            }
        }
    }

    /// Round-19 extension: discrete-suffix keys for the *integer*-driven
    /// dynamic lookups (snooze duration, follow-up override, marine
    /// freshness). These aren't enum-backed but the source of truth lives
    /// in the corresponding store's `allowedMinutes` / `allowedHours` array.
    func test_integerSuffixKeysResolve() {
        let cases: [(prefix: String, values: [Int])] = [
            ("settings.snooze.duration.", SnoozeDurationStore.allowedMinutes),
            ("settings.medication.followup.", MedicationFollowUpDelayStore.allowedMinutes),
            ("settings.marine.freshness.", MarineForecastFreshnessStore.allowedHours),
        ]
        for (prefix, values) in cases {
            for value in values {
                let key = "\(prefix)\(value)"
                let resolved = NSLocalizedString(key, bundle: .main, value: key, comment: "")
                XCTAssertNotEqual(resolved, key, "Missing translation for \(key) — UI will render the raw key.")
            }
        }
    }

    /// Round-19 extension: discrete-suffix keys for the round-14 / round-17
    /// surfaces — pending-notifications source headers, mute categories,
    /// template-presets and their toast variants.
    func test_round17_18_discreteSuffixKeysResolve() {
        let cases: [(prefix: String, values: [String])] = [
            ("settings.pendingNotifications.source.", BlockSnoozeSource.allCases.map(\.rawValue)),
            ("settings.mute.", NotificationCategoryMuteStore.Category.allCases.map(\.rawValue)),
            ("templateEditor.preset.", TemplatePresetSeeds.Preset.allCases.map(\.rawValue)),
            ("templateEditor.preset.inserted.", TemplatePresetSeeds.Preset.allCases.map(\.rawValue)),
        ]
        for (prefix, values) in cases {
            for value in values {
                let key = "\(prefix)\(value)"
                let resolved = NSLocalizedString(key, bundle: .main, value: key, comment: "")
                XCTAssertNotEqual(resolved, key, "Missing translation for \(key) — UI will render the raw key.")
            }
        }
    }

    /// Format-string keys (with `%lld` / `%@` placeholders) must exist with
    /// the *matching format suffix* SwiftUI looks up at runtime, not the
    /// bare key. These are the patterns the app uses with
    /// `Text("foo \(int)", bundle: .main)` or `LocalizedStringResource`.
    func test_formatStringKeysExist() {
        let formatKeys = [
            "birthdays.daysUntil %lld",
            "birthdays.lead.preview %@",
            "a11y.birthdays.leadPreview %@",
            "hydration.action.add %lld",
            "sleep.deficit %lld",
            "a11y.trip.packing %lld %lld",
        ]
        for key in formatKeys {
            let resolved = NSLocalizedString(key, bundle: .main, value: key, comment: "")
            XCTAssertNotEqual(resolved, key, "Missing format key \(key) — UI will render the raw key.")
        }
    }
}
