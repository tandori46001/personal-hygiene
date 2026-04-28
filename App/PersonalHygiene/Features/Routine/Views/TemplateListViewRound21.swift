import SwiftUI

/// Round-21 wires:
/// - T4.24 `searchSuggestionsRow`: when the user has typed a search term,
///   surface up to 5 recent block titles from `BlockTitleSuggestions` as
///   tap-to-fill chips. Lives above the templates list.
extension TemplateListView {

    @ViewBuilder
    func searchSuggestionsRow(
        searchText: String,
        templates: [RoutineTemplate],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let suggestions = TemplateListView.titleSuggestions(matching: trimmed, in: templates)
            if !suggestions.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    onSelect(suggestion)
                                } label: {
                                    Text(verbatim: suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Color.accentColor.opacity(0.12),
                                            in: Capsule()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("templateList.search.suggestions", bundle: .main)
                }
            }
        }
    }

    /// Round-21 slice T4.24: distinct block titles across every category that
    /// contain `query` (case-insensitive). Capped to 5 to keep the chip row
    /// scannable.
    static func titleSuggestions(
        matching query: String,
        in templates: [RoutineTemplate],
        limit: Int = 5
    ) -> [String] {
        let needle = query.lowercased()
        var seen: Set<String> = []
        var result: [String] = []
        for template in templates.reversed() {
            for block in template.sortedBlocks.reversed() {
                let title = block.title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty,
                      title.lowercased().contains(needle),
                      !seen.contains(title)
                else { continue }
                seen.insert(title)
                result.append(title)
                if result.count >= limit { return result }
            }
        }
        return result
    }
}
