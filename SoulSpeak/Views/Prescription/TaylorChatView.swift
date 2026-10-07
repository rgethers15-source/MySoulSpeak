import SwiftUI
import SwiftData

/// TaylorChatView — Chat with Taylor Hope about medications.
/// Users can ask about any medication, side effects, interactions,
/// history, dosage, and Taylor explains in simple, warm terms.
struct TaylorChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taylor = TaylorService.shared
    @State private var inputText: String = ""
    @State private var isTyping = false

    let medications: [Medication]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.06, blue: 0.12),
                        Color(red: 0.08, green: 0.08, blue: 0.16),
                        Color(red: 0.04, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    chatHeader
                    messageList
                    inputArea
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if taylor.conversationHistory.isEmpty {
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

            // Taylor avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.4, green: 0.2, blue: 0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Taylor Hope")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text(taylor.isProcessing ? "Thinking..." : "RN • Psychiatry Resident")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Button(action: { taylor.clearConversation() }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.top, 50)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Messages
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(taylor.conversationHistory) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if taylor.isProcessing {
                        typingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: taylor.conversationHistory.count) { _, _ in
                if let last = taylor.conversationHistory.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private func messageBubble(_ message: TaylorService.TaylorMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .taylor {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.3))
                        .frame(width: 28, height: 28)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                }
            }

            if message.role == .user { Spacer() }

            Text(message.content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.role == .user
                              ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3)
                              : Color.white.opacity(0.07))
                )

            if message.role == .taylor { Spacer() }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.3))
                    .frame(width: 28, height: 28)
                Image(systemName: "stethoscope")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
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
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
            .onAppear { isTyping = true }

            Spacer()
        }
    }

    // MARK: - Input
    private var inputArea: some View {
        VStack(spacing: 0) {
            if taylor.conversationHistory.count <= 1 {
                quickSuggestions
            }

            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                TextField("Ask Taylor about any medication...", text: $inputText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.07))
                    )

                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(inputText.isEmpty ? Color.white.opacity(0.1) : Color(red: 0.4, green: 0.8, blue: 0.6))
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

    private var quickSuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                suggestionChip("What are the side effects of Sertraline?")
                suggestionChip("Can I take ibuprofen with my meds?")
                suggestionChip("What happens if I miss a dose?")
                suggestionChip("Tell me about Lexapro")
                suggestionChip("Is it safe to stop cold turkey?")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button(action: { sendQuickMessage(text) }) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.12))
                        .overlay(Capsule().stroke(Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.3), lineWidth: 1))
                )
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await taylor.sendMessage(text, medications: medications) }
    }

    private func sendQuickMessage(_ text: String) {
        Task { await taylor.sendMessage(text, medications: medications) }
    }

    private func addWelcomeMessage() {
        let medCount = medications.filter { $0.isActive }.count
        let welcome: String
        if medications.isEmpty {
            welcome = "Hey! I'm Taylor Hope — I'm an RN and almost done with my psychiatry residency. I'm here to help you understand your medications, manage side effects, or answer any health questions. No judgment, just straight talk. What can I help you with?"
        } else {
            welcome = "Hey! I see you have \(medCount) active medication\(medCount == 1 ? "" : "s"). I can help you understand any of them better — side effects, interactions, timing, or anything else. What's on your mind?"
        }
        let message = TaylorService.TaylorMessage(role: .taylor, content: welcome, timestamp: Date())
        taylor.conversationHistory.append(message)
    }
}
