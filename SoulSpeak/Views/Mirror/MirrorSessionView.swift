import SwiftUI

/// Mirror Session View — Individual lesson player for an affliction course.
/// Structured like Omna's therapy-style approach:
/// 1. Daily reflection prompt (look in the mirror)
/// 2. Guided self-inquiry questions
/// 3. Journaling exercise
/// 4. Daily affirmation to internalize
/// 5. Progress checkpoint
///
/// Each session is 5-10 minutes — micro-therapy that builds over days.
struct MirrorSessionView: View {
    let affliction: Affliction
    @Environment(\.dismiss) private var dismiss
    @State private var currentLessonIndex: Int = 0
    @State private var currentStep: SessionStep = .intro
    @State private var journalText: String = ""
    @State private var showAffirmation = false
    @State private var reflectionAnswers: [String] = ["", "", ""]
    @State private var breatheScale: CGFloat = 1.0
    @AppStorage private var completedLessons: Int

    init(affliction: Affliction) {
        self.affliction = affliction
        self._completedLessons = AppStorage(wrappedValue: 0, "mirror_\(affliction.name)_completed")
    }

    enum SessionStep: Int, CaseIterable {
        case intro = 0
        case reflection = 1
        case inquiry = 2
        case journaling = 3
        case affirmation = 4
        case complete = 5

        var title: String {
            switch self {
            case .intro: return "Today's Mirror"
            case .reflection: return "Reflect"
            case .inquiry: return "Go Deeper"
            case .journaling: return "Write It Down"
            case .affirmation: return "Your Truth"
            case .complete: return "Complete"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.08),
                    affliction.color.opacity(0.08),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                sessionHeader

                // Progress dots
                progressIndicator

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .intro:
                            introContent
                        case .reflection:
                            reflectionContent
                        case .inquiry:
                            inquiryContent
                        case .journaling:
                            journalingContent
                        case .affirmation:
                            affirmationContent
                        case .complete:
                            completionContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }

                // Navigation buttons
                navigationButtons
            }
        }
    }

    // MARK: - Header
    private var sessionHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(10)
                .background(Circle().fill(Color.white.opacity(0.08)))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(affliction.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Day \(completedLessons + 1) of \(affliction.lessonCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Lesson counter
            Text("\(currentStep.rawValue + 1)/6")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(SessionStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? affliction.color : Color.white.opacity(0.15))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Step 1: Intro
    private var introContent: some View {
        VStack(spacing: 28) {
            // Mirror icon
            ZStack {
                Circle()
                    .fill(affliction.color.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.crop.circle")
                    .font(.system(size: 50))
                    .foregroundColor(affliction.color.opacity(0.8))
            }
            .padding(.top, 20)

            VStack(spacing: 12) {
                Text("Look in the Mirror")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Text(currentLesson.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(affliction.color)

                Text(affliction.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 8)
            }

            // Today's focus
            VStack(spacing: 8) {
                Text("Today's Focus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1)

                Text(currentLesson.prompts.first ?? "Honest self-reflection")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .italic()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
            )
        }
    }

    // MARK: - Step 2: Reflection
    private var reflectionContent: some View {
        VStack(spacing: 24) {
            Text("Reflect Honestly")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(.white)

            Text("Take a moment to sit with these questions.\nThere are no wrong answers — only honest ones.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // Reflection prompts
            VStack(spacing: 16) {
                ForEach(0..<min(3, currentLesson.prompts.count), id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(affliction.color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            Text(currentLesson.prompts[index])
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        TextField("Your honest answer...", text: $reflectionAnswers[index], axis: .vertical)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(affliction.color.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .lineLimit(3...6)
                    }
                }
            }
        }
    }

    // MARK: - Step 3: Inquiry (Go Deeper)
    private var inquiryContent: some View {
        VStack(spacing: 24) {
            Text("Go Deeper")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(.white)

            // Deep question card
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundColor(affliction.color)

                Text(deepQuestion)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .italic()

                Text("Sit with this question for 60 seconds.\nDon't rush to answer — just feel.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(affliction.color.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(affliction.color.opacity(0.15), lineWidth: 1)
                    )
            )

            // Breathing guide
            VStack(spacing: 12) {
                Text("Breathe")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1)

                Circle()
                    .fill(affliction.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(breatheScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                            breatheScale = 1.4
                        }
                    }

                Text("In... Hold... Out...")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    // MARK: - Step 4: Journaling
    private var journalingContent: some View {
        VStack(spacing: 20) {
            Text("Write It Down")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(.white)

            Text("Writing makes the invisible visible.\nPut your thoughts on paper.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            // Journal prompt
            HStack(spacing: 8) {
                Image(systemName: "pencil.tip")
                    .foregroundColor(affliction.color)
                Text(journalPrompt)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(affliction.color.opacity(0.06))
            )

            // Text editor
            TextEditor(text: $journalText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )

            // Word count
            HStack {
                Spacer()
                Text("\(journalText.split(separator: " ").count) words")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    // MARK: - Step 5: Affirmation
    private var affirmationContent: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)

            Text("Your Truth for Today")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1.5)

            // Affirmation card
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(affliction.color)

                Text(affliction.dailyAffirmation)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text("Say this out loud. Say it again.\nLet it settle into your bones.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [affliction.color.opacity(0.1), affliction.color.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(affliction.color.opacity(0.2), lineWidth: 1)
                    )
            )

            // Repeat button
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                    Text("Hear It Spoken")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(affliction.color)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(affliction.color.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(affliction.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            Spacer(minLength: 20)
        }
    }

    // MARK: - Step 6: Complete
    private var completionContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 30)

            ZStack {
                Circle()
                    .fill(affliction.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(affliction.color)
            }

            Text("Day \(completedLessons + 1) Complete")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)

            Text("You showed up. You looked in the mirror.\nThat takes courage.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Course Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("\(completedLessons + 1)/\(affliction.lessonCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(affliction.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(affliction.color)
                            .frame(width: geo.size.width * CGFloat(completedLessons + 1) / CGFloat(affliction.lessonCount), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            )

            Text("\"No message could have been any clearer.\nIf you wanna make the world a better place,\ntake a look at yourself and make a change.\"")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .italic()
                .lineSpacing(3)
                .padding(.top, 12)

            Spacer(minLength: 30)
        }
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button (not on intro)
            if currentStep != .intro {
                Button(action: previousStep) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(14)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
            }

            Spacer()

            // Next / Complete button
            Button(action: nextStep) {
                HStack(spacing: 8) {
                    Text(currentStep == .complete ? "Finish" : currentStep == .affirmation ? "I Claim This" : "Continue")
                        .font(.system(size: 15, weight: .bold))
                    if currentStep != .complete {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(affliction.color)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.5))
    }

    // MARK: - Navigation
    private func nextStep() {
        if currentStep == .complete {
            completedLessons += 1
            dismiss()
        } else if let nextIndex = SessionStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextIndex
            }
        }
    }

    private func previousStep() {
        if let prevIndex = SessionStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prevIndex
            }
        }
    }

    // MARK: - Lesson Data
    private var currentLesson: MirrorLesson {
        let day = completedLessons + 1
        return MirrorLesson(
            dayNumber: day,
            title: "Day \(day): \(lessonTitles[day % lessonTitles.count])",
            type: .reflection,
            duration: "5-8 min",
            prompts: promptsForDay(day),
            affirmation: affliction.dailyAffirmation,
            isCompleted: false
        )
    }

    private var lessonTitles: [String] {
        ["Awareness", "Recognition", "Understanding", "Acceptance", "Confrontation",
         "Release", "Rebuilding", "Strengthening", "Integration", "Growth",
         "Resilience", "Compassion", "Forgiveness", "Purpose", "Freedom",
         "Truth", "Courage", "Transformation", "Reclamation", "Renewal", "Becoming"]
    }

    private func promptsForDay(_ day: Int) -> [String] {
        let basePrompts: [[String]] = [
            ["When did this pattern first appear in your life?", "What was happening around you at that time?", "How did it make you feel then vs. now?"],
            ["What triggers this behavior or feeling?", "What do you tell yourself to justify it?", "What would your life look like without it?"],
            ["Who benefits when you stay stuck in this?", "What are you avoiding by holding onto this pattern?", "What would you need to believe to let it go?"],
            ["If you could speak to your younger self, what would you say?", "What boundary do you need to set today?", "What small step could you take right now?"],
            ["What would the person you want to become do differently?", "Who in your life has overcome something similar?", "What strength have you already shown in this area?"],
        ]
        return basePrompts[(day - 1) % basePrompts.count]
    }

    private var deepQuestion: String {
        let questions = [
            "What are you really afraid will happen if you change?",
            "Who would you be without this struggle? Does that person scare you?",
            "What comfort does this pattern give you that you're not ready to name?",
            "If this affliction had a voice, what would it say to keep you trapped?",
            "What would you need to grieve in order to move forward?",
            "Are you punishing yourself? For what?",
            "What would unconditional self-acceptance feel like in your body?",
        ]
        return questions[(completedLessons) % questions.count]
    }

    private var journalPrompt: String {
        let prompts = [
            "Write a letter to the version of you that started this pattern...",
            "Describe what freedom from this would feel like in one paragraph...",
            "What is the hardest truth you need to admit to yourself today?",
            "Write down 3 things you're grateful for despite this struggle...",
            "If you woke up tomorrow and this was gone, what would change first?",
        ]
        return prompts[(completedLessons) % prompts.count]
    }
}
