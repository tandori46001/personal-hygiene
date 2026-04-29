import Foundation
import SwiftData

/// Round 27 WS-B B5: first-launch population of `ImportantDay` from a
/// per-locale JSON bundle (`Resources/ImportantDays/{es,en,fr}.json`).
/// Idempotent — bails out without inserting anything if the table is
/// already non-empty, so user customizations never get clobbered.
public enum ImportantDaySeeder {

    /// Single seed entry as it appears in the JSON bundle. Mirrors
    /// `ImportantDay` minus the persisted-only fields.
    public struct Seed: Decodable, Sendable, Equatable {
        public let name: String
        public let rule: DayRule
    }

    /// Returns the set of seeds for the given locale identifier (e.g. "es",
    /// "en", "fr"). Falls back to "en" if the requested locale has no
    /// bundle. Returns empty if even the fallback can't load.
    public static func seeds(
        for languageCode: String,
        bundle: Bundle = .main
    ) -> [Seed] {
        if let direct = load(languageCode: languageCode, bundle: bundle) {
            return direct
        }
        return load(languageCode: "en", bundle: bundle) ?? []
    }

    private static func load(languageCode: String, bundle: Bundle) -> [Seed]? {
        guard
            let url = bundle.url(
                forResource: languageCode,
                withExtension: "json",
                subdirectory: "ImportantDays"
            ) ?? bundle.url(
                forResource: languageCode,
                withExtension: "json"
            )
        else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([Seed].self, from: data)
    }

    /// Inserts seeds into the model context if the `ImportantDay` table is
    /// empty. No-op otherwise — existing rows + user customizations are
    /// preserved across launches.
    @MainActor
    public static func seedIfEmpty(
        in context: ModelContext,
        languageCode: String = Locale.current.language.languageCode?.identifier ?? "en",
        regionCode: String? = Locale.current.region?.identifier,
        bundle: Bundle = .main
    ) {
        let descriptor = FetchDescriptor<ImportantDay>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        for seed in seeds(for: languageCode, bundle: bundle) {
            let day = ImportantDay(
                name: seed.name,
                dayRule: seed.rule,
                localeRegion: regionCode,
                enabled: true,
                isCustom: false
            )
            context.insert(day)
        }
        try? context.save()
    }
}
