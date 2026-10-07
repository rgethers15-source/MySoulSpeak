import SwiftUI
import SwiftData

/// Analytics Screen: Weekly stats, journaling streaks, mood trends, and progress badges.
struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var journalEntries: [JournalEntry]
    @Query(sort: \MoodEntry.timestamp, order: .reverse) private var moodEntries: [MoodEntry]

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weekly stats header
                weeklyStatsSection
                    .padding(.top, 12)

                // Journaling streak
                streakSection

                // Mood trends
                moodTrendsSection

                // Progress badges
                badgesSection

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .background(SSColors.officeWarm.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Weekly Stats
    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(SSTypography.headline)
                .foregroundColor(SSColors.textPrimary)

            HStack(spacing: 12) {
                statCard(
                    icon: "mic.fill",
                    value: "\(weeklyJournalCount)",
                    label: "Sessions",
                    color: SSColors.primary
                )

                statCard(
                    icon: "clock.fill",
                    value: formattedWeeklyDuration,
                    label: "Total Time",
                    color: SSColors.calm
                )

                statCard(
                    icon: "face.smiling.fill",
                    value: "\(weeklyMoodCount)",
                    label: "Moods Logged",
                    color: SSColors.energy
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(SSColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(SSColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.04))
        )
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                Text("Journaling Streak")
                    .font(SSTypography.headline)
                    .foregroundColor(SSColors.textPrimary)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(SSColors.primary)
                Text(currentStreak == 1 ? "day" : "days")
                    .font(SSTypography.body)
                    .foregroundColor(SSColors.textSecondary)
                    .padding(.bottom, 8)
            }

            // Streak visualization (last 14 days)
            HStack(spacing: 4) {
                ForEach(last14Days(), id: \.self) { date in
                    let hasEntry = hasJournalEntry(on: date)
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(hasEntry ? SSColors.primary : Color.gray.opacity(0.15))
                            .frame(width: 18, height: 18)

                        if calendar.isDateInToday(date) {
                            Circle()
                                .fill(SSColors.primary)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }

            // Best streak
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SSColors.accent)
                Text("Best streak: \(bestStreak) days")
                    .font(SSTypography.caption)
                    .foregroundColor(SSColors.textSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    // MARK: - Mood Trends
    private var moodTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(SSColors.secondary)
                Text("Mood Trends")
                    .font(SSTypography.headline)
                    .foregroundColor(SSColors.textPrimary)
            }

            if moodEntries.isEmpty {
                emptyStateView(
                    icon: "chart.bar.fill",
                    message: "Log moods to see your trends"
                )
            } else {
                // Top moods this week
                VStack(alignment: .leading, spacing: 10) {
                    Text("Most Frequent Moods")
                        .font(SSTypography.caption)
                        .foregroundColor(SSColors.textSecondary)

                    ForEach(topMoods.prefix(4), id: \.mood) { item in
                        moodTrendRow(mood: item.mood, count: item.count, total: moodEntries.count)
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                // Average intensity
                HStack {
                    Text("Average Intensity")
                        .font(SSTypography.caption)
                        .foregroundColor(SSColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f", averageIntensity) + " / 10")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(SSColors.primary)
                }

                // Mood trend direction
                HStack {
                    Text("Weekly Direction")
                        .font(SSTypography.caption)
                        .foregroundColor(SSColors.textSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: moodTrendIcon)
                            .foregroundColor(moodTrendColor)
                        Text(moodTrendLabel)
                            .font(SSTypography.caption)
                            .foregroundColor(moodTrendColor)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    private func moodTrendRow(mood: String, count: Int, total: Int) -> some View {
        let moodType = Mood(rawValue: mood)
        let percentage = total > 0 ? CGFloat(count) / CGFloat(total) : 0

        return HStack(spacing: 10) {
            Text(moodType?.emoji ?? "")
                .font(.system(size: 20))

            Text(mood)
                .font(SSTypography.caption)
                .foregroundColor(SSColors.textPrimary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(moodType?.color ?? SSColors.calm)
                    .frame(width: geo.size.width * percentage)
            }
            .frame(height: 12)

            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SSColors.textSecondary)
        }
        .frame(height: 28)
    }

    // MARK: - Badges Section
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .font(.system(size: 18))
                    .foregroundColor(SSColors.accent)
                Text("Progress Badges")
                    .font(SSTypography.headline)
                    .foregroundColor(SSColors.textPrimary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(allBadges) { badge in
                    badgeView(badge)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    private func badgeView(_ badge: ProgressBadge) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? badge.color.opacity(0.15) : Color.gray.opacity(0.08))
                    .frame(width: 56, height: 56)

                Image(systemName: badge.icon)
                    .font(.system(size: 24))
                    .foregroundColor(badge.isEarned ? badge.color : Color.gray.opacity(0.3))
            }

            Text(badge.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(badge.isEarned ? SSColors.textPrimary : SSColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(badge.isEarned ? 1.0 : 0.5)
    }

    // MARK: - Empty State
    private func emptyStateView(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(SSColors.textSecondary.opacity(0.4))
                Text(message)
                    .font(SSTypography.caption)
                    .foregroundColor(SSColors.textSecondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    // MARK: - Computed Properties
    private var weeklyJournalCount: Int {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return journalEntries.filter { $0.createdAt >= startOfWeek }.count
    }

    private var weeklyMoodCount: Int {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return moodEntries.filter { $0.timestamp >= startOfWeek }.count
    }

    private var formattedWeeklyDuration: String {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let totalSeconds = journalEntries
            .filter { $0.createdAt >= startOfWeek }
            .reduce(0.0) { $0 + $1.duration }
        let minutes = Int(totalSeconds) / 60
        return "\(minutes)m"
    }

    private var currentStreak: Int {
        var streak = 0
        var date = Date()
        while hasJournalEntry(on: date) {
            streak += 1
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            if streak > 365 { break }
        }
        return streak
    }

    private var bestStreak: Int {
        // Simple heuristic: check last 90 days
        var best = 0
        var current = 0
        for offset in (0..<90).reversed() {
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            if hasJournalEntry(on: date) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private func hasJournalEntry(on date: Date) -> Bool {
        journalEntries.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    private func last14Days() -> [Date] {
        (0..<14).compactMap { offset in
            calendar.date(byAdding: .day, value: -13 + offset, to: Date())
        }
    }

    private var topMoods: [(mood: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in moodEntries {
            counts[entry.mood, default: 0] += 1
        }
        return counts.map { (mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var averageIntensity: Double {
        guard !moodEntries.isEmpty else { return 0 }
        let total = moodEntries.reduce(0) { $0 + $1.intensity }
        return Double(total) / Double(moodEntries.count)
    }

    private var moodTrendIcon: String {
        let recentAvg = recentAverageIntensity
        let olderAvg = olderAverageIntensity
        if recentAvg > olderAvg + 0.5 { return "arrow.up.right" }
        if recentAvg < olderAvg - 0.5 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var moodTrendColor: Color {
        let recentAvg = recentAverageIntensity
        let olderAvg = olderAverageIntensity
        if recentAvg > olderAvg + 0.5 { return SSColors.success }
        if recentAvg < olderAvg - 0.5 { return Color.orange }
        return SSColors.textSecondary
    }

    private var moodTrendLabel: String {
        let recentAvg = recentAverageIntensity
        let olderAvg = olderAverageIntensity
        if recentAvg > olderAvg + 0.5 { return "Improving" }
        if recentAvg < olderAvg - 0.5 { return "Declining" }
        return "Steady"
    }

    private var recentAverageIntensity: Double {
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let recent = moodEntries.filter { $0.timestamp >= threeDaysAgo }
        guard !recent.isEmpty else { return 5.0 }
        return Double(recent.reduce(0) { $0 + $1.intensity }) / Double(recent.count)
    }

    private var olderAverageIntensity: Double {
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let older = moodEntries.filter { $0.timestamp >= sevenDaysAgo && $0.timestamp < threeDaysAgo }
        guard !older.isEmpty else { return 5.0 }
        return Double(older.reduce(0) { $0 + $1.intensity }) / Double(older.count)
    }

    // MARK: - Badges
    private var allBadges: [ProgressBadge] {
        [
            ProgressBadge(name: "First Entry", icon: "star.fill", color: SSColors.accent, isEarned: journalEntries.count >= 1),
            ProgressBadge(name: "3-Day Streak", icon: "flame.fill", color: .orange, isEarned: bestStreak >= 3),
            ProgressBadge(name: "Week Warrior", icon: "shield.fill", color: SSColors.primary, isEarned: bestStreak >= 7),
            ProgressBadge(name: "Mood Master", icon: "face.smiling.fill", color: SSColors.calm, isEarned: moodEntries.count >= 10),
            ProgressBadge(name: "Deep Diver", icon: "waveform", color: SSColors.secondary, isEarned: journalEntries.contains { $0.duration > 120 }),
            ProgressBadge(name: "Consistent", icon: "calendar.badge.checkmark", color: SSColors.success, isEarned: bestStreak >= 14),
            ProgressBadge(name: "Soul Searcher", icon: "sparkles", color: SSColors.love, isEarned: journalEntries.count >= 20),
            ProgressBadge(name: "30-Day Journey", icon: "trophy.fill", color: SSColors.accent, isEarned: bestStreak >= 30),
            ProgressBadge(name: "Centurion", icon: "crown.fill", color: Color(red: 0.85, green: 0.65, blue: 0.1), isEarned: journalEntries.count >= 100),
        ]
    }
}

// MARK: - Badge Model
struct ProgressBadge: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let isEarned: Bool
}
