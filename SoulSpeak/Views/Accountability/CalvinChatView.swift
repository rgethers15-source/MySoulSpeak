import SwiftUI
import SwiftData

/// CalvinChatView — Talk to Calvin, your AI accountability companion.
/// User can ask Calvin to schedule events, check on commitments,
/// get encouragement, or just check in. Calvin knows their full schedule.
///
/// Activated by tapping Calvin's avatar on the calendar view.
struct CalvinChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var calvin = CalvinService.shared
    @State private var inputText: String = ""
    @State private var isTyping = false

    let events: [AccountabilityEvent]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.14),
                        Color(red: 0.08, green: 0.1, blue: 0.18),
                        Color(red: 0.04, green: 0.06, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat header with Calvin's avatar
                    chatHeader

                    // Messages
                    messageList

                    // Input area
                    inputArea
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if calvin.conversationHistory.isEmpty {
                    addWelcomeMessage()
                }
            }
        }
    }

    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }

            // Calvin avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.15, green: 0.35, blue: 0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image("calvin")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Calvin")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text(calvin.isProcessing ? "Thinking..." : "Your Accountability Coach")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            // Quick actions
            Menu {
                Button("Schedule something", action: { inputText = "Calvin, schedule " })
                Button("What's next today?", action: { sendQuickMessage("What do I have coming up today?") })
                Button("How am I doing?", action: { sendQuickMessage("How's my accountability looking this week?") })
                Button("Clear chat", action: { calvin.clearConversation() })
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.top, 50)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(calvin.conversationHistory) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    // Typing indicator
                    if calvin.isProcessing {
                        typingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: calvin.conversationHistory.count) { _, _ in
                if let last = calvin.conversationHistory.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message Bubble
    private func messageBubble(_ message: CalvinService.CalvinMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .calvin {
                // Calvin avatar
                Image("calvin")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }

            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user
                                  ? Color(red: 0.2, green: 0.5, blue: 0.8).opacity(0.4)
                                  : Color.white.opacity(0.07))
                    )

                // Timestamp
                Text(timeString(message.timestamp))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }

            if message.role == .calvin { Spacer() }
        }
    }

    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.4, blue: 0.7).opacity(0.3))
                    .frame(width: 28, height: 28)
                Image("calvin")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .scaleEffect(isTyping ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: isTyping
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .onAppear { isTyping = true }

            Spacer()
        }
    }

    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Quick suggestions
            if calvin.conversationHistory.count <= 1 {
                quickSuggestions
            }

            Divider()
                .overlay(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                TextField("Talk to Calvin...", text: $inputText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )

                // Send button
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(inputText.isEmpty ? Color.white.opacity(0.1) : Color(red: 0.2, green: 0.5, blue: 0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.4))
        }
    }

    // MARK: - Quick Suggestions
    private var quickSuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                suggestionChip("Schedule a workout")
                suggestionChip("What's my week look like?")
                suggestionChip("I need to cancel something")
                suggestionChip("Help me plan tomorrow")
                suggestionChip("Am I on track?")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button(action: { sendQuickMessage(text) }) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.8).opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        Task {
            await calvin.sendMessage(text, events: events)
        }
    }

    private func sendQuickMessage(_ text: String) {
        inputText = ""
        Task {
            await calvin.sendMessage(text, events: events)
        }
    }

    private func addWelcomeMessage() {
        let upcoming = events.filter { !$0.isCompleted && !$0.isCancelled && $0.startDate > Date() }.count
        let completed = events.filter { $0.isCompleted }.count

        let welcome: String
        if events.isEmpty {
            welcome = "Hey! I'm Calvin, your accountability coach. I'm here to help you organize your life and — more importantly — KEEP you organized. Tell me what you need to get done, and I'll make sure it happens. No excuses."
        } else {
            welcome = "Welcome back. You've got \(upcoming) upcoming commitments and \(completed) completed so far. I'm watching. What do you need — schedule something new, check in on your progress, or just talk strategy?"
        }

        let message = CalvinService.CalvinMessage(role: .calvin, content: welcome, timestamp: Date())
        calvin.conversationHistory.append(message)
    }

    // MARK: - Helpers
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
