import Combine
import Foundation

@MainActor
public final class WaterBarStore: ObservableObject {
    @Published public private(set) var settings: WaterSettings
    @Published public private(set) var todayRecord: WaterDayRecord
    @Published public private(set) var history: [WaterDayRecord]
    @Published public private(set) var lastIncrementMl: Int?
    @Published public private(set) var reminderPermissionDenied = false
    @Published public private(set) var lastSaveErrorDescription: String?

    private let storage: WaterSnapshotStorage
    private let reminderScheduler: ReminderScheduling
    private let calendar: Calendar
    private let now: () -> Date
    private var midnightObserver: NSObjectProtocol?
    private var rolloverTimer: Timer?

    public static func live() -> WaterBarStore {
        WaterBarStore(
            storage: FileWaterSnapshotStorage(),
            reminderScheduler: UserNotificationReminderScheduler()
        )
    }

    init(
        storage: WaterSnapshotStorage,
        reminderScheduler: ReminderScheduling,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init
    ) {
        self.storage = storage
        self.reminderScheduler = reminderScheduler
        self.calendar = calendar
        self.now = now

        let currentDay = Self.dayKey(for: now(), calendar: calendar)
        if let snapshot = try? storage.load() {
            self.settings = snapshot.settings.normalized()
            self.todayRecord = snapshot.currentDay
            self.history = snapshot.history.sorted(by: { $0.dayKey > $1.dayKey })
            self.lastIncrementMl = snapshot.lastIncrementMl
        } else {
            self.settings = .default
            self.todayRecord = WaterDayRecord(dayKey: currentDay, totalMl: 0)
            self.history = []
            self.lastIncrementMl = nil
        }

        refreshForCurrentDay()
        installDayTracking()
        refreshReminders()
    }

    public var todayTotalMl: Int {
        todayRecord.totalMl
    }

    public var progressFraction: Double {
        guard settings.dailyGoalMl > 0 else { return 0 }
        return min(Double(todayRecord.totalMl) / Double(settings.dailyGoalMl), 1)
    }

    public var isGoalComplete: Bool {
        todayRecord.totalMl >= settings.dailyGoalMl
    }

    public var remainingMl: Int {
        max(settings.dailyGoalMl - todayRecord.totalMl, 0)
    }

    public var progressSummary: String {
        "\(todayRecord.totalMl) / \(settings.dailyGoalMl) ml"
    }

    public var menuBarTitle: String {
        "\(Int(progressFraction * 100))%"
    }

    public var menuBarSymbolName: String {
        isGoalComplete ? "drop.fill" : "drop"
    }

    public var reminderStatusText: String {
        if reminderPermissionDenied {
            return "Notifications are blocked for WaterBar."
        }
        if !settings.remindersEnabled {
            return "Reminders are off."
        }
        if isGoalComplete {
            return "Goal complete. Reminders paused until tomorrow."
        }
        return "Reminder every \(settings.reminderIntervalMinutes) min."
    }

    public func addDrink() {
        refreshForCurrentDay()
        todayRecord.totalMl += settings.defaultIncrementMl
        lastIncrementMl = settings.defaultIncrementMl
        persistAndRefresh()
    }

    public func undoLastDrink() {
        refreshForCurrentDay()
        guard todayRecord.totalMl > 0 else { return }
        let decrementMl = lastIncrementMl ?? settings.defaultIncrementMl
        todayRecord.totalMl = max(todayRecord.totalMl - decrementMl, 0)
        if todayRecord.totalMl == 0 {
            lastIncrementMl = nil
        } else {
            lastIncrementMl = decrementMl
        }
        persistAndRefresh()
    }

    public func updateTodayTotal(to totalMl: Int) {
        refreshForCurrentDay()
        todayRecord.totalMl = max(0, totalMl)
        lastIncrementMl = nil
        persistAndRefresh()
    }

    public func updateDailyGoal(to dailyGoalMl: Int) {
        settings.dailyGoalMl = dailyGoalMl
        settings = settings.normalized()
        persistAndRefresh()
    }

    public func updateDefaultIncrement(to incrementMl: Int) {
        settings.defaultIncrementMl = incrementMl
        settings = settings.normalized()
        persistAndRefresh()
    }

    public func updateReminderInterval(to minutes: Int) {
        settings.reminderIntervalMinutes = minutes
        settings = settings.normalized()
        persistAndRefresh()
    }

    public func setRemindersEnabled(_ enabled: Bool) {
        reminderPermissionDenied = false

        guard enabled else {
            settings.remindersEnabled = false
            persistAndRefresh()
            return
        }

        reminderScheduler.requestAuthorization { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.settings.remindersEnabled = granted
                self.reminderPermissionDenied = !granted
                self.persistAndRefresh()
            }
        }
    }

    public func refreshForCurrentDay() {
        let currentDayKey = Self.dayKey(for: now(), calendar: calendar)
        guard todayRecord.dayKey != currentDayKey else {
            return
        }

        archive(record: todayRecord)
        todayRecord = WaterDayRecord(dayKey: currentDayKey, totalMl: 0)
        lastIncrementMl = nil
        persistAndRefresh()
    }

    private func persistAndRefresh() {
        saveSnapshot()
        refreshReminders()
    }

    private func saveSnapshot() {
        let snapshot = WaterBarSnapshot(
            settings: settings.normalized(),
            currentDay: todayRecord,
            history: history,
            lastIncrementMl: lastIncrementMl
        )

        do {
            try storage.save(snapshot)
            lastSaveErrorDescription = nil
        } catch {
            lastSaveErrorDescription = error.localizedDescription
        }
    }

    private func refreshReminders() {
        reminderScheduler.updateSchedule(
            enabled: settings.remindersEnabled,
            intervalMinutes: settings.reminderIntervalMinutes,
            isGoalComplete: isGoalComplete
        )
    }

    private func archive(record: WaterDayRecord) {
        guard record.totalMl > 0 else {
            return
        }

        history.removeAll { $0.dayKey == record.dayKey }
        history.append(record)
        history.sort { $0.dayKey > $1.dayKey }
    }

    private func installDayTracking() {
        midnightObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshForCurrentDay()
            }
        }

        rolloverTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshForCurrentDay()
            }
        }
        rolloverTimer?.tolerance = 10
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
