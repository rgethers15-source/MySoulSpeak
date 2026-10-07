import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var isDarkMode: Bool
    var notificationsEnabled: Bool
    var dailyReminderHour: Int
    var dailyReminderMinute: Int
    var streakCount: Int
    var totalSessions: Int
    var lastSessionDate: Date?

    init(
        id: UUID = UUID(),
        isDarkMode: Bool = false,
        notificationsEnabled: Bool = true,
        dailyReminderHour: Int = 9,
        dailyReminderMinute: Int = 0,
        streakCount: Int = 0,
        totalSessions: Int = 0,
        lastSessionDate: Date? = nil
    ) {
        self.id = id
        self.isDarkMode = isDarkMode
        self.notificationsEnabled = notificationsEnabled
        self.dailyReminderHour = dailyReminderHour
        self.dailyReminderMinute = dailyReminderMinute
        self.streakCount = streakCount
        self.totalSessions = totalSessions
        self.lastSessionDate = lastSessionDate
    }
}
