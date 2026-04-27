import Foundation

/// Maps a free-form destination string to the URL slug each foreign-affairs
/// site uses. Most sites accept a lowercased-hyphenated slug ("costa-rica"),
/// but a handful of common destinations have non-obvious slugs that the
/// auto-generator would miss (e.g. UK FCDO uses "the-united-states-of-america"
/// rather than "united-states"). We keep an override table for those + fall
/// back to the auto-slug for everything else.
public enum DestinationSlug {

    /// Naïve auto-slug: lowercase, replace non-alphanumeric runs with `-`,
    /// trim leading/trailing dashes. Usable for travel.gc.ca + most gov.uk
    /// pages.
    public static func auto(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    /// gov.uk uses a few non-obvious slugs for common destinations. Falls
    /// back to `auto(_:)` when the destination isn't in the override map.
    public static func ukFCDO(_ name: String) -> String {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "usa", "us", "united states", "america":
            return "the-united-states-of-america"
        case "uae", "u.a.e.":
            return "united-arab-emirates"
        case "uk", "united kingdom", "britain", "great britain":
            return "united-kingdom"
        case "south korea", "korea":
            return "south-korea"
        case "north korea":
            return "north-korea"
        case "ivory coast":
            return "cote-d-ivoire"
        case "vatican", "vatican city":
            return "vatican-city"
        default:
            return auto(name)
        }
    }

    /// travel.gc.ca uses the same auto-slug as gov.uk for most countries, but
    /// is more strict — non-existent slugs 404 hard. Same overrides where the
    /// difference matters.
    public static func canada(_ name: String) -> String {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "usa", "us", "united states", "america":
            return "united-states"
        case "uk", "united kingdom", "britain", "great britain":
            return "united-kingdom"
        default:
            return auto(name)
        }
    }

    /// Round-12 slice 5: smartraveller.gov.au uses lowercase-hyphenated
    /// slugs at `/destinations/<slug>`. Few overrides matter; the auto-slug
    /// covers most country pages.
    public static func australia(_ name: String) -> String {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "usa", "us", "united states", "america":
            return "united-states-america"
        case "uk", "united kingdom", "britain", "great britain":
            return "united-kingdom"
        case "uae", "u.a.e.":
            return "united-arab-emirates"
        default:
            return auto(name)
        }
    }
}
