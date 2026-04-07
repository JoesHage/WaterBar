import Foundation
@preconcurrency import UserNotifications

protocol ReminderScheduling: AnyObject {
    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void)
    func updateSchedule(enabled: Bool, intervalMinutes: Int, isGoalComplete: Bool)
}

final class UserNotificationReminderScheduler: ReminderScheduling {
    private let center: UNUserNotificationCenter
    private let requestIdentifier = "waterbar.periodic-reminder"

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        center.getNotificationSettings { [center] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    func updateSchedule(enabled: Bool, intervalMinutes: Int, isGoalComplete: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])

        guard enabled, !isGoalComplete else {
            return
        }

        let seconds = max(intervalMinutes * 60, 60)
        let content = UNMutableNotificationContent()
        content.title = "Water check-in"
        content.body = "Log your next glass and keep your daily intake moving."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: true)
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        center.add(request)
    }
}
