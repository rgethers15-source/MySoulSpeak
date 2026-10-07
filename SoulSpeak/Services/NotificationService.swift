import Foundation
import UserNotifications

/// Handles scheduling and managing daily reminder notifications.
class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Permission

    /// Request notification permission from the user.
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[SoulSpeak] Notification permission error: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Check current authorization status.
    func checkPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Schedule Daily Reminder

    /// Schedule a daily journal reminder at the specified time.
    func scheduleDailyReminder(hour: Int, minute: Int) {
        // Remove existing reminders first
        cancelDailyReminder()

        // Create content with rotating messages
        let content = UNMutableNotificationContent()
        content.title = "SoulSpeak"
        content.body = dailyReminderMessage()
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        // Set up daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "soulspeak_daily_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("[SoulSpeak] Failed to schedule notification: \(error)")
            } else {
                print("[SoulSpeak] Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }

        // Also schedule a few variety notifications for the week
        scheduleVarietyReminders(hour: hour, minute: minute)
    }

    /// Cancel all daily reminder notifications.
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [
                "soulspeak_daily_reminder",
                "soulspeak_variety_1",
                "soulspeak_variety_2",
                "soulspeak_variety_3",
                "soulspeak_variety_4",
                "soulspeak_variety_5",
                "soulspeak_variety_6",
                "soulspeak_variety_7",
            ]
        )
    }

    // MARK: - Streak Reminder

    /// Schedule a "don't break your streak" reminder if user hasn't journaled today.
    func scheduleStreakReminder(currentStreak: Int) {
        guard currentStreak >= 3 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your \(currentStreak)-day streak!"
        content.body = "Don't let it slip, Champ! Dr. Hope is waiting to hear from you today."
        content.sound = .default

        // Trigger at 8 PM if they haven't journaled
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "soulspeak_streak_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("[SoulSpeak] Streak reminder error: \(error)")
            }
        }
    }

    /// Cancel streak reminder (called when user journals for the day).
    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["soulspeak_streak_reminder"])
    }

    // MARK: - Private Helpers

    private func dailyReminderMessage() -> String {
        let messages = [
            "Hey Champ, Dr. Hope's got a seat ready for you. Come speak your truth today.",
            "Your soul's got somethin' to say. Take a few minutes to journal today.",
            "Good morning, baby. How's your spirit today? Dr. Hope would love to hear.",
            "A few minutes of honest reflection can change your whole day. You ready?",
            "The ancestors are cheering you on. Come sit with Dr. Hope for a spell.",
            "Your feelings matter. Your story matters. Come tell it today.",
            "Hey Champ! Mr. Hope here. Dr. Hope's been asking about you. Come on in.",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return messages[dayOfYear % messages.count]
    }

    private func scheduleVarietyReminders(hour: Int, minute: Int) {
        let messages = [
            ("Monday Motivation", "New week, new chances to grow. Dr. Hope believes in you, Champ."),
            ("Midweek Check-in", "How's your heart today? Take a moment to check in with yourself."),
            ("Gratitude Moment", "Name one thing you're grateful for today. Just one. That's medicine."),
            ("Friday Reflection", "You made it through another week. That's worth celebrating."),
            ("Weekend Rest", "Even warriors rest, baby. How can you fill your cup this weekend?"),
            ("Sunday Spirit", "Feed your soul today. Scripture, prayer, journal — whatever speaks to you."),
            ("Gentle Nudge", "You don't have to be perfect. You just have to show up. Dr. Hope's here."),
        ]

        for (index, (title, body)) in messages.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            // Schedule for each day of the week (weekday = index + 1, starting Monday = 2)
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = (index + 2) % 7 + 1 // Maps to Sun=1, Mon=2, etc.

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(
                identifier: "soulspeak_variety_\(index + 1)",
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request, withCompletionHandler: nil)
        }
    }
}
