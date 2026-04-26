import Foundation

/// Pure value type that groups recently-delivered notifications by their
/// parsed `BlockSnoozeSource`. Decoupled from `UNUserNotificationCenter` so
/// tests can feed `Item` values directly without spinning up a stub center.
public enum DeliveredNotificationsGrouper {

    public struct Item: Equatable, Sendable {
        public let identifier: String
        public let title: String
        public let body: String
        public let deliveredAt: Date

        public init(identifier: String, title: String, body: String, deliveredAt: Date) {
            self.identifier = identifier
            self.title = title
            self.body = body
            self.deliveredAt = deliveredAt
        }
    }

    public struct Group: Equatable, Sendable {
        public let source: BlockSnoozeSource?
        public let items: [Item]
    }

    /// Buckets `items` by parsed source, sorting each bucket newest-first.
    /// Unknown identifiers (no parser match) collapse into a single trailing
    /// `nil`-source group. The outer ordering follows `BlockSnoozeSource.allCases`
    /// + the unknown bucket last.
    public static func group(_ items: [Item]) -> [Group] {
        let sortedNewestFirst = items.sorted { $0.deliveredAt > $1.deliveredAt }
        var buckets: [BlockSnoozeSource: [Item]] = [:]
        var unknown: [Item] = []
        for item in sortedNewestFirst {
            if let parsed = BlockNotificationIdentifier.parseAny(item.identifier) {
                buckets[parsed.source, default: []].append(item)
            } else {
                unknown.append(item)
            }
        }
        var result: [Group] = []
        for source in BlockSnoozeSource.allCases {
            if let items = buckets[source], !items.isEmpty {
                result.append(Group(source: source, items: items))
            }
        }
        if !unknown.isEmpty {
            result.append(Group(source: nil, items: unknown))
        }
        return result
    }
}
