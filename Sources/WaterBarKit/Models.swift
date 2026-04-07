import Foundation

public struct WaterSettings: Codable, Equatable, Sendable {
    public var dailyGoalMl: Int
    public var defaultIncrementMl: Int
    public var remindersEnabled: Bool
    public var reminderIntervalMinutes: Int

    public static let `default` = WaterSettings(
        dailyGoalMl: 2_000,
        defaultIncrementMl: 250,
        remindersEnabled: false,
        reminderIntervalMinutes: 60
    )

    public func normalized() -> WaterSettings {
        WaterSettings(
            dailyGoalMl: dailyGoalMl.clamped(to: 250...10_000),
            defaultIncrementMl: defaultIncrementMl.clamped(to: 50...2_000),
            remindersEnabled: remindersEnabled,
            reminderIntervalMinutes: reminderIntervalMinutes.clamped(to: 15...240)
        )
    }
}

public struct WaterDayRecord: Codable, Equatable, Identifiable, Sendable {
    public var dayKey: String
    public var totalMl: Int

    public var id: String { dayKey }

    public init(dayKey: String, totalMl: Int) {
        self.dayKey = dayKey
        self.totalMl = max(0, totalMl)
    }
}

struct WaterBarSnapshot: Codable, Equatable {
    var settings: WaterSettings
    var currentDay: WaterDayRecord
    var history: [WaterDayRecord]
    var lastIncrementMl: Int?
}

extension Int {
    fileprivate func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
