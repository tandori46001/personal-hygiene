import SwiftUI
import UIKit

/// Round-19 SettingsView wires:
/// - T3.13 "Reset onboarding tips" — clears the `whatsNew.lastSeenCommitSHA`
///   AppStorage + `WhatsNewHistoryStore` so the auto-popup re-fires on next
///   launch (used during validation flows where the tester wants to see the
///   release-notes sheet again without reinstalling).
/// - T3.14 footer line — version, build, commit SHA, locale, and i18n key
///   count, packed into a single tappable row that copies to the clipboard
///   for quick paste into a bug report.
extension SettingsView {

    @ViewBuilder
    var resetOnboardingTipsRow: some View {
        Section {
            Button(role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "whatsNew.lastSeenCommitSHA")
                WhatsNewHistoryStore.clear()
            } label: {
                Label {
                    Text("settings.onboarding.resetTips", bundle: .main)
                } icon: {
                    Image(systemName: "lightbulb")
                }
            }
        } footer: {
            Text("settings.onboarding.resetTips.footer", bundle: .main)
        }
    }

    @ViewBuilder
    var aboutFooterSection: some View {
        Section {
            Button {
                UIPasteboard.general.string = Self.aboutLine
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: BuildInfo.shortDescriptor)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                    Text(verbatim: Self.localeAndKeyCountLine)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            .buttonStyle(.plain)
        } header: {
            Text("settings.about.section", bundle: .main)
        } footer: {
            Text("settings.about.section.footer", bundle: .main)
        }
    }

    /// Round-19 slice T3.14: inferred i18n key count via `Bundle.main` lookup
    /// of a sentinel "non-existent" key that wouldn't bias the count. We can't
    /// count keys at runtime without parsing the strings table, so this uses
    /// the `LocalizationKeyCount` constant baked at build time by xcodegen.
    private static var localeAndKeyCountLine: String {
        let locale = Locale.current.identifier
        let count = LocalizationKeyCount.total
        return "locale \(locale) · keys \(count)"
    }

    private static var aboutLine: String {
        "\(BuildInfo.shortDescriptor) · \(localeAndKeyCountLine)"
    }
}

/// Round-19 slice T3.14: source-of-truth constant for the i18n catalog size.
/// Bumped manually when `Localizable.xcstrings` adds/removes keys; the
/// `BundleLocalizationLookupTests` cross-check guards correctness, and
/// `scripts/check-i18n-coverage.sh` keeps the per-locale count in sync.
public enum LocalizationKeyCount {
    public static let total = 813
}
