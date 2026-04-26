import Foundation
import SwiftData

/// Read/write access to hydration logs. Lives next to the routine repository
/// so the same `ModelContext` can carry both.
@MainActor
public protocol HydrationService {
    func log(milliliters: Int, at drankAt: Date) throws
    func logs(between start: Date, and end: Date) throws -> [HydrationLog]
    func deleteAllLogs() throws
}

@MainActor
public final class SwiftDataHydrationService: HydrationService {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func log(milliliters: Int, at drankAt: Date) throws {
        guard milliliters > 0 else { return }
        let entry = HydrationLog(milliliters: milliliters, drankAt: drankAt)
        context.insert(entry)
        try context.save()
    }

    public func logs(between start: Date, and end: Date) throws -> [HydrationLog] {
        let descriptor = FetchDescriptor<HydrationLog>(
            predicate: #Predicate { $0.drankAt >= start && $0.drankAt <= end },
            sortBy: [SortDescriptor(\.drankAt)]
        )
        return try context.fetch(descriptor)
    }

    public func deleteAllLogs() throws {
        let descriptor = FetchDescriptor<HydrationLog>()
        for entry in try context.fetch(descriptor) {
            context.delete(entry)
        }
        try context.save()
    }
}

/// In-memory test/preview implementation.
@MainActor
public final class InMemoryHydrationService: HydrationService {

    public var entries: [HydrationLog] = []

    public init(entries: [HydrationLog] = []) {
        self.entries = entries
    }

    public func log(milliliters: Int, at drankAt: Date) throws {
        guard milliliters > 0 else { return }
        entries.append(HydrationLog(milliliters: milliliters, drankAt: drankAt))
    }

    public func logs(between start: Date, and end: Date) throws -> [HydrationLog] {
        entries
            .filter { $0.drankAt >= start && $0.drankAt <= end }
            .sorted { $0.drankAt < $1.drankAt }
    }

    public func deleteAllLogs() throws {
        entries.removeAll()
    }
}
