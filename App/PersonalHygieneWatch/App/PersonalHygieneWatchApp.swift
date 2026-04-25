import SwiftData
import SwiftUI

@main
struct PersonalHygieneWatchApp: App {

    let modelContainer: ModelContainer

    init() {
        do {
            self.modelContainer = try AppModelContainer.makeProduction()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
