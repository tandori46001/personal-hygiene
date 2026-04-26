import SwiftUI

/// Maps each `BlockCategory` to a distinct SwiftUI `Color` for the small
/// indicator dot shown in Today + Templates rows. iOS-only because `Color` is
/// a SwiftUI symbol; the model itself stays platform-agnostic.
enum BlockCategoryColor {

    static func color(for category: BlockCategory) -> Color {
        switch category {
        case .hygiene: return .cyan
        case .meal: return .orange
        case .sport: return .green
        case .work: return .indigo
        case .medical: return .red
        case .shopping: return .yellow
        case .medication: return .pink
        case .social: return .purple
        case .kids: return .mint
        case .sleep: return .blue
        case .hydration: return .teal
        case .housekeeping: return .brown
        }
    }
}

/// Small filled circle (8 px) used as an at-a-glance category indicator on
/// row leading edges. Hidden from VoiceOver because the spoken category name
/// already follows.
struct BlockCategoryDot: View {
    let category: BlockCategory

    var body: some View {
        Circle()
            .fill(BlockCategoryColor.color(for: category))
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
    }
}
