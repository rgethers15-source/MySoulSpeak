import SwiftUI

/// TutorialView — Interactive walkthrough for any section of the app.
/// Shows animated step-by-step screens explaining how to use each feature.
/// Auto-plays first time user opens a section, and available in Settings to rewatch.
struct TutorialView: View {
    let tutorial: TutorialType
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var fadeIn = false
    @State private var iconScale: CGFloat = 0.8
    @State private var slideOffset: CGFloat = 50

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.08),
                    tutorial.steps[currentStep].color.opacity(0.1),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Text("Skip")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }

                Spacer()

                // Step content
                stepContent
                    .opacity(fadeIn ? 1 : 0)
                    .offset(y: fadeIn ? 0 : slideOffset)

                Spacer()

                // Progress dots + navigation
                bottomNavigation
            }
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Step Content
    private var stepContent: some View {
        let step = tutorial.steps[currentStep]

        return VStack(spacing: 28) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(iconScale)

                Image(systemName: step.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [step.color, step.color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(iconScale)
            }

            // Step number
            Text("Step \(currentStep + 1) of \(tutorial.steps.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1.5)

            // Title
            Text(step.title)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Description
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 30)

            // Tip (if available)
            if let tip = step.tip {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text(tip)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.08))
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        VStack(spacing: 20) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<tutorial.steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? tutorial.steps[currentStep].color : Color.white.opacity(0.2))
                        .frame(width: index == currentStep ? 10 : 6, height: index == currentStep ? 10 : 6)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }

            // Next / Get Started button
            Button(action: nextStep) {
                HStack(spacing: 8) {
                    Text(currentStep == tutorial.steps.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 16, weight: .bold))
                    if currentStep < tutorial.steps.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tutorial.steps[currentStep].color)
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Navigation
    private func nextStep() {
        if currentStep < tutorial.steps.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) {
                fadeIn = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentStep += 1
                animateIn()
            }
        } else {
            onComplete()
        }
    }

    private func animateIn() {
        fadeIn = false
        iconScale = 0.8
        slideOffset = 50

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            fadeIn = true
            iconScale = 1.0
            slideOffset = 0
        }
    }
}

// MARK: - Tutorial Step Model
struct TutorialStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let tip: String?

    init(icon: String, title: String, description: String, color: Color, tip: String? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.tip = tip
    }
}

// MARK: - Tutorial Types (one for each app section)
enum TutorialType {
    case journal
    case talk
    case vent
    case centered
    case mirror
    case mood
    case accountability
    case prescriptions

    var title: String {
        switch self {
        case .journal: return "Voice Journal"
        case .talk: return "Talk"
        case .vent: return "Vent Room"
        case .centered: return "Centered"
        case .mirror: return "The Mirror"
        case .mood: return "Mood Tracker"
        case .accountability: return "Accountability"
        case .prescriptions: return "Prescriptions"
        }
    }

    var steps: [TutorialStep] {
        switch self {
        case .journal:
            return [
                TutorialStep(icon: "mic.fill", title: "Speak Your Truth", description: "Record a voice journal entry. Just talk — Dr. Hope is listening. Say whatever is on your mind without filter.", color: Color(red: 0.8, green: 0.4, blue: 0.9)),
                TutorialStep(icon: "waveform", title: "Watch It Come Out", description: "As you speak, your words are transcribed in real-time. The waveform shows your voice — proof that you're letting it out.", color: Color(red: 0.7, green: 0.4, blue: 0.8)),
                TutorialStep(icon: "brain.head.profile", title: "Dr. Hope Responds", description: "After you finish, Dr. Hope analyzes your entry and gives you a real therapeutic response. She identifies patterns and gives actionable guidance.", color: Color(red: 0.6, green: 0.4, blue: 0.9), tip: "The more you journal, the more Dr. Hope understands you."),
                TutorialStep(icon: "face.smiling.fill", title: "Track Your Mood", description: "After each entry, select how you're feeling. Over time, this builds your emotional map — so you can see your progress.", color: Color(red: 0.9, green: 0.7, blue: 0.2)),
            ]

        case .talk:
            return [
                TutorialStep(icon: "bubble.left.and.bubble.right.fill", title: "Choose Your Companion", description: "Pick Dr. Hope (wise, warm therapist) or Mr. Hope (motivational mentor). Each has their own personality and approach.", color: Color(red: 0.3, green: 0.6, blue: 1.0)),
                TutorialStep(icon: "keyboard", title: "Type or Speak", description: "Type your message or tap the microphone to speak. Ask ANYTHING — they're as smart as any AI assistant but with soul.", color: Color(red: 0.4, green: 0.6, blue: 0.9)),
                TutorialStep(icon: "speaker.wave.2.fill", title: "Hear Their Voice", description: "They respond in their actual voice — not a robot. Real, cloned voices that feel like talking to a real person.", color: Color(red: 0.5, green: 0.4, blue: 0.9), tip: "Tap 'Listen' on any message to hear it spoken aloud."),
                TutorialStep(icon: "brain", title: "They Remember You", description: "The more you talk, the better they understand you. They reference your previous conversations and learn your patterns.", color: Color(red: 0.3, green: 0.7, blue: 0.8)),
            ]

        case .vent:
            return [
                TutorialStep(icon: "flame.fill", title: "Let It Out", description: "The Vent Room is your safe space to release frustration. Record your anger, your pain, your rage — then watch it burn.", color: Color(red: 1.0, green: 0.4, blue: 0.15)),
                TutorialStep(icon: "mic.circle.fill", title: "Record Your Vent", description: "Speak everything that's bothering you. Don't hold back. This is for YOU. Nobody else will hear it.", color: Color(red: 0.9, green: 0.3, blue: 0.2)),
                TutorialStep(icon: "flame.circle.fill", title: "Watch It Burn", description: "Your words transform into paper that burns to ash in a cinematic fireplace scene. Symbolic release.", color: Color(red: 0.95, green: 0.5, blue: 0.1)),
                TutorialStep(icon: "hammer.fill", title: "Destroy the Room", description: "Smash, throw, and destroy objects in a 3D rage room. Use the sledgehammer, bat, fists, or throw plates. Feel the impact.", color: Color(red: 0.8, green: 0.3, blue: 0.2), tip: "Swipe harder for bigger impacts. Build combos for slow-motion hits!"),
                TutorialStep(icon: "leaf.fill", title: "Release & Reset", description: "After the destruction, breathe. The Release phase brings you back to calm with healing visuals and a reset.", color: Color(red: 0.3, green: 0.8, blue: 0.5)),
            ]

        case .centered:
            return [
                TutorialStep(icon: "leaf.circle.fill", title: "Find Your Center", description: "This is your peaceful space. Listen to guided meditations, pep talks, healing sessions, or relaxing music.", color: Color(red: 0.3, green: 0.85, blue: 0.5)),
                TutorialStep(icon: "music.note.list", title: "Choose a Category", description: "Music (ambient/lofi), Meditations, Pep Talks, Healing, or Closings. Each has curated audio from Dr. Hope and Mr. Hope.", color: Color(red: 0.4, green: 0.7, blue: 0.9)),
                TutorialStep(icon: "play.circle.fill", title: "Tap to Play", description: "Tap any track to start playing. The red STOP button at the bottom will immediately stop all audio.", color: Color(red: 0.5, green: 0.8, blue: 0.6), tip: "Music loops continuously. Meditations play once."),
            ]

        case .mirror:
            return [
                TutorialStep(icon: "person.crop.circle", title: "Look in the Mirror", description: "The Mirror is for confronting your struggles honestly. Choose your affliction and work through a structured course — one day at a time.", color: Color(red: 0.85, green: 0.75, blue: 1.0)),
                TutorialStep(icon: "list.bullet", title: "Choose Your Affliction", description: "23 courses across 4 categories: Behavioral, Emotional, Relational, and Identity. From procrastination to childhood trauma.", color: Color(red: 0.7, green: 0.5, blue: 0.9)),
                TutorialStep(icon: "pencil.and.scribble", title: "Daily Sessions", description: "Each day has 6 steps: Reflection, Deep Inquiry, Journaling, Affirmation, and Completion. 5-10 minutes that build over time.", color: Color(red: 0.6, green: 0.4, blue: 0.8), tip: "Consistency is key. Show up every day — even for 5 minutes."),
                TutorialStep(icon: "chart.line.uptrend.xyaxis", title: "Track Your Growth", description: "See your streaks, completion percentages, and weekly progress. Watch yourself transform over weeks and months.", color: Color(red: 0.4, green: 0.8, blue: 0.6)),
            ]

        case .mood:
            return [
                TutorialStep(icon: "face.smiling.fill", title: "How Are You Feeling?", description: "Log your mood anytime. Choose from 8 emotional states: Joyful, Peaceful, Grateful, Anxious, Sad, Angry, Hopeful, or Tired.", color: Color(red: 1.0, green: 0.75, blue: 0.2)),
                TutorialStep(icon: "slider.horizontal.3", title: "Rate the Intensity", description: "How strong is the feeling? Rate from 1-10. This helps track whether your emotions are getting more manageable over time.", color: Color(red: 0.9, green: 0.6, blue: 0.3)),
                TutorialStep(icon: "chart.bar.fill", title: "See Your Patterns", description: "The Analytics section shows your mood trends, most frequent emotions, and whether things are improving, steady, or declining.", color: Color(red: 0.4, green: 0.7, blue: 0.9), tip: "Log daily for the best insights. Even a quick tap counts."),
            ]

        case .accountability:
            return [
                TutorialStep(icon: "calendar.badge.clock", title: "Your Life, Organized", description: "The Accountability Calendar helps you schedule and KEEP commitments. Calvin — your AI coach — makes sure you follow through.", color: Color(red: 0.3, green: 0.7, blue: 0.9)),
                TutorialStep(icon: "plus.circle.fill", title: "Add Events", description: "Tap + to add appointments, tasks, workouts, therapy sessions — anything. Set category, priority, and reminders.", color: Color(red: 0.4, green: 0.8, blue: 0.5)),
                TutorialStep(icon: "person.crop.circle.badge.checkmark", title: "Meet Calvin", description: "Tap Calvin's picture to chat with him. He can schedule events for you, check your progress, or give you a push when you need it.", color: Color(red: 0.2, green: 0.5, blue: 0.8), tip: "Ask Calvin: 'Schedule a workout for tomorrow at 7am'"),
                TutorialStep(icon: "xmark.circle", title: "No Free Cancellations", description: "If you try to cancel, Calvin plays a video and requires you to TYPE why. No excuses without accountability. This builds discipline.", color: Color(red: 0.9, green: 0.4, blue: 0.3)),
                TutorialStep(icon: "flame.fill", title: "Build Your Streak", description: "Every completed event adds to your streak. Calvin celebrates your wins and tracks your consistency over time.", color: Color(red: 0.9, green: 0.6, blue: 0.2)),
            ]

        case .prescriptions:
            return [
                TutorialStep(icon: "pill.fill", title: "Manage Your Medications", description: "Track all your prescriptions in one place. Taylor Hope — your AI pharmacist — helps you understand and manage everything.", color: Color(red: 0.4, green: 0.8, blue: 0.6)),
                TutorialStep(icon: "plus.circle.fill", title: "Add Medications", description: "Enter your medication name, dosage, form (tablet/capsule/etc.), and how often you take it. Set up the pill count.", color: Color(red: 0.3, green: 0.7, blue: 0.5)),
                TutorialStep(icon: "checkmark.circle.fill", title: "Tap to Take", description: "Each day, tap the circle next to your medication to mark it as taken. Watch your adherence streak grow.", color: Color(red: 0.4, green: 0.9, blue: 0.5), tip: "Taylor will remind you if you forget."),
                TutorialStep(icon: "exclamationmark.triangle.fill", title: "Refill Alerts", description: "When your pill count gets low, you'll see a refill warning. The app shows how many days you have left and your pharmacy's phone number.", color: Color(red: 0.9, green: 0.6, blue: 0.2)),
                TutorialStep(icon: "stethoscope.circle.fill", title: "Ask Taylor Anything", description: "Tap Taylor's icon to ask about ANY medication — side effects, interactions, what happens if you miss a dose, history, everything.", color: Color(red: 0.6, green: 0.4, blue: 0.8), tip: "Taylor explains complex medical info in simple terms."),
            ]
        }
    }
}
