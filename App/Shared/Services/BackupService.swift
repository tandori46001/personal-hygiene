import Foundation
import SwiftData

/// Wire-format snapshot of the user's portable data. Serialises everything
/// SwiftData currently owns *except* the per-device Keychain bytes for trip
/// documents — those don't survive a device move and would import as dangling
/// references.
public struct BackupSnapshot: Codable, Equatable, Sendable {

    public let version: Int
    public let exportedAt: Date
    public let templates: [TemplatePayload]
    public let completions: [CompletionPayload]
    public let hydration: [HydrationLogPayload]
    public let housekeeping: [HousekeepingTaskPayload]
    public let trips: [TripPayload]

    public init(
        version: Int = 1,
        exportedAt: Date = Date(),
        templates: [TemplatePayload],
        completions: [CompletionPayload],
        hydration: [HydrationLogPayload],
        housekeeping: [HousekeepingTaskPayload],
        trips: [TripPayload]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.templates = templates
        self.completions = completions
        self.hydration = hydration
        self.housekeeping = housekeeping
        self.trips = trips
    }
}

extension BackupSnapshot {

    public struct TemplatePayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let name: String
        public let dayType: String
        public let isActive: Bool
        public let blocks: [BlockPayload]
    }

    public struct BlockPayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let category: String
        public let startMinutesFromMidnight: Int
        public let durationMinutes: Int
        public let notificationLeadMinutes: Int
        public let isDeepFocus: Bool
        public let notes: String?
    }

    public struct CompletionPayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let blockID: UUID
        public let dayStart: Date
        public let completedAt: Date
    }

    public struct HydrationLogPayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let drankAt: Date
        public let milliliters: Int
    }

    public struct HousekeepingTaskPayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let recurrence: String
        public let lastCompletedAt: Date?
        public let escalationDays: Int
    }

    public struct TripPayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let name: String
        public let startDate: Date
        public let endDate: Date
        public let destinationName: String
        public let destinationLatitude: Double?
        public let destinationLongitude: Double?
        public let milestones: [MilestonePayload]
        // Added in v1.1; older backups omit these. Decode as nil/empty.
        public let packingItems: [PackingItemPayload]?

        public init(
            id: UUID,
            name: String,
            startDate: Date,
            endDate: Date,
            destinationName: String,
            destinationLatitude: Double?,
            destinationLongitude: Double?,
            milestones: [MilestonePayload],
            packingItems: [PackingItemPayload]? = nil
        ) {
            self.id = id
            self.name = name
            self.startDate = startDate
            self.endDate = endDate
            self.destinationName = destinationName
            self.destinationLatitude = destinationLatitude
            self.destinationLongitude = destinationLongitude
            self.milestones = milestones
            self.packingItems = packingItems
        }
    }

    public struct PackingItemPayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let isPacked: Bool
    }

    public struct MilestonePayload: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let daysBefore: Int
        public let isComplete: Bool
    }
}

@MainActor
public enum BackupService {

    public static func export(from context: ModelContext) throws -> BackupSnapshot {
        let templates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        let completions = try context.fetch(FetchDescriptor<BlockCompletion>())
        let hydration = try context.fetch(FetchDescriptor<HydrationLog>())
        let housekeeping = try context.fetch(FetchDescriptor<HousekeepingTask>())
        let trips = try context.fetch(FetchDescriptor<Trip>())

        return BackupSnapshot(
            templates: templates.map(payload(from:)),
            completions: completions.map(payload(from:)),
            hydration: hydration.map(payload(from:)),
            housekeeping: housekeeping.map(payload(from:)),
            trips: trips.map(payload(from:))
        )
    }

    public static func encode(_ snapshot: BackupSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        // `.iso8601` truncates fractional seconds, which breaks Equatable
        // round-trips. `.secondsSince1970` is lossless to nanosecond level.
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(snapshot)
    }

    public static func decode(_ data: Data) throws -> BackupSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(BackupSnapshot.self, from: data)
    }

    /// Replaces *all* user data in `context` with the contents of `snapshot`.
    /// This is intentionally destructive — JSON backups exist as a safety net
    /// before CloudKit lands; merging would give us silent half-migrations.
    public static func restore(_ snapshot: BackupSnapshot, into context: ModelContext) throws {
        try wipe(context)
        snapshot.templates.forEach { restoreTemplate($0, into: context) }
        snapshot.completions.forEach { restoreCompletion($0, into: context) }
        snapshot.hydration.forEach { restoreHydration($0, into: context) }
        snapshot.housekeeping.forEach { restoreHousekeeping($0, into: context) }
        snapshot.trips.forEach { restoreTrip($0, into: context) }
        try context.save()
    }

    private static func restoreTemplate(_ payload: BackupSnapshot.TemplatePayload, into context: ModelContext) {
        let blocks = payload.blocks.map(block(from:))
        context.insert(
            RoutineTemplate(
                id: payload.id,
                name: payload.name,
                dayType: DayType(rawValue: payload.dayType) ?? .weekday,
                blocks: blocks,
                isActive: payload.isActive
            )
        )
    }

    private static func restoreCompletion(
        _ payload: BackupSnapshot.CompletionPayload,
        into context: ModelContext
    ) {
        context.insert(
            BlockCompletion(
                id: payload.id,
                blockID: payload.blockID,
                dayStart: payload.dayStart,
                completedAt: payload.completedAt
            )
        )
    }

    private static func restoreHydration(
        _ payload: BackupSnapshot.HydrationLogPayload,
        into context: ModelContext
    ) {
        context.insert(
            HydrationLog(id: payload.id, milliliters: payload.milliliters, drankAt: payload.drankAt)
        )
    }

    private static func restoreHousekeeping(
        _ payload: BackupSnapshot.HousekeepingTaskPayload,
        into context: ModelContext
    ) {
        context.insert(
            HousekeepingTask(
                id: payload.id,
                title: payload.title,
                recurrence: HousekeepingRecurrence(rawValue: payload.recurrence) ?? .weekly,
                lastCompletedAt: payload.lastCompletedAt,
                escalationDays: payload.escalationDays
            )
        )
    }

    private static func restoreTrip(_ payload: BackupSnapshot.TripPayload, into context: ModelContext) {
        let milestones = payload.milestones.map { milestone in
            TripMilestone(
                id: milestone.id,
                title: milestone.title,
                daysBefore: milestone.daysBefore,
                isComplete: milestone.isComplete
            )
        }
        let packingItems = (payload.packingItems ?? []).map { item in
            PackingItem(id: item.id, title: item.title, isPacked: item.isPacked)
        }
        context.insert(
            Trip(
                id: payload.id,
                name: payload.name,
                startDate: payload.startDate,
                endDate: payload.endDate,
                destinationName: payload.destinationName,
                destinationLatitude: payload.destinationLatitude,
                destinationLongitude: payload.destinationLongitude,
                packingItems: packingItems,
                milestones: milestones,
                documents: []
            )
        )
    }

    private static func wipe(_ context: ModelContext) throws {
        // Use per-instance `context.delete(_:)` so SwiftData honours the
        // cascading inverse relationships. The bulk `delete(model:)` form
        // bypasses cascade triggers and trips
        // "mandatory OTO nullify inverse" errors for `TripMilestone.trip`.
        let templates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        templates.forEach(context.delete)
        let trips = try context.fetch(FetchDescriptor<Trip>())
        trips.forEach(context.delete)
        let completions = try context.fetch(FetchDescriptor<BlockCompletion>())
        completions.forEach(context.delete)
        let hydration = try context.fetch(FetchDescriptor<HydrationLog>())
        hydration.forEach(context.delete)
        let housekeeping = try context.fetch(FetchDescriptor<HousekeepingTask>())
        housekeeping.forEach(context.delete)
        try context.save()
    }

    // MARK: - Mappings

    private static func payload(from template: RoutineTemplate) -> BackupSnapshot.TemplatePayload {
        BackupSnapshot.TemplatePayload(
            id: template.id,
            name: template.name,
            dayType: template.dayType.rawValue,
            isActive: template.isActive,
            blocks: template.sortedBlocks.map(payload(from:))
        )
    }

    private static func payload(from block: Block) -> BackupSnapshot.BlockPayload {
        BackupSnapshot.BlockPayload(
            id: block.id,
            title: block.title,
            category: block.category.rawValue,
            startMinutesFromMidnight: block.startMinutesFromMidnight,
            durationMinutes: block.durationMinutes,
            notificationLeadMinutes: block.notificationLeadMinutes,
            isDeepFocus: block.isDeepFocus,
            notes: block.notes
        )
    }

    private static func block(from payload: BackupSnapshot.BlockPayload) -> Block {
        Block(
            id: payload.id,
            title: payload.title,
            category: BlockCategory(rawValue: payload.category) ?? .hygiene,
            startMinutesFromMidnight: payload.startMinutesFromMidnight,
            durationMinutes: payload.durationMinutes,
            notes: payload.notes,
            notificationLeadMinutes: payload.notificationLeadMinutes,
            isDeepFocus: payload.isDeepFocus
        )
    }

    private static func payload(from completion: BlockCompletion) -> BackupSnapshot.CompletionPayload {
        BackupSnapshot.CompletionPayload(
            id: completion.id,
            blockID: completion.blockID,
            dayStart: completion.dayStart,
            completedAt: completion.completedAt
        )
    }

    private static func payload(from log: HydrationLog) -> BackupSnapshot.HydrationLogPayload {
        BackupSnapshot.HydrationLogPayload(
            id: log.id,
            drankAt: log.drankAt,
            milliliters: log.milliliters
        )
    }

    private static func payload(from task: HousekeepingTask) -> BackupSnapshot.HousekeepingTaskPayload {
        BackupSnapshot.HousekeepingTaskPayload(
            id: task.id,
            title: task.title,
            recurrence: task.recurrence.rawValue,
            lastCompletedAt: task.lastCompletedAt,
            escalationDays: task.escalationDays
        )
    }

    private static func payload(from trip: Trip) -> BackupSnapshot.TripPayload {
        BackupSnapshot.TripPayload(
            id: trip.id,
            name: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            destinationName: trip.destinationName,
            destinationLatitude: trip.destinationLatitude,
            destinationLongitude: trip.destinationLongitude,
            milestones: trip.milestones.map { milestone in
                BackupSnapshot.MilestonePayload(
                    id: milestone.id,
                    title: milestone.title,
                    daysBefore: milestone.daysBefore,
                    isComplete: milestone.isComplete
                )
            },
            packingItems: trip.packingItems.map { item in
                BackupSnapshot.PackingItemPayload(
                    id: item.id,
                    title: item.title,
                    isPacked: item.isPacked
                )
            }
        )
    }
}
