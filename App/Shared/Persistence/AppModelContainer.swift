import Foundation
import SwiftData

/// Centralized factory for the app's `ModelContainer`.
///
/// Phase 1 ships local-only persistence. CloudKit sync is wired in Slice 2 once
/// the iCloud entitlement is in the project.
public enum AppModelContainer {

    public static let schema = Schema([
        Block.self,
        RoutineTemplate.self,
        BlockCompletion.self,
        HydrationLog.self,
        HousekeepingTask.self,
    ])

    /// On-disk container used by the running app.
    @MainActor
    public static func makeProduction() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// In-memory container for previews and tests.
    @MainActor
    public static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
