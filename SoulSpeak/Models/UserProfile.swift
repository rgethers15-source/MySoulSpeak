import Foundation
import SwiftData

/// Stores user's personal information, goals, and progress.
/// The AI uses this to personalize conversations and remember context.
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var preferredName: String
    var emergencyContactName: String
    var emergencyContactPhone: String
    var goals: [String]
    var struggles: [String]
    var sobrietyStartDate: Date?
    var isInRecovery: Bool
    var substanceType: String?
    var faithPreference: String
    var accountabilityCategories: [String]
    var createdAt: Date
    var lastCheckIn: Date?

    // Daily tracking
    var prayedToday: Bool
    var journaledToday: Bool
    var meditatedToday: Bool
    var drankWaterToday: Bool
    var exercisedToday: Bool
    var deepBreathToday: Bool
    var calledLovedOneToday: Bool
    var readBookToday: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        preferredName: String = "",
        emergencyContactName: String = "",
        emergencyContactPhone: String = "",
        goals: [String] = [],
        struggles: [String] = [],
        sobrietyStartDate: Date? = nil,
        isInRecovery: Bool = false,
        substanceType: String? = nil,
        faithPreference: String = "Christian",
        accountabilityCategories: [String] = [],
        createdAt: Date = Date(),
        lastCheckIn: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.preferredName = preferredName
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.goals = goals
        self.struggles = struggles
        self.sobrietyStartDate = sobrietyStartDate
        self.isInRecovery = isInRecovery
        self.substanceType = substanceType
        self.faithPreference = faithPreference
        self.accountabilityCategories = accountabilityCategories
        self.createdAt = createdAt
        self.lastCheckIn = lastCheckIn
        self.prayedToday = false
        self.journaledToday = false
        self.meditatedToday = false
        self.drankWaterToday = false
        self.exercisedToday = false
        self.deepBreathToday = false
        self.calledLovedOneToday = false
        self.readBookToday = false
    }

    /// Number of days sober (if in recovery)
    var sobrietyDays: Int {
        guard let start = sobrietyStartDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
    }

    /// Reset daily tracking (call at midnight)
    func resetDailyTracking() {
        prayedToday = false
        journaledToday = false
        meditatedToday = false
        drankWaterToday = false
        exercisedToday = false
        deepBreathToday = false
        calledLovedOneToday = false
        readBookToday = false
    }

    /// Build context string for AI conversations
    func aiContext() -> String {
        var context = "User's name is \(preferredName.isEmpty ? name : preferredName). "

        if !goals.isEmpty {
            context += "Their goals are: \(goals.joined(separator: ", ")). "
        }
        if !struggles.isEmpty {
            context += "They struggle with: \(struggles.joined(separator: ", ")). "
        }
        if isInRecovery {
            context += "They are in recovery from \(substanceType ?? "substance use"). "
            context += "They have been sober for \(sobrietyDays) days. "
        }
        context += "Faith preference: \(faithPreference). "

        // Today's progress
        var completed: [String] = []
        if prayedToday { completed.append("prayed") }
        if journaledToday { completed.append("journaled") }
        if meditatedToday { completed.append("meditated") }
        if drankWaterToday { completed.append("drank water") }
        if exercisedToday { completed.append("exercised") }
        if deepBreathToday { completed.append("did breathing exercises") }
        if calledLovedOneToday { completed.append("called a loved one") }
        if readBookToday { completed.append("read a book") }

        if !completed.isEmpty {
            context += "Today they have: \(completed.joined(separator: ", ")). "
        } else {
            context += "They haven't completed any wellness activities today yet. "
        }

        return context
    }
}
