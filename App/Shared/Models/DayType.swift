import Foundation

public enum DayType: String, CaseIterable, Codable, Sendable {
    case weekday
    case weekend
    case vacation
    case custom
}
