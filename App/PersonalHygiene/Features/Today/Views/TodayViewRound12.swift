import SwiftUI

/// Round-12 slice 23: horizontal scroll chips for filtering today by category.
struct CategoryFilterChips: View {
    @Binding var selected: BlockCategory?
    let blocks: [Block]

    private var availableCategories: [BlockCategory] {
        Array(Set(blocks.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button {
                    selected = nil
                } label: {
                    Text("today.filter.all", bundle: .main)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(selected == nil ? .accentColor : .secondary)
                ForEach(availableCategories, id: \.self) { cat in
                    Button {
                        selected = cat
                    } label: {
                        Text(LocalizedStringKey("category.\(cat.rawValue)"))
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(selected == cat ? .accentColor : .secondary)
                }
            }
        }
    }
}
