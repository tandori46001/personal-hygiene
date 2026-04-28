import Foundation

/// Round-25 slice T8.55: extends the round-20 "everything bundle" with the
/// r25 helpers' surfaces (cache counters, archive count, mood streak,
/// recent error log). Returns a Markdown-flavored multiline string suitable
/// for clipboard paste into a bug report.
@MainActor
public enum DiagnosticsEverythingV2 {

    public static func render(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium

        var lines: [String] = []
        lines.append("# diagnostics.everythingV2")
        lines.append("captured_at: \(formatter.string(from: now))")
        lines.append("commit: \(BuildInfo.shortDescriptor)")
        lines.append("locale: \(Locale.current.identifier)")
        lines.append("i18n_keys: \(LocalizationKeyCount.total)")
        lines.append("")
        lines.append("## cache_counters")
        let counters = WeatherForecastCacheCounters.shared.snapshot
        lines.append("hits: \(counters.hits)")
        lines.append("misses: \(counters.misses)")
        lines.append("")
        lines.append("## archive")
        lines.append("archived_templates: \(TemplateArchiveStore.archivedIDs().count)")
        lines.append("")
        lines.append("## mood")
        lines.append("streak_days: \(MoodLogStore.streakDays())")
        lines.append("entries: \(MoodLogStore.entries().count)")
        lines.append("")
        lines.append("## refresh_trace")
        let traceCount = RefreshTraceLog.shared.entries.count
        lines.append("entries: \(traceCount)")
        if let last = RefreshTraceLog.shared.entries.last {
            lines.append("last_at: \(formatter.string(from: last.timestamp))")
            lines.append("last_count: \(last.scheduledCount)")
        }
        lines.append("")
        lines.append("## recent_errors")
        for line in DiagnosticsErrorLog.shared.recent(limit: 5) {
            lines.append("- \(line)")
        }
        return lines.joined(separator: "\n")
    }
}
