import Foundation
import UserNotifications

/// Manages daily wellness check-in notifications.
/// Sends personalized reminders throughout the day.
class CheckInService {
    static let shared = CheckInService()
    private let center = UNUserNotificationCenter.current()

    /// Schedule all daily check-in notifications.
    func scheduleAllCheckIns() {
        cancelAllCheckIns()

        let checkIns: [(id: String, hour: Int, minute: Int, title: String, body: String)] = [
            ("checkin_morning_prayer", 7, 0,
             "Morning Prayer",
             "Good morning, Champ! Have you talked to God today? Even a quiet 'thank you' counts."),
            ("checkin_water", 9, 0,
             "Hydrate",
             "Hey sugar — Dr. Hope here. Drink some water. Your body and mind both need it."),
            ("checkin_breathe", 10, 30,
             "Deep Breath",
             "Pause for 30 seconds. Breathe in through your nose... out through your mouth. You got this."),
            ("checkin_journal", 12, 0,
             "Journal Check",
             "Have you spoken your truth today? Dr. Hope is ready to listen whenever you are."),
            ("checkin_meditate", 14, 0,
             "Meditation Moment",
             "Take 5 minutes to be still, baby. The world can wait. Your peace cannot."),
            ("checkin_call", 16, 0,
             "Call Someone",
             "Champ — when's the last time you checked on someone you love? A quick call goes a long way."),
            ("checkin_read", 18, 0,
             "Read Something",
             "Feed your mind tonight. Even one page of something good changes your energy."),
            ("checkin_exercise", 17, 0,
             "Move Your Body",
             "Even a 10-minute walk counts. Your body holds your emotions — let them move through you."),
            ("checkin_evening", 21, 0,
             "Evening Reflection",
             "How was your day, baby? Come journal with Dr. Hope before bed. Let it all out."),
        ]

        for checkIn in checkIns {
            let content = UNMutableNotificationContent()
            content.title = checkIn.title
            content.body = checkIn.body
            content.sound = .default
            content.categoryIdentifier = "DAILY_CHECKIN"

            var dateComponents = DateComponents()
            dateComponents.hour = checkIn.hour
            dateComponents.minute = checkIn.minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: checkIn.id,
                content: content,
                trigger: trigger
            )

            center.add(request, withCompletionHandler: nil)
        }

        print("[SoulSpeak] Scheduled \(checkIns.count) daily check-in notifications")
    }

    /// Schedule sobriety-specific encouragement notifications.
    func scheduleSobrietyCheckIns(substanceType: String, days: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Day \(days + 1) — Stay Strong"
        content.sound = .default
        content.categoryIdentifier = "SOBRIETY_CHECKIN"

        let messages = [
            "You made it another day without \(substanceType), Champ. That's not small — that's HUGE.",
            "Baby, \(days) days clean. The ancestors are cheering. Don't stop now.",
            "One more day of choosing yourself over \(substanceType). That's real strength.",
            "Champ — \(days) days. Most people can't do what you're doing. Remember that.",
            "Sugar, your sobriety is a gift to yourself AND everyone who loves you. Keep going.",
        ]

        content.body = messages[days % messages.count]

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "sobriety_day_\(days)",
            content: content,
            trigger: trigger
        )

        center.add(request, withCompletionHandler: nil)
    }

    /// Cancel all check-in notifications.
    func cancelAllCheckIns() {
        let ids = [
            "checkin_morning_prayer", "checkin_water", "checkin_breathe",
            "checkin_journal", "checkin_meditate", "checkin_call",
            "checkin_read", "checkin_exercise", "checkin_evening"
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Schedule accountability-specific check-in notifications based on user's selected categories.
    func scheduleAccountabilityCheckIns(for categories: Set<AccountabilityCategory>) {
        // Remove old accountability notifications
        let oldIDs = (0..<50).map { "accountability_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        var notificationIndex = 0

        for category in categories {
            let messages = category.checkInMessages
            guard !messages.isEmpty else { continue }

            // Schedule 2-3 notifications per category at different times
            let times: [(Int, Int)] = [(8, 30), (13, 0), (19, 30)]

            for (timeIndex, (hour, minute)) in times.prefix(min(messages.count, 3)).enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "Check-in: \(category.rawValue)"
                content.body = messages[timeIndex % messages.count]
                content.sound = .default
                content.categoryIdentifier = "ACCOUNTABILITY_CHECKIN"

                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                // Spread across days of the week
                dateComponents.weekday = (notificationIndex % 7) + 1

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )

                let request = UNNotificationRequest(
                    identifier: "accountability_\(notificationIndex)",
                    content: content,
                    trigger: trigger
                )

                center.add(request, withCompletionHandler: nil)
                notificationIndex += 1
            }
        }

        print("[SoulSpeak] Scheduled \(notificationIndex) accountability notifications for \(categories.count) categories")
    }

}
