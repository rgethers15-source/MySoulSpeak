import SwiftUI
import SwiftData

/// AccountabilityCalendarView — The ultimate life organizer.
/// Main calendar interface with month view, day detail, event list,
/// and Calvin's picture in the corner to activate him.
///
/// Features:
/// - Month grid with colored dots for events
/// - Day view showing all events for selected date
/// - Quick-add button for new events
/// - Calvin avatar button to chat with him
/// - Streak counter and accountability stats
/// - Syncs with Apple Calendar
struct AccountabilityCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AccountabilityEvent.startDate) private var allEvents: [AccountabilityEvent]
    @StateObject private var calvin = CalvinService.shared

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showAddEvent = false
    @State private var showCalvinChat = false
    @State private var showEventDetail: AccountabilityEvent? = nil
    @State private var viewMode: ViewMode = .month
    @State private var showIntroVideo = true
    @AppStorage("hasSeenCalvinIntro") private var hasSeenCalvinIntro = false

    enum ViewMode: String, CaseIterable {
        case month = "Month"
        case week = "Week"
        case day = "Day"
    }

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            if showIntroVideo && !hasSeenCalvinIntro {
                // Calvin's intro video
                FullScreenVideoBackground(
                    videoName: "calvin_intro",
                    fileExtension: "mp4",
                    looping: false,
                    onFinished: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showIntroVideo = false
                            hasSeenCalvinIntro = true
                        }
                    }
                )
            } else {
                calendarContent
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            calvin.requestCalendarAccess()
            if hasSeenCalvinIntro {
                showIntroVideo = false
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AccountabilityEventDetailView(selectedDate: selectedDate)
        }
        .sheet(isPresented: $showCalvinChat) {
            CalvinChatView(events: allEvents)
        }
        .sheet(item: $showEventDetail) { event in
            AccountabilityEventDetailView(existingEvent: event)
        }
    }

    // MARK: - Calendar Content
    private var calendarContent: some View {
        ZStack {
            // Background
            Color(red: 0.06, green: 0.06, blue: 0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                calendarHeader

                // View mode selector
                viewModeSelector

                // Calendar content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewMode == .month {
                            monthGridView
                        }

                        // Selected day events
                        dayEventsSection

                        // Stats bar
                        statsBar

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Calvin floating avatar (bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    calvinFloatingButton
                }
            }

            // Add event button (bottom-left)
            VStack {
                Spacer()
                HStack {
                    addEventButton
                    Spacer()
                }
            }
        }
    }

    // MARK: - Header
    private var calendarHeader: some View {
        HStack(spacing: 14) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Accountability")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Your life, organized by Calvin")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Today button
            Button(action: {
                selectedDate = Date()
                currentMonth = Date()
            }) {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.15))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - View Mode Selector
    private var viewModeSelector: some View {
        HStack(spacing: 0) {
            // Month navigation
            Button(action: { moveMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(8)
            }

            Text(dateFormatter.string(from: currentMonth))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(minWidth: 140)

            Button(action: { moveMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(8)
            }

            Spacer()

            // View toggle
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Month Grid
    private var monthGridView: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayEvents = eventsForDate(date)
        let hasEvents = !dayEvents.isEmpty

        return Button(action: { selectedDate = date }) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : isToday ? Color(red: 0.3, green: 0.7, blue: 0.9) : .white.opacity(0.7))

                // Event dots
                if hasEvents {
                    HStack(spacing: 2) {
                        ForEach(dayEvents.prefix(3), id: \.id) { event in
                            Circle()
                                .fill(EventCategory(rawValue: event.category)?.color ?? .gray)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(width: 36, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.3) : Color.clear)
            )
        }
    }

    // MARK: - Day Events Section
    private var dayEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                Text(selectedDateFormatted)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(eventsForDate(selectedDate).count) events")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Events list
            let dayEvents = eventsForDate(selectedDate)
            if dayEvents.isEmpty {
                emptyDayView
            } else {
                ForEach(dayEvents, id: \.id) { event in
                    eventRow(event)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var emptyDayView: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.2))

            Text("Nothing scheduled")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))

            Text("Tap + to add an event, or ask Calvin to schedule something")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func eventRow(_ event: AccountabilityEvent) -> some View {
        Button(action: { showEventDetail = event }) {
            HStack(spacing: 12) {
                // Time + color bar
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(EventCategory(rawValue: event.category)?.color ?? .gray)
                        .frame(width: 3, height: 36)
                        .cornerRadius(2)
                }

                // Event info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(event.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(event.isCancelled ? .white.opacity(0.3) : .white)
                            .strikethrough(event.isCancelled)

                        if event.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }

                        if event.priority == "critical" || event.priority == "high" {
                            Image(systemName: EventPriority(rawValue: event.priority)?.icon ?? "minus")
                                .font(.system(size: 10))
                                .foregroundColor(EventPriority(rawValue: event.priority)?.color ?? .gray)
                        }
                    }

                    HStack(spacing: 8) {
                        // Time
                        if !event.isAllDay {
                            Text(timeString(event.startDate))
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Text("All Day")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        // Category
                        HStack(spacing: 3) {
                            Image(systemName: EventCategory(rawValue: event.category)?.icon ?? "calendar")
                                .font(.system(size: 9))
                            Text(EventCategory(rawValue: event.category)?.displayName ?? "General")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(EventCategory(rawValue: event.category)?.color.opacity(0.8) ?? .gray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(event.isCompleted ? Color.green.opacity(0.05) : event.isCancelled ? Color.red.opacity(0.05) : Color.white.opacity(0.03))
            )
        }
    }

    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 12) {
            statPill(value: "\(completedCount)", label: "Done", color: .green)
            statPill(value: "\(currentStreak)", label: "Streak", color: .orange)
            statPill(value: "\(cancelledCount)", label: "Cancelled", color: .red)
            statPill(value: "\(upcomingCount)", label: "Upcoming", color: .blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calvin Floating Button
    private var calvinFloatingButton: some View {
        Button(action: { showCalvinChat = true }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.15, green: 0.35, blue: 0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.8).opacity(0.4), radius: 8, y: 4)

                Image("calvin")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Add Event Button
    private var addEventButton: some View {
        Button(action: { showAddEvent = true }) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.3, green: 0.7, blue: 0.4))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(red: 0.3, green: 0.7, blue: 0.4).opacity(0.4), radius: 8, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.leading, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Helpers
    private func moveMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        // Pad to fill grid
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func eventsForDate(_ date: Date) -> [AccountabilityEvent] {
        allEvents.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // Stats
    private var completedCount: Int { allEvents.filter { $0.isCompleted }.count }
    private var cancelledCount: Int { allEvents.filter { $0.isCancelled }.count }
    private var upcomingCount: Int { allEvents.filter { !$0.isCompleted && !$0.isCancelled && $0.startDate > Date() }.count }
    private var currentStreak: Int {
        var streak = 0
        var date = Date()
        for _ in 0..<30 {
            let dayEvents = eventsForDate(date)
            if dayEvents.isEmpty { break }
            if dayEvents.allSatisfy({ $0.isCompleted || $0.isCancelled }) {
                streak += 1
            } else {
                break
            }
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return streak
    }
}
