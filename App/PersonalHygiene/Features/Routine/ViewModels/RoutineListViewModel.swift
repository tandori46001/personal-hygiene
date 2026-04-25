import Foundation
import Observation

@Observable
@MainActor
final class RoutineListViewModel {
    var blocks: [Block]

    init(blocks: [Block] = []) {
        self.blocks = blocks
    }

    static var preview: RoutineListViewModel {
        RoutineListViewModel(blocks: [
            Block(
                title: "Aseo",
                category: .hygiene,
                startMinutesFromMidnight: 7 * 60,
                durationMinutes: 30
            ),
            Block(
                title: "Desayuno",
                category: .meal,
                startMinutesFromMidnight: 7 * 60 + 30,
                durationMinutes: 30
            ),
            Block(
                title: "Medicación",
                category: .medication,
                startMinutesFromMidnight: 8 * 60,
                durationMinutes: 5
            ),
            Block(
                title: "Trabajo",
                category: .work,
                startMinutesFromMidnight: 9 * 60,
                durationMinutes: 8 * 60,
                isDeepFocus: true
            ),
        ])
    }
}
