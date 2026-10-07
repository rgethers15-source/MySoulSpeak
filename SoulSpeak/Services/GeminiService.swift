import Foundation

/// Google Gemini AI service for Dr. Hope and Mr. Hope intelligent conversations.
/// Provides listen-and-talk-back capabilities similar to Google Gemini.
///
/// Setup: Add your Gemini API key to the `apiKey` property.
/// Get a key at: https://aistudio.google.com/app/apikey
@MainActor
class GeminiService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResponse: String = ""
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var error: String?

    // MARK: - Configuration

    /// Set your Google Gemini API key here or via environment/config
    private let apiKey: String = {
        // Try to load from bundle plist first
        if let path = Bundle.main.path(forResource: "GeminiConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["API_KEY"] as? String, !key.isEmpty,
           key != "YOUR_GEMINI_API_KEY" && key != "YOUR_GEMINI_API_KEY_HERE" && key != "PASTE_YOUR_GEMINI_API_KEY_HERE" {
            print("[SoulSpeak Gemini] API key loaded from plist, length: \(key.count)")
            return key
        }
        // Configure a private development key locally; never commit credentials.
        return ""
    }()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    // MARK: - Character Personalities

    enum Character: String {
        case drHope = "Dr. Hope"
        case mrHope = "Mr. Hope"

        var systemPrompt: String {
            switch self {
            case .drHope:
                return """
                You are Dr. Hope — a POWERFUL AI therapist with the combined energy of Iyanla Vanzant, Dr. Phil, and a wise Gullah elder. You are BRILLIANT. You are DIRECT. You speak TRUTH that transforms lives.

                WHO YOU ARE:
                - You have the therapeutic intensity of Iyanla Vanzant — you see through people's masks and call out the ROOT issue
                - You have the no-nonsense directness of Dr. Phil — you don't dance around problems, you NAME them
                - You have the spiritual depth of a Gullah elder — you understand spiritual warfare, generational curses, and the power of the ancestors
                - You are educated in: psychology, human biology, sociology, theology, neuroscience, relationship dynamics, trauma responses, and behavioral patterns
                - You are NOT a soft, generic chatbot. You are a REAL therapeutic force.

                HOW YOU OPERATE:
                - You DIAGNOSE the real issue — not the surface complaint. If someone says "I'm tired," you dig into WHY. Is it depression? Burnout? An unhealthy relationship draining them? Spiritual attack?
                - You speak the HARD TRUTH with love. Like Iyanla says: "I'm not here to make you comfortable. I'm here to make you FREE."
                - You educate on spiritual warfare: what it looks like, how the enemy attacks (isolation, confusion, temptation, distraction), and how to fight back with truth and discipline
                - You understand human biology: how cortisol affects decision-making, how trauma rewires the brain, how sleep/nutrition/movement affect mental state
                - You understand sociology: how environment, family systems, generational patterns, and cultural pressure shape behavior
                - You help clients KEEP THEIR PEACE — you teach boundaries, discernment, emotional regulation, and wise decision-making
                - You are INTELLIGENT enough to answer ANY question — science, history, health, relationships, money, career, spirituality — with depth and accuracy

                YOUR VOICE:
                - Direct. Powerful. No filler.
                - You can be warm but you LEAD with truth: "Baby, I love you, but I need to tell you something you don't want to hear..."
                - You call out patterns: "This is the THIRD time you've described this cycle. You see it too, don't you?"
                - You give REAL prescriptions: "Here's what I need you to do this week..."
                - You reference scripture, neuroscience, and lived wisdom in the same breath
                - You ask HARD questions: "What are you getting out of staying stuck?"
                - You don't coddle. You empower.
                - Give thorough, complete answers. No artificial length limits.
                """

            case .mrHope:
                return """
                You are Mr. Hope — a POWERFUL AI mentor with the combined energy of Eric Thomas (ET the Hip Hop Preacher), Steve Harvey's real talk, and a successful Black entrepreneur who built empires. You are RELENTLESS.

                WHO YOU ARE:
                - You have Eric Thomas's FIRE — "When you want to succeed as bad as you want to breathe, THEN you'll be successful"
                - You have Steve Harvey's no-BS wisdom about life, relationships, and money
                - You are a strategic mind — you don't just motivate, you give BLUEPRINTS
                - You understand: business, finance, fitness, discipline, relationships, fatherhood, leadership, and legacy
                - You have ZERO tolerance for excuses but INFINITE belief in potential

                HOW YOU OPERATE:
                - You CHALLENGE mediocrity: "You're better than this and you KNOW it. So why are you settling?"
                - You give REAL strategic advice — not motivational quotes. Actual step-by-step plans.
                - You hold people to a HIGHER standard: "Don't tell me what you're going to do. Tell me what you DID."
                - You understand discipline: how habits form, how winners think differently, how to build systems that don't depend on motivation
                - You educate on financial literacy, time management, health optimization, and relationship strategy
                - You celebrate HARD but you also raise the bar IMMEDIATELY: "That's fire. Now what's the NEXT level?"
                - You are INTELLIGENT enough to answer ANY question with depth — business plans, workout routines, budgets, career pivots, dating strategy — REAL answers

                YOUR VOICE:
                - Intense. Energetic. Like a coach in the locker room at halftime.
                - "Look at me. LOOK AT ME. You are NOT going to waste another year. Not on my watch."
                - You reference success principles, discipline frameworks, and real-world strategy
                - You ask accountability questions: "What did you do TODAY to move closer to your goal?"
                - You don't accept "I'll try" — you demand "I WILL"
                - You're tough because you SEE their greatness and refuse to let them waste it
                - Give thorough, complete answers. No limits on length.
                """
            }
        }
    }

    // MARK: - Conversation Message Model    // MARK: - Conversation Message Model    // MARK: - Conversation Message Model

    struct ConversationMessage: Identifiable {
        let id = UUID()
        let role: MessageRole
        let content: String
        let timestamp: Date

        enum MessageRole {
            case user
            case assistant
        }
    }

    // MARK: - Public API

    /// Send a message to the AI character and get a response.
    func sendMessage(_ text: String, character: Character) async {
        guard !apiKey.isEmpty else {
            print("[SoulSpeak Gemini] No API key — using local fallback")
            await generateLocalResponse(text, character: character)
            return
        }

        isProcessing = true
        error = nil

        // Add user message to history
        let userMessage = ConversationMessage(role: .user, content: text, timestamp: Date())
        conversationHistory.append(userMessage)

        print("[SoulSpeak Gemini] Sending message to \(character.rawValue)...")

        do {
            let response = try await callGeminiAPI(text: text, character: character)
            lastResponse = response
            // Keep journal and conversation text out of logs.

            let assistantMessage = ConversationMessage(role: .assistant, content: response, timestamp: Date())
            conversationHistory.append(assistantMessage)
        } catch {
            print("[SoulSpeak Gemini] API error: \(error.localizedDescription)")
            self.error = "Dr. Hope is taking a moment. Try again, baby."
            // Fallback to local
            await generateLocalResponse(text, character: character)
        }

        isProcessing = false
    }

    /// Clear conversation history (start fresh session)
    func clearConversation() {
        conversationHistory.removeAll()
        lastResponse = ""
        error = nil
    }

    // MARK: - Gemini API Call

    private func callGeminiAPI(text: String, character: Character) async throws -> String {
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!

        // Build conversation context
        var contents: [[String: Any]] = []

        // System instruction as first user message
        contents.append([
            "role": "user",
            "parts": [["text": character.systemPrompt + "\n\n---\nRespond naturally. Be helpful, accurate, and thorough. Give the user ALL the information they need.\n\nUser: \"\(text)\""]]
        ])

        // Add recent conversation history (last 10 messages for context)
        let recentHistory = conversationHistory.suffix(10)
        for message in recentHistory {
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
                "temperature": 0.85,
                "topP": 0.92,
                "topK": 40,
                "maxOutputTokens": 8192,
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"],
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError
        }

        print("[SoulSpeak Gemini] HTTP status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("[SoulSpeak Gemini] Error response: \(errorStr.prefix(300))")
            }
            throw GeminiError.apiError
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            throw GeminiError.parseError
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Local Fallback (when no API key)

    private func generateLocalResponse(_ text: String, character: Character) async {
        // Use existing DrHopeResponseEngine for Dr. Hope
        let response: String
        switch character {
        case .drHope:
            response = DrHopeResponseEngine.generateResponse(for: text)
        case .mrHope:
            response = generateMrHopeResponse(for: text)
        }

        lastResponse = response
        let assistantMessage = ConversationMessage(role: .assistant, content: response, timestamp: Date())
        conversationHistory.append(assistantMessage)
    }

    private func generateMrHopeResponse(for text: String) -> String {
        let lowercased = text.lowercased()
        let responses: [String]

        if lowercased.contains("happy") || lowercased.contains("good") || lowercased.contains("great") {
            responses = [
                "That's what I'm talking about, Champ! Keep that energy up. You earned this good feeling!",
                "Now THAT'S the vibe! Ride that wave, Champ. You deserve every bit of it.",
                "Yes sir! Look at you glowing! I'm proud of you, Champ. Keep stacking those wins!",
            ]
        } else if lowercased.contains("tired") || lowercased.contains("exhausted") || lowercased.contains("drained") {
            responses = [
                "Hey Champ, even MVPs need rest days. No shame in recharging. You'll come back stronger.",
                "Listen, your body's telling you something. Honor it. Rest ain't quitting — it's strategy.",
                "Take the breather, Champ. Tomorrow's a fresh start. You've already proven you're a fighter.",
            ]
        } else if lowercased.contains("scared") || lowercased.contains("afraid") || lowercased.contains("nervous") {
            responses = [
                "Champ, courage ain't the absence of fear — it's showing up anyway. And you showed up today!",
                "I hear you. But remember — you've faced hard things before and you're still standing. That's not luck.",
                "Hey, every champion feels nervous before the big moment. That's just your body getting ready to perform!",
            ]
        } else if lowercased.contains("angry") || lowercased.contains("mad") || lowercased.contains("frustrated") {
            responses = [
                "I feel you, Champ. That fire? Use it as fuel, not as a weapon. Channel it into something powerful.",
                "Real talk — it's okay to be heated. Just don't let it drive the bus. You're still in control.",
                "Hey, anger means you care about something deeply. That's not weakness. Let's figure out what to do with it.",
            ]
        } else {
            responses = [
                "I hear you, Champ. Whatever you're going through, you're not going through it alone. I got you.",
                "Thanks for keeping it real with me. That takes guts. You're doing better than you think.",
                "Champ, just the fact that you're talking about it? That's a win. Most people keep it bottled up. You're ahead of the game.",
                "Real talk — life throws curveballs. But you've got a solid swing. Let's figure this out together.",
            ]
        }

        return responses[abs(text.hashValue) % responses.count]
    }

    // MARK: - Errors
    enum GeminiError: Error {
        case apiError
        case parseError
        case noAPIKey
    }
}
