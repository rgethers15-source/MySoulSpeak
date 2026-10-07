import SwiftUI

/// AI Conversation View — Talk to Dr. Hope or Mr. Hope with listen + talk-back.
/// Similar to Google Gemini's conversational interface.
/// Premium feature (requires paid subscription).
struct ConversationView: View {
    let character: GeminiService.Character
    @Environment(\.dismiss) private var dismiss

    @StateObject private var gemini = GeminiService()
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var ttsService = TextToSpeechService()

    @State private var inputText: String = ""
    @State private var isListening = false
    @State private var showingCharacterInfo = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Background
            characterBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                conversationHeader

                // Messages
                messageList

                // Input area
                inputArea
            }
        }
        .onAppear {
            speechService.requestAuthorization()
        }
        .onDisappear {
            ttsService.stop()
            speechService.stopTranscribing()
        }
    }

    // MARK: - Background
    private var characterBackground: some View {
        Group {
            switch character {
            case .drHope:
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.08, blue: 0.2),
                        Color(red: 0.18, green: 0.12, blue: 0.28),
                        Color(red: 0.1, green: 0.07, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .mrHope:
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.2),
                        Color(red: 0.12, green: 0.18, blue: 0.3),
                        Color(red: 0.06, green: 0.1, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Header
    private var conversationHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Character avatar
            Image(character == .drHope ? "dr_hope" : "mr_hope")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(characterColor.opacity(0.6), lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(character.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text(gemini.isProcessing ? "Thinking..." : ttsService.isSpeaking ? "Speaking..." : "Online")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Clear conversation
            Button(action: { gemini.clearConversation() }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Welcome message
                    if gemini.conversationHistory.isEmpty {
                        welcomeMessage
                    }

                    ForEach(gemini.conversationHistory) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    // Processing indicator
                    if gemini.isProcessing {
                        processingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onChange(of: gemini.conversationHistory.count) { _, _ in
                if let last = gemini.conversationHistory.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Welcome Message
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(character == .drHope ? "dr_hope" : "mr_hope")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(characterColor.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: characterColor.opacity(0.3), radius: 10)

            Text(character == .drHope
                 ? "\"Hey baby, what's on your mind today?\nI'm all ears.\""
                 : "\"What's good, Champ!\nTalk to me — what's happening?\"")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .italic()
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
    }

    // MARK: - Message Bubble
    private func messageBubble(_ message: GeminiService.ConversationMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .assistant {
                // Character avatar
                Image(character == .drHope ? "dr_hope" : "mr_hope")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }

            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 14, weight: .regular, design: message.role == .assistant ? .serif : .default))
                    .foregroundColor(message.role == .user ? .white : .white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user
                                  ? characterColor.opacity(0.5)
                                  : Color.white.opacity(0.08))
                    )

                // Play button for assistant messages
                if message.role == .assistant {
                    Button(action: {
                        ttsService.speak(message.content, as: character)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: ttsService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.1")
                                .font(.system(size: 10))
                            Text("Listen")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            if message.role == .assistant { Spacer() }
        }
    }

    // MARK: - Processing Indicator
    private var processingIndicator: some View {
        HStack(spacing: 6) {
            Image(character == .drHope ? "dr_hope" : "mr_hope")
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: pulseAnimation
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .onAppear { pulseAnimation = true }

            Spacer()
        }
    }

    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                // Text input
                TextField("Talk to \(character.rawValue)...", text: $inputText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )

                // Microphone button (hold to listen)
                Button(action: toggleListening) {
                    ZStack {
                        Circle()
                            .fill(isListening ? Color.red.opacity(0.3) : characterColor.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 18))
                            .foregroundColor(isListening ? .red : .white.opacity(0.8))
                    }
                }

                // Send button
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(inputText.isEmpty ? Color.white.opacity(0.1) : characterColor)
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(inputText.isEmpty && !isListening)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""

        Task {
            await gemini.sendMessage(text, character: character)

            // Auto speak the response
            if let lastMsg = gemini.conversationHistory.last, lastMsg.role == .assistant {
                ttsService.speak(lastMsg.content, as: character)
            }
        }
    }

    private func toggleListening() {
        if isListening {
            // Stop listening and send what was captured
            speechService.stopTranscribing()
            isListening = false
            if !speechService.transcribedText.isEmpty {
                inputText = speechService.transcribedText
                sendMessage()
            }
        } else {
            // Start listening
            isListening = true
            speechService.startTranscribing()
        }
    }

    // MARK: - Helpers
    private var characterColor: Color {
        character == .drHope
            ? Color(red: 0.7, green: 0.4, blue: 0.8)
            : Color(red: 0.3, green: 0.6, blue: 0.9)
    }
}
