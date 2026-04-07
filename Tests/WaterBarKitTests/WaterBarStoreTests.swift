import XCTest
@testable import WaterBarKit

@MainActor
final class WaterBarStoreTests: XCTestCase {
    func testDefaultsLoadForFreshInstall() {
        let storage = InMemoryStorage(snapshot: nil)
        let scheduler = MockReminderScheduler()
        let store = makeStore(storage: storage, scheduler: scheduler, now: "2026-04-07T09:00:00Z")

        XCTAssertEqual(store.settings, .default)
        XCTAssertEqual(store.todayTotalMl, 0)
        XCTAssertTrue(store.history.isEmpty)
        XCTAssertEqual(scheduler.lastUpdate?.enabled, false)
    }

    func testAddDrinkAndUndoAdjustTodayTotal() {
        let storage = InMemoryStorage(snapshot: nil)
        let scheduler = MockReminderScheduler()
        let store = makeStore(storage: storage, scheduler: scheduler, now: "2026-04-07T09:00:00Z")

        store.addDrink()
        XCTAssertEqual(store.todayTotalMl, 250)
        XCTAssertEqual(store.lastIncrementMl, 250)

        store.undoLastDrink()
        XCTAssertEqual(store.todayTotalMl, 0)
        XCTAssertNil(store.lastIncrementMl)
    }

    func testRolloverArchivesPriorDayAndResetsToday() {
        let snapshot = WaterBarSnapshot(
            settings: .default,
            currentDay: WaterDayRecord(dayKey: "2026-04-06", totalMl: 1_250),
            history: [],
            lastIncrementMl: 250
        )
        let storage = InMemoryStorage(snapshot: snapshot)
        let scheduler = MockReminderScheduler()
        var currentDate = Self.date("2026-04-07T08:00:00Z")
        let store = WaterBarStore(
            storage: storage,
            reminderScheduler: scheduler,
            calendar: Self.utcCalendar,
            now: { currentDate }
        )

        XCTAssertEqual(store.todayRecord.dayKey, "2026-04-07")
        XCTAssertEqual(store.todayTotalMl, 0)
        XCTAssertEqual(store.history, [WaterDayRecord(dayKey: "2026-04-06", totalMl: 1_250)])
        XCTAssertNil(store.lastIncrementMl)

        store.addDrink()
        currentDate = Self.date("2026-04-08T01:00:00Z")
        store.refreshForCurrentDay()

        XCTAssertEqual(store.todayRecord.dayKey, "2026-04-08")
        XCTAssertTrue(store.history.contains(WaterDayRecord(dayKey: "2026-04-07", totalMl: 250)))
    }

    func testEnablingRemindersRequestsPermission() {
        let storage = InMemoryStorage(snapshot: nil)
        let scheduler = MockReminderScheduler(permissionGranted: false)
        let store = makeStore(storage: storage, scheduler: scheduler, now: "2026-04-07T09:00:00Z")

        store.setRemindersEnabled(true)

        XCTAssertTrue(scheduler.didRequestAuthorization)
        XCTAssertFalse(store.settings.remindersEnabled)
        XCTAssertTrue(store.reminderPermissionDenied)
    }

    func testManualEditCanCompleteGoal() {
        let storage = InMemoryStorage(snapshot: nil)
        let scheduler = MockReminderScheduler()
        let store = makeStore(storage: storage, scheduler: scheduler, now: "2026-04-07T09:00:00Z")

        store.updateTodayTotal(to: 2_500)

        XCTAssertEqual(store.todayTotalMl, 2_500)
        XCTAssertTrue(store.isGoalComplete)
        XCTAssertEqual(scheduler.lastUpdate?.isGoalComplete, true)
    }

    private func makeStore(
        storage: InMemoryStorage,
        scheduler: MockReminderScheduler,
        now: String
    ) -> WaterBarStore {
        WaterBarStore(
            storage: storage,
            reminderScheduler: scheduler,
            calendar: Self.utcCalendar,
            now: { Self.date(now) }
        )
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private static func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)!
    }
}

private final class InMemoryStorage: WaterSnapshotStorage {
    var snapshot: WaterBarSnapshot?

    init(snapshot: WaterBarSnapshot?) {
        self.snapshot = snapshot
    }

    func load() throws -> WaterBarSnapshot? {
        snapshot
    }

    func save(_ snapshot: WaterBarSnapshot) throws {
        self.snapshot = snapshot
    }
}

private final class MockReminderScheduler: ReminderScheduling {
    struct Update: Equatable {
        var enabled: Bool
        var intervalMinutes: Int
        var isGoalComplete: Bool
    }

    var permissionGranted: Bool
    var didRequestAuthorization = false
    var lastUpdate: Update?

    init(permissionGranted: Bool = true) {
        self.permissionGranted = permissionGranted
    }

    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        didRequestAuthorization = true
        completion(permissionGranted)
    }

    func updateSchedule(enabled: Bool, intervalMinutes: Int, isGoalComplete: Bool) {
        lastUpdate = Update(
            enabled: enabled,
            intervalMinutes: intervalMinutes,
            isGoalComplete: isGoalComplete
        )
    }
}
