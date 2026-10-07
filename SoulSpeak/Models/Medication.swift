import Foundation
import SwiftData
import SwiftUI

/// Medication — Core model for the Prescription Tracker.
/// Tracks medication name, dosage, schedule, pill count, pharmacy, and refill status.
/// Taylor Hope (AI psychiatrist) uses this data to help users manage their prescriptions.
@Model
final class Medication {
    var id: UUID = UUID()
    var name: String = ""
    var genericName: String = ""
    var dosage: String = "" // e.g. "20mg", "500mg"
    var form: String = "tablet" // tablet, capsule, liquid, injection, patch, inhaler
    var frequency: String = "once_daily" // once_daily, twice_daily, three_daily, as_needed, weekly
    var timeOfDay: [String] = [] // ["morning", "evening"]
    var pillCount: Int = 0
    var pillsPerDose: Int = 1
    var totalPrescribed: Int = 30
    var refillDate: Date?
    var prescribedDate: Date = Date()
    var prescribedBy: String = ""
    var purpose: String = "" // What the medication is for
    var instructions: String = "" // Special instructions (with food, etc.)
    var sideEffects: String = ""
    var isActive: Bool = true
    var isTakenToday: Bool = false
    var lastTakenDate: Date?
    var streakCount: Int = 0
    var missedCount: Int = 0
    var pharmacyName: String = ""
    var pharmacyPhone: String = ""
    var pharmacyAddress: String = ""
    var rxNumber: String = "" // Prescription number
    var barcode: String = "" // Scanned barcode data
    var notes: String = ""
    var color: String = "blue" // For UI display
    var createdAt: Date = Date()
    var remindersEnabled: Bool = true
    var reminderTimes: [Date] = []

    init(name: String, dosage: String = "", frequency: String = "once_daily", pillCount: Int = 30) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.pillCount = pillCount
        self.totalPrescribed = pillCount
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    var pillsRemaining: Int { pillCount }

    var isRunningLow: Bool {
        let threshold = max(7, totalPrescribed / 5) // 20% or 7 days worth
        return pillCount <= threshold && pillCount > 0
    }

    var isEmpty: Bool { pillCount <= 0 }

    var daysUntilEmpty: Int {
        guard pillsPerDose > 0 else { return 0 }
        let dosesPerDay: Int
        switch frequency {
        case "once_daily": dosesPerDay = 1
        case "twice_daily": dosesPerDay = 2
        case "three_daily": dosesPerDay = 3
        case "weekly": dosesPerDay = 1 // per week
        default: dosesPerDay = 1
        }
        let dailyUsage = dosesPerDay * pillsPerDose
        guard dailyUsage > 0 else { return 0 }
        if frequency == "weekly" {
            return (pillCount / pillsPerDose) * 7
        }
        return pillCount / dailyUsage
    }

    var frequencyDisplayName: String {
        switch frequency {
        case "once_daily": return "Once Daily"
        case "twice_daily": return "Twice Daily"
        case "three_daily": return "Three Times Daily"
        case "as_needed": return "As Needed"
        case "weekly": return "Weekly"
        default: return frequency
        }
    }

    var formDisplayName: String {
        switch form {
        case "tablet": return "Tablet"
        case "capsule": return "Capsule"
        case "liquid": return "Liquid"
        case "injection": return "Injection"
        case "patch": return "Patch"
        case "inhaler": return "Inhaler"
        default: return form.capitalized
        }
    }

    var displayColor: Color {
        switch color {
        case "blue": return Color(red: 0.3, green: 0.5, blue: 0.9)
        case "green": return Color(red: 0.3, green: 0.7, blue: 0.4)
        case "purple": return Color(red: 0.6, green: 0.4, blue: 0.8)
        case "orange": return Color(red: 0.9, green: 0.6, blue: 0.2)
        case "red": return Color(red: 0.9, green: 0.3, blue: 0.3)
        case "pink": return Color(red: 0.9, green: 0.4, blue: 0.6)
        case "teal": return Color(red: 0.3, green: 0.7, blue: 0.7)
        default: return Color(red: 0.3, green: 0.5, blue: 0.9)
        }
    }

    // MARK: - Actions

    func takeDose() {
        if pillCount > 0 {
            pillCount -= pillsPerDose
            isTakenToday = true
            lastTakenDate = Date()
            streakCount += 1
        }
    }

    func undoLastDose() {
        pillCount += pillsPerDose
        if streakCount > 0 { streakCount -= 1 }
    }

    func refill(count: Int) {
        pillCount += count
        refillDate = Date()
    }
}

// MARK: - Medication Form Types
enum MedicationForm: String, CaseIterable, Identifiable {
    case tablet, capsule, liquid, injection, patch, inhaler

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .tablet: return "pill.fill"
        case .capsule: return "capsule.fill"
        case .liquid: return "drop.fill"
        case .injection: return "syringe.fill"
        case .patch: return "bandage.fill"
        case .inhaler: return "wind"
        }
    }
}

// MARK: - Frequency Types
enum MedicationFrequency: String, CaseIterable, Identifiable {
    case once_daily, twice_daily, three_daily, as_needed, weekly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .once_daily: return "Once Daily"
        case .twice_daily: return "Twice Daily"
        case .three_daily: return "3x Daily"
        case .as_needed: return "As Needed"
        case .weekly: return "Weekly"
        }
    }
}

// MARK: - Pharmacy Model
@Model
final class PharmacyInfo {
    var id: UUID = UUID()
    var name: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var phone: String = ""
    var fax: String = ""
    var hoursMonFri: String = "9:00 AM - 9:00 PM"
    var hoursSaturday: String = "9:00 AM - 6:00 PM"
    var hoursSunday: String = "10:00 AM - 5:00 PM"
    var isDefault: Bool = false
    var latitude: Double = 0
    var longitude: Double = 0
    var website: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String, address: String = "", phone: String = "") {
        self.id = UUID()
        self.name = name
        self.address = address
        self.phone = phone
        self.createdAt = Date()
    }

    var fullAddress: String {
        var parts: [String] = []
        if !address.isEmpty { parts.append(address) }
        if !city.isEmpty { parts.append(city) }
        if !state.isEmpty { parts.append(state) }
        if !zipCode.isEmpty { parts.append(zipCode) }
        return parts.joined(separator: ", ")
    }

    var isOpen: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        // Simple heuristic — assumes standard hours
        let hour = calendar.component(.hour, from: now)
        switch weekday {
        case 1: return hour >= 10 && hour < 17 // Sunday
        case 7: return hour >= 9 && hour < 18 // Saturday
        default: return hour >= 9 && hour < 21 // Mon-Fri
        }
    }
}
