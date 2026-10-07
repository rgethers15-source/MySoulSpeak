import SwiftUI
import SwiftData

/// Voice Journal — Immersive therapy session experience.
///
/// Flow:
/// 1. Doorway video (walking into Dr. Hope's office)
/// 2. Office scene: Dr. Hope portrait + "Speak your truth" + Record button
/// 3. Recording: "Go on, speak your truth" audio plays, user records
/// 4. Post-recording: Dr. Hope listening video loops while AI analyzes
/// 5. "Analyze" button: user taps for Dr. Hope's AI advice
/// 6. AI stores all entries and learns over time
///
/// Videos needed:
/// - journal_door_entry.mp4 (walking through door into office)
/// - dr_hope_listening_loop.mp4 (Dr. Hope writing/listening, loops)
/// Audio needed:
/// - dr_hope_speak_truth.mp3 ("Go on, baby. Speak your truth.")
enum JournalPhase {
    case doorEntry        // Walking in video
    case office           // Ready to record
    case recording        // User is recording
    case analyzing        // Dr. Hope listening loop + Analyze button
    case results          // AI feedback shown
}

struct VoiceJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @StateObject private var recorder = VoiceRecorderService()
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @StateObject private var gemini = GeminiService()
    @StateObject private var tts = TextToSpeechService()

    @State private var phase: JournalPhase = .doorEntry
    @State private var selectedMood: Mood?
    @State private var aiResponse: String = ""
    @State private var showMoodSelector = false
    @State private var savedEntry = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .doorEntry:
                doorEntryView

            case .office:
                officeView

            case .recording:
                recordingView

            case .analyzing:
                analyzingView

            case .results:
                resultsView
            }

            // Back button overlay (always visible)
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.leading, 16)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Door Entry (Video)
    private var doorEntryView: some View {
        FullScreenVideoBackground(
            videoName: "journal_door_entry",
            fileExtension: "mp4",
            looping: false,
            onFinished: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    phase = .office
                }
            }
        )
    }

    // MARK: - Office Scene (Ready to Record)
    private var officeView: some View {
        ZStack {
            // Office background
            Image("dr_hope_office_render")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            VStack(spacing: 24) {
                Spacer()

                // Dr. Hope portrait
                Image("dr_hope")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.7, green: 0.4, blue: 0.8), lineWidth: 3)
                    )
                    .shadow(color: Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.5), radius: 10)

                // Quote
                Text("\"Go on, baby. Speak your truth.\nI'm right here listenin'.\"")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .italic()

                Spacer()

                // Record button
                Button(action: startRecording) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }

                Text("Tap to Record")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()
                    .frame(height: 80)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Recording View
    private var recordingView: some View {
        ZStack {
            // Dr. Hope listening image (full screen)
            DrHopeListeningView()
                .ignoresSafeArea()

            // Bottom controls
            VStack {
                // Recording indicator
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text(recorder.formattedDuration)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Waveform + Stop
                VStack(spacing: 16) {
                    WaveformView(levels: recorder.audioLevels, isActive: true, barColor: .white)
                        .frame(height: 30)
                        .padding(.horizontal, 40)

                    Button(action: stopRecording) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                .frame(width: 72, height: 72)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 26, height: 26)
                        }
                    }

                    Text("Tap to stop")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Analyzing View (Dr. Hope Listening Loop + Analyze Button)
    private var analyzingView: some View {
        ZStack {
            // Dr. Hope listening video loops
            FullScreenVideoBackground(
                videoName: "dr_hope_listening_loop",
                fileExtension: "mp4",
                looping: true
            )

            // Dark overlay at bottom
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)
            }
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Status text
                Text("Dr. Hope is reflecting...")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))
                    .italic()
                    .padding(.bottom, 16)

                // Transcription preview (if available)
                if !speechService.transcribedText.isEmpty {
                    Text("\"\(String(speechService.transcribedText.prefix(100)))...\"")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 12)
                }

                // ANALYZE BUTTON
                Button(action: analyzeWithAI) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                        Text("Analyze with Dr. Hope")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 36)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.5, green: 0.25, blue: 0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.5), radius: 12, y: 4)
                    )
                }

                // Skip button
                Button(action: { saveWithoutAnalysis() }) {
                    Text("Save without analysis")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 10)
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Results View (AI Feedback)
    private var resultsView: some View {
        ZStack {
            // Office background
            Image("dr_hope_office_render")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.6).ignoresSafeArea())

            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 60)

                    // Dr. Hope's response
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image("dr_hope")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())

                            Text("Dr. Hope's Reflection")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            // Play voice button
                            Button(action: {
                                tts.speak(aiResponse, as: .drHope)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.7, green: 0.4, blue: 0.8))
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                            }
                        }

                        if gemini.isProcessing {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Thinking...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        } else {
                            Text(aiResponse)
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(5)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Mood selector
                    if showMoodSelector {
                        moodSelectorSection
                    }

                    // Saved confirmation
                    if savedEntry {
                        savedConfirmation
                    }

                    // New entry button
                    if savedEntry {
                        Button(action: resetForNewEntry) {
                            Text("New Journal Entry")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Mood Selector
    private var moodSelectorSection: some View {
        VStack(spacing: 16) {
            Text("How are you feeling now?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    Button(action: { selectedMood = mood }) {
                        VStack(spacing: 4) {
                            Text(mood.emoji).font(.system(size: 26))
                            Text(mood.rawValue).font(.system(size: 9, weight: .medium))
                                .foregroundColor(selectedMood == mood ? .white : .white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedMood == mood ? mood.color.opacity(0.5) : Color.white.opacity(0.05))
                        )
                    }
                }
            }

            if selectedMood != nil {
                Button(action: saveJournalEntry) {
                    Text("Save Entry")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 40)
                        .background(Capsule().fill(SSColors.gradientPrimary))
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
    }

    private var savedConfirmation: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundColor(.green)
            Text("Journal entry saved").font(.system(size: 15)).foregroundColor(.white)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.15)))
    }

    // MARK: - Actions
    private func startRecording() {
        // Play "Go on, speak your truth" audio
        audioPlayer.playVoice(fileName: "dr_hope_speak_truth")

        // Start recording after brief delay (let the audio play first)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            recorder.startRecording()
            speechService.requestAuthorization()
            speechService.startTranscribing()
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .recording
            }
        }
    }

    private func stopRecording() {
        recorder.stopRecording()
        speechService.stopTranscribing()
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .analyzing
        }
    }

    private func analyzeWithAI() {
        let text = speechService.transcribedText.isEmpty
            ? "Voice journal entry - \(recorder.formattedDuration)"
            : speechService.transcribedText

        // Build context from user profile for personalized response
        let context = profile?.aiContext() ?? ""

        Task {
            await gemini.sendMessage(
                """
                \(context)
                
                The user just recorded this journal entry: "\(text)"
                
                You are Dr. Hope analyzing this journal entry. Respond in EXACTLY two paragraphs (3 max):
                
                PARAGRAPH 1 - DIAGNOSIS & OBSERVATION: Identify the core emotional pattern, struggle, or theme you hear in their words. Name it clearly. Reference their specific words. Tell them what you observe about their emotional state — like a real therapist giving an assessment. Be direct and insightful, not vague.
                
                PARAGRAPH 2 - GUIDANCE & ACTION: Give them ONE specific, actionable piece of advice or a reframe that could help. Not generic — tailored to exactly what they said. End with one powerful question that makes them think deeper.
                
                Keep your warm Southern personality but prioritize being USEFUL and INSIGHTFUL over being poetic. Be the therapist, not just the grandmother. MAX 3 short paragraphs total.
                """,
                character: .drHope
            )
            aiResponse = gemini.lastResponse
            showMoodSelector = true

            // Speak the response in Dr. Hope's voice
            tts.speak(aiResponse, as: .drHope)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .results
        }
    }

    private func saveWithoutAnalysis() {
        aiResponse = "Entry saved without analysis. Dr. Hope is proud you showed up today."
        showMoodSelector = true
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .results
        }
    }

    private func saveJournalEntry() {
        guard let mood = selectedMood else { return }

        let transcription = speechService.transcribedText.isEmpty
            ? "Voice journal - \(recorder.formattedDuration)"
            : speechService.transcribedText

        let entry = JournalEntry(
            content: transcription,
            mood: mood.rawValue,
            duration: recorder.recordingDuration,
            drHopeFeedback: aiResponse,
            createdAt: Date()
        )
        modelContext.insert(entry)
        NotificationService.shared.cancelStreakReminder()

        withAnimation { savedEntry = true }
    }

    private func resetForNewEntry() {
        phase = .office
        selectedMood = nil
        aiResponse = ""
        showMoodSelector = false
        savedEntry = false
        speechService.transcribedText = ""
    }
}
