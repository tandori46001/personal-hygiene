import Foundation
import SwiftData

/// Centralized factory for the app's `ModelContainer`.
///
/// Phase 1 ships local-only persistence. The CloudKit-ready configuration is
/// declared here so it can be flipped on the moment the iCloud + CloudKit
/// entitlements are added to the project (which requires the paid Apple
/// Developer Program). Until then `makeProduction()` defaults to the local
/// configuration so the app works without an entitlement.
public enum AppModelContainer {

    /// Container identifier used once CloudKit is enabled. Mirrors
    /// `PRODUCT_BUNDLE_IDENTIFIER` per Apple convention.
    public static let cloudKitContainerIdentifier =
        "iCloud.com.tandori46001.personalhygiene"

    /// All models go to CloudKit once sync is enabled. Listed explicitly so a
    /// new `@Model` can't be added without a deliberate decision.
    public static let cloudSyncableTypes: [any PersistentModel.Type] = [
        Block.self,
        RoutineTemplate.self,
        BlockCompletion.self,
        HydrationLog.self,
        HousekeepingTask.self,
        Trip.self,
        TripMilestone.self,
        // `TripDocument` ships its bytes via Keychain (per-device only) — the
        // metadata @Model could sync, but we hold off until we've validated
        // that document references roundtrip cleanly across devices without
        // dangling pointers to Keychain items that don't exist on the
        // receiving device.
        TripDocument.self,
        ImportantDay.self,
    ]

    /// Computed (not `static let`) so we don't trip Swift 6's
    /// "non-Sendable shared-mutable-state" diagnostic on `Schema`.
    /// Build cost is negligible — it's a tiny metatype array — and call
    /// sites are not on a hot path.
    public static var schema: Schema {
        Schema([
            Block.self,
            RoutineTemplate.self,
            BlockCompletion.self,
            HydrationLog.self,
            HousekeepingTask.self,
            Trip.self,
            TripMilestone.self,
            TripDocument.self,
            ImportantDay.self,
        ])
    }

    /// On-disk container used by the running app. Local-only today; pass
    /// `cloudKit: true` once the entitlement is in the project.
    @MainActor
    public static func makeProduction(cloudKit: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if cloudKit {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// In-memory container for previews and tests.
    @MainActor
    public static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
