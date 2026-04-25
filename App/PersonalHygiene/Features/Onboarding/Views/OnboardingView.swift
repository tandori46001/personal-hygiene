import SwiftUI

struct OnboardingView: View {
    let repository: any RoutineRepository
    let onComplete: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("onboarding.welcome.title", bundle: .main)
                    .font(.largeTitle.bold())
                Text("onboarding.welcome.body", bundle: .main)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    seedAndContinue()
                } label: {
                    Text("onboarding.action.start", bundle: .main)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
            .alert(
                Text("common.error", bundle: .main),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                actions: { Button(action: { errorMessage = nil }, label: { Text("common.ok", bundle: .main) }) },
                message: { Text(errorMessage ?? "") }
            )
        }
    }

    private func seedAndContinue() {
        do {
            try seedDefaultTemplates()
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func seedDefaultTemplates() throws {
        let weekday = RoutineTemplate(
            name: NSLocalizedString("onboarding.template.weekday", comment: ""),
            dayType: .weekday,
            blocks: [
                Block(
                    title: NSLocalizedString("seed.block.hygiene", comment: ""), category: .hygiene,
                    startMinutesFromMidnight: 7 * 60, durationMinutes: 30),
                Block(
                    title: NSLocalizedString("seed.block.breakfast", comment: ""), category: .meal,
                    startMinutesFromMidnight: 7 * 60 + 30, durationMinutes: 30),
                Block(
                    title: NSLocalizedString("seed.block.medication", comment: ""), category: .medication,
                    startMinutesFromMidnight: 8 * 60, durationMinutes: 5),
                Block(
                    title: NSLocalizedString("seed.block.work", comment: ""), category: .work,
                    startMinutesFromMidnight: 9 * 60, durationMinutes: 8 * 60, isDeepFocus: true),
                Block(
                    title: NSLocalizedString("seed.block.dinner", comment: ""), category: .meal,
                    startMinutesFromMidnight: 20 * 60, durationMinutes: 60),
                Block(
                    title: NSLocalizedString("seed.block.sleep", comment: ""), category: .sleep,
                    startMinutesFromMidnight: 23 * 60, durationMinutes: 8 * 60),
            ],
            isActive: true
        )
        let weekend = RoutineTemplate(
            name: NSLocalizedString("onboarding.template.weekend", comment: ""),
            dayType: .weekend,
            blocks: [
                Block(
                    title: NSLocalizedString("seed.block.hygiene", comment: ""), category: .hygiene,
                    startMinutesFromMidnight: 9 * 60, durationMinutes: 30),
                Block(
                    title: NSLocalizedString("seed.block.breakfast", comment: ""), category: .meal,
                    startMinutesFromMidnight: 9 * 60 + 30, durationMinutes: 60),
                Block(
                    title: NSLocalizedString("seed.block.medication", comment: ""), category: .medication,
                    startMinutesFromMidnight: 10 * 60, durationMinutes: 5),
                Block(
                    title: NSLocalizedString("seed.block.sleep", comment: ""), category: .sleep,
                    startMinutesFromMidnight: 23 * 60 + 30, durationMinutes: 8 * 60),
            ],
            isActive: true
        )
        try repository.upsert(weekday)
        try repository.upsert(weekend)
    }
}
