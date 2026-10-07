import SwiftUI
import SwiftData

/// AccountabilityEventDetailView — Create, edit, or cancel events.
/// KEY FEATURE: To cancel, user MUST type a reason why. Calvin won't let them
/// cancel without accountability. Also handles completing events with encouragement.
struct AccountabilityEventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var calvin = CalvinService.shared

    // If editing an existing event
    var existingEvent: AccountabilityEvent?
    var selectedDate: Date

    // Form state
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: EventCategory = .general
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var priority: EventPriority = .medium
    @State private var reminderMinutes: Int = 15
    @State private var recurrence: String = "none"

    // Cancel flow
    @State private var showCancelFlow = false
    @State private var showCancelTextField = false
    @State private var cancellationReason: String = ""
    @State private var cancelError: String = ""
    @State private var calvinCancelResponse: String = ""

    // Complete flow
    @State private var showCompletionCelebration = false
    @State private var calvinEncouragement: String = ""

    // UI state
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { existingEvent != nil }

    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        self.existingEvent = nil
    }

    init(existingEvent: AccountabilityEvent) {
        self.existingEvent = existingEvent
        self.selectedDate = existingEvent.startDate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Title field
                        titleSection

                        // Category picker
                        categorySection

                        // Date & Time
                        dateTimeSection

                        // Priority
                        prioritySection

                        // Reminder
                        reminderSection

                        // Recurrence
                        recurrenceSection

                        // Notes/Description
                        descriptionSection

                        // Action buttons
                        if isEditing {
                            editActionButtons
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Cancel flow overlay
                if showCancelFlow {
                    cancelFlowOverlay
                }

                // Completion celebration
                if showCompletionCelebration {
                    completionOverlay
                }
            }
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") { saveEvent() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(title.isEmpty ? .white.opacity(0.3) : Color(red: 0.3, green: 0.7, blue: 0.9))
                        .disabled(title.isEmpty)
                }
            }
            .onAppear { loadExistingEvent() }
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you committing to?")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            TextField("Event title...", text: $title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventCategory.allCases) { cat in
                        Button(action: { category = cat }) {
                            HStack(spacing: 5) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 11))
                                Text(cat.displayName)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(category == cat ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(category == cat ? cat.color.opacity(0.3) : Color.white.opacity(0.05))
                                    .overlay(
                                        Capsule()
                                            .stroke(category == cat ? cat.color.opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Date & Time
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            Toggle(isOn: $isAllDay) {
                HStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("All Day")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .tint(Color(red: 0.3, green: 0.7, blue: 0.9))

            DatePicker("Starts", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                .foregroundColor(.white)
                .tint(Color(red: 0.3, green: 0.7, blue: 0.9))

            if !isAllDay {
                DatePicker("Ends", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    .foregroundColor(.white)
                    .tint(Color(red: 0.3, green: 0.7, blue: 0.9))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Priority
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Priority")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 10) {
                ForEach(EventPriority.allCases, id: \.self) { p in
                    Button(action: { priority = p }) {
                        VStack(spacing: 4) {
                            Image(systemName: p.icon)
                                .font(.system(size: 14))
                            Text(p.displayName)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(priority == p ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(priority == p ? p.color.opacity(0.25) : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(priority == p ? p.color.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Reminder
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reminder")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            Picker("Remind me", selection: $reminderMinutes) {
                Text("None").tag(0)
                Text("5 min before").tag(5)
                Text("15 min before").tag(15)
                Text("30 min before").tag(30)
                Text("1 hour before").tag(60)
                Text("1 day before").tag(1440)
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .tint(Color(red: 0.3, green: 0.7, blue: 0.9))
        }
    }

    // MARK: - Recurrence
    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Repeat")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            Picker("Repeat", selection: $recurrence) {
                Text("Never").tag("none")
                Text("Daily").tag("daily")
                Text("Weekly").tag("weekly")
                Text("Monthly").tag("monthly")
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            TextEditor(text: $description)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Edit Action Buttons
    private var editActionButtons: some View {
        VStack(spacing: 12) {
            // Mark Complete
            if !(existingEvent?.isCompleted ?? false) && !(existingEvent?.isCancelled ?? false) {
                Button(action: markComplete) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Mark Complete")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green.opacity(0.3))
                    )
                }

                // Cancel Event (requires reason)
                Button(action: { showCancelFlow = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Cancel This Event")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }

            // Status badge if already completed/cancelled
            if existingEvent?.isCompleted ?? false {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
            }

            if existingEvent?.isCancelled ?? false {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.seal.fill")
                            .foregroundColor(.red)
                        Text("Cancelled")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    if let reason = existingEvent?.cancellationReason, !reason.isEmpty {
                        Text("Reason: \"\(reason)\"")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
            }
        }
    }

    // MARK: - Cancel Flow Overlay (REQUIRES REASON + VIDEO)
    private var cancelFlowOverlay: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Calvin's accountability video plays first
                if !showCancelTextField {
                    FullScreenVideoBackground(
                        videoName: "calvin_cancel",
                        fileExtension: "mp4",
                        looping: false,
                        onFinished: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCancelTextField = true
                            }
                        }
                    )
                    .overlay(
                        // Skip button after 2 seconds
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation { showCancelTextField = true }
                                }) {
                                    Text("Skip")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.white.opacity(0.15)))
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 60)
                            }
                            Spacer()
                        }
                    )
                } else {
                    // After video: text field for cancellation reason
                    cancelReasonForm
                }
            }
        }
    }

    // MARK: - Cancel Reason Form (shown after video)
    private var cancelReasonForm: some View {
        VStack(spacing: 20) {
            Spacer()

            // Calvin's picture
            Image("calvin")
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                )

            Text("Why are you cancelling?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("Be honest with yourself. Calvin's watching.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))

            // Reason text field (REQUIRED)
            VStack(alignment: .leading, spacing: 6) {
                TextEditor(text: $cancellationReason)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(cancellationReason.count < 10 && !cancelError.isEmpty ? Color.red.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )

                HStack {
                    if !cancelError.isEmpty {
                        Text(cancelError)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Text("\(cancellationReason.count)/10 minimum")
                        .font(.system(size: 10))
                        .foregroundColor(cancellationReason.count >= 10 ? .green.opacity(0.7) : .white.opacity(0.3))
                }
            }
            .padding(.horizontal, 24)

            // Calvin's response after confirming
            if !calvinCancelResponse.isEmpty {
                Text(calvinCancelResponse)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(.orange.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .italic()
            }

            Spacer()

            // Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation { showCancelFlow = false; showCancelTextField = false }
                    cancellationReason = ""
                    cancelError = ""
                    calvinCancelResponse = ""
                }) {
                    Text("Go Back")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }

                Button(action: confirmCancellation) {
                    Text("Confirm Cancel")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(cancellationReason.count >= 10 ? Color.red.opacity(0.6) : Color.gray.opacity(0.3))
                        )
                }
                .disabled(cancellationReason.count < 10)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Completion Celebration
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }

                Text("DONE!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(calvinEncouragement)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Keep Going")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.green))
                }
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Actions
    private func saveEvent() {
        if let event = existingEvent {
            // Update existing
            event.title = title
            event.eventDescription = description
            event.category = category.rawValue
            event.startDate = startDate
            event.endDate = endDate
            event.isAllDay = isAllDay
            event.priority = priority.rawValue
            event.reminderMinutesBefore = reminderMinutes
            event.recurrence = recurrence
        } else {
            // Create new
            let event = AccountabilityEvent(
                title: title,
                description: description,
                category: category.rawValue,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                reminderMinutesBefore: reminderMinutes,
                recurrence: recurrence,
                priority: priority.rawValue
            )
            modelContext.insert(event)

            // Schedule notification
            calvin.scheduleReminder(for: event)

            // Sync to Apple Calendar
            if let calID = calvin.syncToAppleCalendar(event: event) {
                event.externalCalendarID = calID
            }
        }

        dismiss()
    }

    private func markComplete() {
        guard let event = existingEvent else { return }
        event.isCompleted = true
        event.completedAt = Date()
        event.streakCount += 1

        // Calvin celebrates
        calvinEncouragement = calvin.generateEncouragement(for: event)
        event.calvinEncouragement = calvinEncouragement

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showCompletionCelebration = true
        }
    }

    private func confirmCancellation() {
        guard cancellationReason.count >= 10 else {
            cancelError = "Calvin needs a REAL reason. At least 10 characters. Be honest."
            return
        }

        guard let event = existingEvent else { return }
        event.isCancelled = true
        event.cancellationReason = cancellationReason
        event.cancelledAt = Date()

        // Calvin's accountability response
        calvinCancelResponse = calvin.generateAccountabilityMessage(for: event, reason: cancellationReason)

        // Brief delay then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
            dismiss()
        }
    }

    private func loadExistingEvent() {
        if let event = existingEvent {
            title = event.title
            description = event.eventDescription
            category = EventCategory(rawValue: event.category) ?? .general
            startDate = event.startDate
            endDate = event.endDate
            isAllDay = event.isAllDay
            priority = EventPriority(rawValue: event.priority) ?? .medium
            reminderMinutes = event.reminderMinutesBefore
            recurrence = event.recurrence
        } else {
            startDate = selectedDate
            endDate = selectedDate.addingTimeInterval(3600)
        }
    }
}
