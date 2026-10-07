import SwiftUI

/// Mirror Progress View — Track your journey across all affliction courses.
/// Shows streak, total sessions completed, active courses, and overall growth.
/// Motivational and visual — makes the user feel their progress is real.
struct MirrorProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("mirrorTotalSessions") private var totalSessions: Int = 0
    @AppStorage("mirrorCurrentStreak") private var currentStreak: Int = 0
    @AppStorage("mirrorLongestStreak") private var longestStreak: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.04, blue: 0.08),
                        Color(red: 0.06, green: 0.05, blue: 0.12),
                        Color(red: 0.04, green: 0.04, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header stats
                        headerStats

                        // Active courses
                        activeCourses

                        // Weekly grid
                        weeklyGrid

                        // Motivational quote
                        motivationalSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalSessions)", label: "Sessions", icon: "checkmark.circle.fill", color: Color(red: 0.4, green: 0.8, blue: 0.5))
            statCard(value: "\(currentStreak)", label: "Day Streak", icon: "flame.fill", color: Color(red: 0.9, green: 0.5, blue: 0.2))
            statCard(value: "\(longestStreak)", label: "Best Streak", icon: "trophy.fill", color: Color(red: 0.95, green: 0.78, blue: 0.3))
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Active Courses
    private var activeCourses: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Courses")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // Read progress from AppStorage for each affliction
            ForEach(activeAfflictionProgress, id: \.name) { progress in
                courseProgressRow(progress)
            }

            if activeAfflictionProgress.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No courses started yet")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))

                    Text("Choose an affliction to begin your Mirror journey")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func courseProgressRow(_ progress: AfflictionProgress) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(progress.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: progress.icon)
                    .font(.system(size: 14))
                    .foregroundColor(progress.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(progress.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        Capsule()
                            .fill(progress.color)
                            .frame(width: max(0, geo.size.width * progress.percentage), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Percentage
            Text("\(Int(progress.percentage * 100))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(progress.color)
        }
    }

    // MARK: - Weekly Grid
    private var weeklyGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 6) {
                        Text(dayLabel(day))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        Circle()
                            .fill(dayCompleted(day) ? Color(red: 0.4, green: 0.8, blue: 0.5) : Color.white.opacity(0.08))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Group {
                                    if dayCompleted(day) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func dayLabel(_ index: Int) -> String {
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return labels[index]
    }

    private func dayCompleted(_ index: Int) -> Bool {
        // Simple heuristic: mark days up to current streak
        let today = Calendar.current.component(.weekday, from: Date())
        let adjustedToday = (today + 5) % 7 // Adjust so Monday = 0
        return index <= adjustedToday && index >= (adjustedToday - currentStreak + 1) && currentStreak > 0
    }

    // MARK: - Motivational Section
    private var motivationalSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "quote.opening")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.2))

            Text(motivationalQuote)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .italic()
                .lineSpacing(4)

            Text("Keep going. The mirror doesn't lie —\nbut it also shows growth.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private var motivationalQuote: String {
        let quotes = [
            "The only person you are destined to become is the person you decide to be.",
            "Healing is not linear, but every step counts.",
            "You cannot heal what you refuse to confront.",
            "Change is painful. But nothing is as painful as staying stuck.",
            "The wound is the place where the light enters you.",
            "You've survived 100% of your worst days so far.",
            "Growth is uncomfortable because you've never been here before.",
        ]
        return quotes[totalSessions % quotes.count]
    }

    // MARK: - Active Course Data
    private var activeAfflictionProgress: [AfflictionProgress] {
        // Check AppStorage for each known affliction
        let afflictions: [(String, String, Color, Int)] = [
            ("Procrastination", "clock.arrow.circlepath", Color(red: 0.9, green: 0.6, blue: 0.2), 14),
            ("Pornography Addiction", "eye.slash.fill", Color(red: 0.7, green: 0.3, blue: 0.3), 21),
            ("Self-Harm", "bandage.fill", Color(red: 0.6, green: 0.3, blue: 0.5), 18),
            ("Substance Dependency", "pills.fill", Color(red: 0.5, green: 0.4, blue: 0.7), 21),
            ("Disordered Eating", "fork.knife", Color(red: 0.8, green: 0.5, blue: 0.4), 16),
            ("Social Media Addiction", "iphone.slash", Color(red: 0.3, green: 0.6, blue: 0.8), 10),
            ("Depression", "cloud.rain.fill", Color(red: 0.4, green: 0.5, blue: 0.8), 21),
            ("Anxiety & Worry", "tornado", Color(red: 0.6, green: 0.5, blue: 0.9), 16),
            ("Anger Management", "flame.fill", Color(red: 0.9, green: 0.35, blue: 0.2), 14),
            ("Grief & Loss", "leaf.fill", Color(red: 0.4, green: 0.6, blue: 0.5), 18),
            ("Shame & Guilt", "lock.open.fill", Color(red: 0.6, green: 0.4, blue: 0.4), 14),
            ("Loneliness", "person.fill.questionmark", Color(red: 0.5, green: 0.5, blue: 0.7), 12),
            ("Co-Dependency", "person.2.slash.fill", Color(red: 0.7, green: 0.4, blue: 0.5), 16),
            ("Childhood Trauma", "figure.and.child.holdinghands", Color(red: 0.6, green: 0.5, blue: 0.8), 21),
            ("Toxic Relationships", "link.badge.plus", Color(red: 0.8, green: 0.3, blue: 0.4), 14),
            ("People Pleasing", "theatermasks.fill", Color(red: 0.7, green: 0.6, blue: 0.3), 12),
            ("Trust Issues", "shield.slash.fill", Color(red: 0.5, green: 0.5, blue: 0.6), 14),
            ("Abandonment Fear", "door.left.hand.open", Color(red: 0.6, green: 0.4, blue: 0.7), 14),
            ("Identity Conflict", "person.crop.circle.badge.questionmark", Color(red: 0.5, green: 0.7, blue: 0.6), 18),
            ("Low Self-Worth", "star.slash.fill", Color(red: 0.8, green: 0.5, blue: 0.3), 16),
            ("Perfectionism", "checkmark.seal.fill", Color(red: 0.4, green: 0.6, blue: 0.7), 12),
            ("Imposter Syndrome", "person.crop.circle.badge.exclamationmark", Color(red: 0.6, green: 0.5, blue: 0.8), 10),
            ("Purpose & Direction", "compass.drawing", Color(red: 0.4, green: 0.7, blue: 0.5), 14),
        ]

        var active: [AfflictionProgress] = []
        for (name, icon, color, total) in afflictions {
            let key = "mirror_\(name)_completed"
            let completed = UserDefaults.standard.integer(forKey: key)
            if completed > 0 {
                active.append(AfflictionProgress(
                    name: name,
                    icon: icon,
                    color: color,
                    completed: completed,
                    total: total,
                    percentage: CGFloat(completed) / CGFloat(total)
                ))
            }
        }
        return active.sorted { $0.percentage > $1.percentage }
    }
}

// MARK: - Progress Model
struct AfflictionProgress {
    let name: String
    let icon: String
    let color: Color
    let completed: Int
    let total: Int
    let percentage: CGFloat
}
