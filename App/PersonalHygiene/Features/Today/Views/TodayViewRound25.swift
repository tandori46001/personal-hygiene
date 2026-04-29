import SwiftUI

/// Round-25 wires:
/// - T7.47 `quickJumpKeyboardItem`: ⌘N keyboard shortcut that scrolls to
///   the next active block (current → next → first).
/// - T7.49 `pullToRefreshHaptic`: a wrist-feedback haptic confirmation
///   played after `.refreshable` completes.
/// - T7.52 `longPressShowConflicts`: long-press handler that surfaces
///   the conflict overlap visualizer for the tapped block.
extension TodayView {

    @ToolbarContentBuilder
    var round25KeyboardItems: some ToolbarContent {
        // Round-25 slice T7.47: ⌘N jumps to the next active block.
        ToolbarItem(placement: .keyboard) {
            Button {
                let target = viewModel.nextBlock() ?? viewModel.currentBlock() ?? viewModel.blocks.first
                if let target {
                    NotificationCenter.default.post(
                        name: .todayJumpToBlock,
                        object: nil,
                        userInfo: ["blockID": target.id]
                    )
                }
            } label: {
                Text("today.shortcut.jumpNext", bundle: .main)
            }
            .keyboardShortcut("n", modifiers: .command)
            .opacity(0)
            .accessibilityHidden(true)
        }
    }

    /// Round-25 slice T7.49: triggers a tap haptic when pull-to-refresh
    /// completes. Caller invokes from the `.refreshable` closure.
    @MainActor
    static func playRefreshHaptic() {
        #if canImport(UIKit) && !os(watchOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }

    /// Round-25 slice T7.52: builds the conflict overlap state for the
    /// currently long-pressed block. Returns nil when no overlap exists.
    static func conflictOverlap(
        for block: Block,
        in blocks: [Block]
    ) -> BlockConflictOverlap.Overlap? {
        BlockConflictOverlap.overlaps(in: blocks).first { overlap in
            overlap.firstID == block.id || overlap.secondID == block.id
        }
    }
}

extension Notification.Name {
    static let todayJumpToBlock = Notification.Name("today.jumpToBlock")
}

extension TodayView {
    /// Round-25 diagnostic line shown beneath the empty-state description.
    /// Surfaces what the repository currently returns so we can tell
    /// whether `reload()` is finding the active template at all. Format:
    /// `dayType=weekday · count=2 · active=Weekday routine` (or
    /// `active=nil` when no match was found despite templates existing).
    @MainActor
    static func diagnosticLine(viewModel: TodayViewModel) -> String {
        let dayType = viewModel.todaysDayType.rawValue
        let activeName = viewModel.activeTemplate?.name ?? "nil"
        return "dayType=\(dayType) · active=\(activeName)"
    }
}
