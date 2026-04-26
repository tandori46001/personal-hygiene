import AppIntents
import Foundation
import SwiftData

/// "Hey Siri, what's next?" → reads the user's active template and reports
/// the current or next block. Lives in the iOS app target so it can use the
/// same SwiftData container the UI uses.
struct WhatsNextIntent: AppIntent {

    static let title: LocalizedStringResource = "intent.whatsNext.title"
    static let description = IntentDescription(
        LocalizedStringResource("intent.whatsNext.description")
    )

    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try AppModelContainer.makeProduction()
        let context = ModelContext(container)
        let repo = SwiftDataRoutineRepository(context: context)

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let dayType = TodayViewModel.dayType(for: now, in: calendar)
        let template = try repo.activeTemplate(for: dayType)

        let dialog = WhatsNextDialogBuilder.build(template: template, at: now, calendar: calendar)
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

struct PersonalHygieneShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WhatsNextIntent(),
            phrases: [
                "What's next on \(.applicationName)",
                "\(.applicationName) qué toca ahora",
                "\(.applicationName) prochain bloc",
            ],
            shortTitle: "intent.whatsNext.shortTitle",
            systemImageName: "calendar"
        )
    }
}
