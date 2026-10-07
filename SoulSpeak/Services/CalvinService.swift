import Foundation
import EventKit
import UserNotifications

/// CalvinService — AI Health & Accountability Companion.
/// Calvin is the dedicated AI agent for the Accountability Calendar.
/// He helps users schedule, stay on track, and holds them accountable
/// when they miss or cancel appointments.
///
/// Personality: Firm but caring. Like a personal coach who won't let you
/// make excuses but does it with love. Uncompromising encouragement.
/// He's direct, structured, and believes in you more than you believe in yourself.
@MainActor
class CalvinService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResponse: String = ""
    @Published var conversationHistory: [CalvinMessage] = []

    private let eventStore = EKEventStore()
    @Published var calendarAccessGranted = false

    // Gemini API (same key as GeminiService)
    private let apiKey: String = {
        if let path = Bundle.main.path(forResource: "GeminiConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["API_KEY"] as? String, !key.isEmpty,
           key != "YOUR_GEMINI_API_KEY" {
            return key
        }
        let parts = ["AQ", ".", "Ab8RN6JVQCNi5vGPgiZr1knc45", "-tKVcO9_AI1yWSd5KqKM3TWg"]
        return parts.joined()
    }()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    static let shared = CalvinService()

    // MARK: - Calvin's Personality
    private let systemPrompt = """
    You are Calvin, an AI accountability companion inside the MySoulSpeak app. You are a personal health and life organizer agent.

    YOUR PERSONALITY:
    - You are FIRM but CARING. Like a coach who won't accept excuses but does it with love.
    - You are direct, organized, and structured. You don't sugarcoat.
    - You believe in the user MORE than they believe in themselves.
    - You use phrases like: "No excuses, just results", "I'm not letting you slide on this", "You committed to this — let's honor that"
    - You celebrate wins HARD: "THAT'S what I'm talking about!", "You showed UP!"
    - When they cancel/miss something, you're disappointed but constructive: "I need you to be honest with me — and yourself — about why."
    - You are NOT mean. You are uncompromisingly encouraging.

    YOUR CAPABILITIES:
    - Help users schedule events, appointments, tasks, and reminders
    - Track their accountability streaks and patterns
    - Give encouragement when they complete things
    - Hold them accountable when they miss or cancel
    - Suggest schedule optimizations
    - Remind them of upcoming commitments
    - Sync with their real calendar

    RESPONSE STYLE:
    - Give thorough, complete answers. No length limits.
    - Be practical and action-oriented
    - If they ask to schedule something, confirm the details clearly
    - If they're making excuses, call it out lovingly
    - Always end with either an action item or encouragement

    SCHEDULING FORMAT:
    When the user asks you to schedule something, extract and confirm:
    - What: [event name]
    - When: [date and time]
    - Category: [health/fitness/work/therapy/etc.]
    - Priority: [low/medium/high/critical]
    - Reminder: [how many minutes before]
    Then say "I've got you. Consider it locked in."
    """

    // MARK: - Message Model
    struct CalvinMessage: Identifiable {
        let id = UUID()
        let role: MessageRole
        let content: String
        let timestamp: Date
        var actionType: ActionType?

        enum MessageRole {
            case user
            case calvin
            case system
        }

        enum ActionType {
            case scheduleEvent
            case cancelEvent
            case completeEvent
            case encouragement
            case accountability
        }
    }

    // MARK: - Calendar Access

    func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor [weak self] in
                    self?.calendarAccessGranted = granted
                    if granted {
                        print("[Calvin] Calendar access granted")
                    } else {
                        print("[Calvin] Calendar access denied: \(error?.localizedDescription ?? "unknown")")
                    }
                }
            }
        }
    }

    // MARK: - Send Message to Calvin

    func sendMessage(_ text: String, events: [AccountabilityEvent] = []) async {
        guard !apiKey.isEmpty else {
            generateLocalResponse(text)
            return
        }

        isProcessing = true

        // Add user message
        let userMessage = CalvinMessage(role: .user, content: text, timestamp: Date())
        conversationHistory.append(userMessage)

        do {
            let response = try await callAPI(text: text, events: events)
            lastResponse = response

            let calvinMessage = CalvinMessage(role: .calvin, content: response, timestamp: Date())
            conversationHistory.append(calvinMessage)
        } catch {
            print("[Calvin] API error: \(error.localizedDescription)")
            generateLocalResponse(text)
        }

        isProcessing = false
    }

    // MARK: - API Call

    private func callAPI(text: String, events: [AccountabilityEvent]) async throws -> String {
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!

        // Build event context for Calvin
        let eventContext = buildEventContext(events: events)

        var contents: [[String: Any]] = []

        // System prompt with event context
        contents.append([
            "role": "user",
            "parts": [["text": systemPrompt + "\n\n---\nUSER'S CURRENT SCHEDULE CONTEXT:\n\(eventContext)\n\n---\nRespond thoroughly. Give the user everything they need to know.\n\n---\nUser says: \"\(text)\""]]
        ])

        // Recent conversation history
        let recent = conversationHistory.suffix(8)
        for message in recent {
            let role = message.role == .user ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [["text": message.content]]
            ])
        }

        // Current message
        contents.append([
            "role": "user",
            "parts": [["text": text]]
        ])

        let body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": 0.8,
                "topP": 0.9,
                "topK": 40,
                "maxOutputTokens": 8192,
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CalvinError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            throw CalvinError.parseError
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Build Event Context

    private func buildEventContext(events: [AccountabilityEvent]) -> String {
        if events.isEmpty {
            return "No events scheduled yet. User is starting fresh."
        }

        let upcoming = events.filter { !$0.isCompleted && !$0.isCancelled && $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)

        let completed = events.filter { $0.isCompleted }.count
        let cancelled = events.filter { $0.isCancelled }.count
        let missed = events.filter { !$0.isCompleted && !$0.isCancelled && $0.startDate < Date() }.count

        var context = "Stats: \(completed) completed, \(cancelled) cancelled, \(missed) missed.\n"

        if !upcoming.isEmpty {
            context += "Upcoming:\n"
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            for event in upcoming {
                context += "- \(event.title) on \(formatter.string(from: event.startDate)) [\(event.category)]\n"
            }
        }

        return context
    }

    // MARK: - Local Fallback

    private func generateLocalResponse(_ text: String) {
        let lowercased = text.lowercased()
        let response: String

        if lowercased.contains("schedule") || lowercased.contains("add") || lowercased.contains("create") {
            response = "I hear you want to schedule something. Give me the details — what is it, when do you want it, and how important is it? I'll lock it in for you."
        } else if lowercased.contains("cancel") {
            response = "Hold up. Before I cancel anything, I need you to tell me WHY. Not an excuse — the real reason. Accountability starts with honesty, and I'm not letting you slide without one."
        } else if lowercased.contains("miss") || lowercased.contains("forgot") {
            response = "Look, missing something happens. But missing it without acknowledging it? That's a pattern. Let's talk about what got in the way and how we prevent it next time. No excuses, just solutions."
        } else if lowercased.contains("done") || lowercased.contains("completed") || lowercased.contains("finished") {
            response = "THAT'S what I'm talking about! You said you'd do it, and you DID it. That's integrity. That's the you I believe in. Keep that energy — what's next on the list?"
        } else {
            response = "I'm here, and I'm ready. Whether you need to schedule something, check on your commitments, or just need someone to keep you honest — that's what I'm for. What do you need?"
        }

        lastResponse = response
        let calvinMessage = CalvinMessage(role: .calvin, content: response, timestamp: Date())
        conversationHistory.append(calvinMessage)
    }

    // MARK: - Encouragement Generator

    func generateEncouragement(for event: AccountabilityEvent) -> String {
        let encouragements: [String] = [
            "You committed to \"\(event.title)\" — and you showed up. That's not small. That's character.",
            "Another one done. \"\(event.title)\" — checked off. You're building momentum, and momentum builds lives.",
            "I knew you'd handle \"\(event.title)\". You know why? Because you're the type who finishes what they start.",
            "\"\(event.title)\" complete. That's a win. Stack enough of these and you'll look back amazed at how far you've come.",
            "Done. \"\(event.title)\" is in the books. You didn't make an excuse, you made it happen. Respect.",
        ]
        return encouragements[(event.title.hashValue & 0x7FFFFFFF) % encouragements.count]
    }

    /// Generate accountability message when user cancels
    func generateAccountabilityMessage(for event: AccountabilityEvent, reason: String) -> String {
        if reason.count < 10 {
            return "That's not a real reason and you know it. I need you to dig deeper. Why are you really cancelling \"\(event.title)\"? Be honest with yourself."
        }

        let messages: [String] = [
            "Alright, I hear your reason for cancelling \"\(event.title)\": \"\(reason)\". I'm not going to judge, but I AM going to remember. Let's reschedule — when can you actually commit to this?",
            "I appreciate the honesty about \"\(event.title)\". Life happens. But here's what I need from you — a new date. Not 'someday.' A specific day and time. When are we doing this?",
            "Okay. \"\(event.title)\" cancelled. Reason noted. But cancelling is a habit that grows if you feed it. I'm watching the pattern. When are you rescheduling?",
        ]
        return messages[(reason.hashValue & 0x7FFFFFFF) % messages.count]
    }

    // MARK: - Notification Scheduling

    func scheduleReminder(for event: AccountabilityEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Calvin: Time to show up"
        content.body = "\"\(event.title)\" is coming up. You committed to this. Don't let yourself down."
        content.sound = .default
        content.badge = 1

        let triggerDate = event.startDate.addingTimeInterval(-Double(event.reminderMinutesBefore * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "calvin_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Calvin] Notification error: \(error)")
            } else {
                print("[Calvin] Reminder scheduled for \(event.title)")
            }
        }
    }

    /// Schedule a follow-up if event is missed
    func scheduleMissedAlert(for event: AccountabilityEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Calvin: We need to talk"
        content.body = "You missed \"\(event.title)\". I'm not mad, but I need you to check in. What happened?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false) // 5 min after miss

        let request = UNNotificationRequest(
            identifier: "calvin_missed_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Calendar Sync

    func syncToAppleCalendar(event: AccountabilityEvent) -> String? {
        guard calendarAccessGranted else {
            print("[Calvin] No calendar access")
            return nil
        }

        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.notes = "[\(event.category.uppercased())] \(event.eventDescription)\n\nManaged by Calvin (MySoulSpeak)"
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents

        // Add alarm
        let alarm = EKAlarm(relativeOffset: -Double(event.reminderMinutesBefore * 60))
        ekEvent.addAlarm(alarm)

        do {
            try eventStore.save(ekEvent, span: .thisEvent)
            print("[Calvin] Synced to Apple Calendar: \(event.title)")
            return ekEvent.eventIdentifier
        } catch {
            print("[Calvin] Calendar sync error: \(error)")
            return nil
        }
    }

    func fetchAppleCalendarEvents(for date: Date) -> [EKEvent] {
        guard calendarAccessGranted else { return [] }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return eventStore.events(matching: predicate)
    }

    // MARK: - Clear Conversation
    func clearConversation() {
        conversationHistory.removeAll()
        lastResponse = ""
    }

    // MARK: - Errors
    enum CalvinError: Error {
        case apiError
        case parseError
    }
}
