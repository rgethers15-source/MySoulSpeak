import SwiftUI

// MARK: - Color Palette
enum SSColors {
    static let primary = Color(red: 0.4, green: 0.3, blue: 0.8)
    static let secondary = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let accent = Color(red: 0.85, green: 0.65, blue: 0.2)
    static let warmBrown = Color(red: 0.45, green: 0.3, blue: 0.2)
    static let officeWarm = Color(red: 0.95, green: 0.92, blue: 0.88)
    static let officeDark = Color(red: 0.12, green: 0.1, blue: 0.18)
    static let textPrimary = Color(red: 0.15, green: 0.12, blue: 0.2)
    static let textSecondary = Color(red: 0.45, green: 0.42, blue: 0.5)
    static let cardBackground = Color.white.opacity(0.95)
    static let success = Color(red: 0.3, green: 0.75, blue: 0.45)
    static let calm = Color(red: 0.55, green: 0.75, blue: 0.9)
    static let energy = Color(red: 1.0, green: 0.7, blue: 0.3)
    static let love = Color(red: 0.9, green: 0.4, blue: 0.5)

    static let gradientPrimary = LinearGradient(
        colors: [Color(red: 0.35, green: 0.25, blue: 0.7), Color(red: 0.55, green: 0.35, blue: 0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientWarm = LinearGradient(
        colors: [Color(red: 0.95, green: 0.88, blue: 0.78), Color(red: 0.92, green: 0.82, blue: 0.7)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let gradientOffice = LinearGradient(
        colors: [Color(red: 0.18, green: 0.14, blue: 0.26), Color(red: 0.25, green: 0.2, blue: 0.35)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography
enum SSTypography {
    static let largeTitle = Font.system(size: 32, weight: .bold, design: .serif)
    static let title = Font.system(size: 24, weight: .semibold, design: .serif)
    static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let small = Font.system(size: 11, weight: .regular, design: .rounded)
}

// MARK: - Mood Definitions
enum Mood: String, CaseIterable, Identifiable {
    case joyful = "Joyful"
    case peaceful = "Peaceful"
    case grateful = "Grateful"
    case anxious = "Anxious"
    case sad = "Sad"
    case angry = "Angry"
    case hopeful = "Hopeful"
    case tired = "Tired"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .joyful: return "😊"
        case .peaceful: return "😌"
        case .grateful: return "🙏"
        case .anxious: return "😰"
        case .sad: return "😢"
        case .angry: return "😤"
        case .hopeful: return "🌟"
        case .tired: return "😴"
        }
    }

    var color: Color {
        switch self {
        case .joyful: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .peaceful: return SSColors.calm
        case .grateful: return SSColors.success
        case .anxious: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .sad: return Color(red: 0.4, green: 0.5, blue: 0.8)
        case .angry: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .hopeful: return SSColors.secondary
        case .tired: return Color(red: 0.6, green: 0.6, blue: 0.7)
        }
    }
}
