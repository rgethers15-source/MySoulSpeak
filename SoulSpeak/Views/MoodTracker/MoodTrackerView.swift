import SwiftUI
import SwiftData

/// Mood Tracker Screen: Calendar with emotion icons, mood history chart, and reflection prompt.
struct MoodTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MoodEntry.timestamp, order: .reverse) private var moodEntries: [MoodEntry]

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showAddMood = false
    @State private var reflectionText: String = ""
    @State private var selectedMoodForAdd: Mood?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Calendar section
                calendarSection
                    .padding(.top, 12)

                // Mood history chart
                moodChartSection

                // Reflection prompt
                reflectionSection

                // Quick add mood
                if showAddMood {
                    quickAddMoodSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .background(SSColors.officeWarm.ignoresSafeArea())
        .navigationTitle("Mood Tracker")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(SSColors.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showAddMood.toggle()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(SSColors.primary)
                }
            }
        }
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SSColors.primary)
                }

                Spacer()

                Text(monthYearString)
                    .font(SSTypography.headline)
                    .foregroundColor(SSColors.textPrimary)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SSColors.primary)
                }
            }
            .padding(.horizontal, 8)

            // Day headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SSColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days with mood emojis
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: 44)
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

    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let moodForDay = moodEntry(for: date)

        return Button(action: {
            selectedDate = date
        }) {
            VStack(spacing: 2) {
                if let mood = moodForDay {
                    Text(Mood(rawValue: mood.mood)?.emoji ?? "")
                        .font(.system(size: 18))
                } else {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .regular))
                        .foregroundColor(
                            isToday ? .white :
                            isSelected ? SSColors.primary : SSColors.textPrimary
                        )
                }
            }
            .frame(width: 38, height: 38)
            .background(
                Circle()
                    .fill(
                        isToday ? SSColors.primary :
                        isSelected ? SSColors.primary.opacity(0.1) : Color.clear
                    )
            )
        }
    }

    // MARK: - Mood Chart Section
    private var moodChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Moods")
                .font(SSTypography.headline)
                .foregroundColor(SSColors.textPrimary)

            if weekMoods.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 36))
                            .foregroundColor(SSColors.textSecondary.opacity(0.5))
                        Text("No mood entries this week")
                            .font(SSTypography.caption)
                            .foregroundColor(SSColors.textSecondary)
                        Text("Add your first mood to see trends")
                            .font(SSTypography.small)
                            .foregroundColor(SSColors.textSecondary.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                // Bar chart representation
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(last7Days(), id: \.self) { date in
                        VStack(spacing: 4) {
                            if let entry = moodEntry(for: date) {
                                let mood = Mood(rawValue: entry.mood)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(mood?.color ?? SSColors.calm)
                                    .frame(width: 32, height: CGFloat(entry.intensity) * 8)

                                Text(mood?.emoji ?? "")
                                    .font(.system(size: 14))
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 32, height: 8)

                                Text("·")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }

                            Text(dayAbbreviation(date))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(SSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    // MARK: - Reflection Section
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(SSColors.accent)
                Text("Reflection Prompt")
                    .font(SSTypography.headline)
                    .foregroundColor(SSColors.textPrimary)
            }

            Text(dailyReflectionPrompt)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(SSColors.textPrimary.opacity(0.8))
                .italic()
                .lineSpacing(4)

            TextField("Write your reflection...", text: $reflectionText, axis: .vertical)
                .font(SSTypography.body)
                .lineLimit(3...6)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SSColors.officeWarm)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    // MARK: - Quick Add Mood
    private var quickAddMoodSection: some View {
        VStack(spacing: 16) {
            Text("How are you feeling right now?")
                .font(SSTypography.headline)
                .foregroundColor(SSColors.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    Button(action: {
                        selectedMoodForAdd = mood
                    }) {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 30))
                            Text(mood.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(
                                    selectedMoodForAdd == mood ? mood.color : SSColors.textSecondary
                                )
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMoodForAdd == mood ? mood.color.opacity(0.15) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMoodForAdd == mood ? mood.color : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }

            if selectedMoodForAdd != nil {
                // Intensity slider
                VStack(spacing: 8) {
                    Text("Intensity")
                        .font(SSTypography.caption)
                        .foregroundColor(SSColors.textSecondary)

                    IntensitySelector(intensity: .constant(5))
                }

                Button(action: saveMoodEntry) {
                    Text("Log Mood")
                        .font(SSTypography.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(
                            Capsule()
                                .fill(SSColors.gradientPrimary)
                        )
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

    // MARK: - Helpers
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func moodEntry(for date: Date) -> MoodEntry? {
        moodEntries.first { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: date)
        }
    }

    private var weekMoods: [MoodEntry] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return moodEntries.filter { $0.timestamp >= startOfWeek }
    }

    private func last7Days() -> [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -6 + offset, to: Date())
        }
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dailyReflectionPrompt: String {
        let prompts = [
            "What emotion visited you most today? Did it stay or pass through?",
            "If your mood were weather, what would today's forecast be?",
            "What's one small thing that shifted your energy today?",
            "Close your eyes. What does your body tell you about today?",
            "What would Dr. Hope say about how you're feeling right now?",
            "Name one thing you're grateful for in this moment.",
            "What color does today feel like? Why?",
        ]
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return prompts[dayOfYear % prompts.count]
    }

    private func saveMoodEntry() {
        guard let mood = selectedMoodForAdd else { return }
        let entry = MoodEntry(mood: mood.rawValue, intensity: 5, note: reflectionText.isEmpty ? nil : reflectionText)
        modelContext.insert(entry)
        withAnimation {
            showAddMood = false
            selectedMoodForAdd = nil
        }
    }
}

// MARK: - Intensity Selector
struct IntensitySelector: View {
    @Binding var intensity: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...10, id: \.self) { level in
                Circle()
                    .fill(level <= intensity ? SSColors.primary : SSColors.primary.opacity(0.15))
                    .frame(width: 22, height: 22)
                    .onTapGesture {
                        intensity = level
                    }
            }
        }
    }
}
