import Foundation
import SwiftData
import SwiftUI

/// AccountabilityEvent — Core data model for the Accountability Calendar.
/// Every event the user creates, schedules, completes, or cancels is tracked here.
/// Calvin (the AI companion) uses this data to hold the user accountable.
@Model
final class AccountabilityEvent {
    var id: UUID = UUID()
    var title: String = ""
    var eventDescription: String = ""
    var category: String = "general"
    var startDate: Date = Date()
    var endDate: Date = Date()
    var isAllDay: Bool = false
    var isCompleted: Bool = false
    var isCancelled: Bool = false
    var cancellationReason: String = ""
    var cancelledAt: Date?
    var completedAt: Date?
    var reminderMinutesBefore: Int = 15
    var recurrence: String = "none" // none, daily, weekly, monthly
    var priority: String = "medium" // low, medium, high, critical
    var notes: String = ""
    var calvinEncouragement: String = ""
    var missedCount: Int = 0
    var streakCount: Int = 0
    var externalCalendarID: String? // For syncing with Apple Calendar
    var createdAt: Date = Date()
    var createdByCalvin: Bool = false

    init(
        title: String,
        description: String = "",
        category: String = "general",
        startDate: Date,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        reminderMinutesBefore: Int = 15,
        recurrence: String = "none",
        priority: String = "medium"
    ) {
        self.id = UUID()
        self.title = title
        self.eventDescription = description
        self.category = category
        self.startDate = startDate
        self.endDate = endDate ?? startDate.addingTimeInterval(3600)
        self.isAllDay = isAllDay
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrence = recurrence
        self.priority = priority
        self.createdAt = Date()
    }
}

// MARK: - Event Category
enum EventCategory: String, CaseIterable, Identifiable {
    case general = "general"
    case health = "health"
    case fitness = "fitness"
    case work = "work"
    case therapy = "therapy"
    case medication = "medication"
    case selfCare = "self_care"
    case spiritual = "spiritual"
    case social = "social"
    case finance = "finance"
    case education = "education"
    case family = "family"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general: return "General"
        case .health: return "Health"
        case .fitness: return "Fitness"
        case .work: return "Work"
        case .therapy: return "Therapy"
        case .medication: return "Medication"
        case .selfCare: return "Self Care"
        case .spiritual: return "Spiritual"
        case .social: return "Social"
        case .finance: return "Finance"
        case .education: return "Education"
        case .family: return "Family"
        }
    }

    var icon: String {
        switch self {
        case .general: return "calendar"
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .work: return "briefcase.fill"
        case .therapy: return "brain.head.profile"
        case .medication: return "pills.fill"
        case .selfCare: return "sparkles"
        case .spiritual: return "hands.and.sparkles.fill"
        case .social: return "person.2.fill"
        case .finance: return "dollarsign.circle.fill"
        case .education: return "book.fill"
        case .family: return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return Color(red: 0.5, green: 0.5, blue: 0.6)
        case .health: return Color(red: 0.9, green: 0.3, blue: 0.4)
        case .fitness: return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .work: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .therapy: return Color(red: 0.7, green: 0.4, blue: 0.8)
        case .medication: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .selfCare: return Color(red: 0.9, green: 0.5, blue: 0.7)
        case .spiritual: return Color(red: 0.6, green: 0.5, blue: 0.9)
        case .social: return Color(red: 0.4, green: 0.7, blue: 0.8)
        case .finance: return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .education: return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .family: return Color(red: 0.7, green: 0.5, blue: 0.4)
        }
    }
}

// MARK: - Priority Level
enum EventPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.2"
        }
    }
}
