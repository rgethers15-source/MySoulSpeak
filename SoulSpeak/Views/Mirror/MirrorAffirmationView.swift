import SwiftUI

/// Mirror Daily Affirmation View — Beautiful full-screen affirmation display.
/// Can be triggered from notifications or accessed from the Mirror hub.
/// Shows the affirmation for the user's active affliction(s) with
/// gorgeous typography and an option to hear it spoken aloud.
struct MirrorAffirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsService = TextToSpeechService()
    @State private var fadeIn = false
    @State private var currentIndex = 0

    private let affirmations: [(affliction: String, affirmation: String, color: Color)] = [
        ("Procrastination", "I choose action over avoidance. Each step forward counts.", Color(red: 0.9, green: 0.6, blue: 0.2)),
        ("Depression", "The darkness is temporary. I will feel lightness again.", Color(red: 0.4, green: 0.5, blue: 0.8)),
        ("Anxiety", "I release what I cannot control. This moment is enough.", Color(red: 0.6, green: 0.5, blue: 0.9)),
        ("Anger", "My anger is information, not instruction. I choose my response.", Color(red: 0.9, green: 0.35, blue: 0.2)),
        ("Self-Worth", "I am valuable. My existence alone proves my worth.", Color(red: 0.8, green: 0.5, blue: 0.3)),
        ("Childhood Trauma", "The child in me deserves the love they never got. I give it now.", Color(red: 0.6, green: 0.5, blue: 0.8)),
        ("Co-Dependency", "I am whole on my own. My happiness is not someone else's responsibility.", Color(red: 0.7, green: 0.4, blue: 0.5)),
        ("Self-Harm", "My pain is valid. I deserve gentleness, not punishment.", Color(red: 0.6, green: 0.3, blue: 0.5)),
        ("Identity", "I am allowed to rediscover who I am. My truth is mine to find.", Color(red: 0.5, green: 0.7, blue: 0.6)),
        ("Shame", "I am not my mistakes. I am growing and learning.", Color(red: 0.6, green: 0.4, blue: 0.4)),
        ("Loneliness", "I am worthy of connection. My presence matters.", Color(red: 0.5, green: 0.5, blue: 0.7)),
        ("Purpose", "My purpose is unfolding. I trust the process of becoming.", Color(red: 0.4, green: 0.7, blue: 0.5)),
        ("Trust", "I can protect myself AND let love in. Both are possible.", Color(red: 0.5, green: 0.5, blue: 0.6)),
        ("Perfectionism", "Done is better than perfect. I release the need to be flawless.", Color(red: 0.4, green: 0.6, blue: 0.7)),
        ("Sobriety", "I am choosing sobriety. Every clean moment is a victory.", Color(red: 0.5, green: 0.4, blue: 0.7)),
    ]

    private var current: (affliction: String, affirmation: String, color: Color) {
        affirmations[currentIndex % affirmations.count]
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.06),
                    current.color.opacity(0.08),
                    Color(red: 0.03, green: 0.03, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        ttsService.stop()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 56)
                }

                Spacer()

                // Affirmation content
                VStack(spacing: 32) {
                    // Mirror icon
                    ZStack {
                        Circle()
                            .fill(current.color.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [current.color.opacity(0.8), current.color.opacity(0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .opacity(fadeIn ? 1 : 0)

                    // Category label
                    Text(current.affliction.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(current.color.opacity(0.7))
                        .tracking(2)
                        .opacity(fadeIn ? 1 : 0)

                    // The affirmation
                    Text(current.affirmation)
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 30)
                        .opacity(fadeIn ? 1 : 0)
                        .offset(y: fadeIn ? 0 : 20)

                    // Instruction
                    Text("Say it out loud. Mean it.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                        .opacity(fadeIn ? 1 : 0)
                }

                Spacer()

                // Bottom controls
                VStack(spacing: 16) {
                    // Speak button
                    Button(action: speakAffirmation) {
                        HStack(spacing: 10) {
                            Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16))
                            Text(ttsService.isSpeaking ? "Speaking..." : "Hear It")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(current.color.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(current.color.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }

                    // Next affirmation
                    Button(action: nextAffirmation) {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Randomize starting affirmation based on day
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            currentIndex = dayOfYear % affirmations.count

            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                fadeIn = true
            }
        }
        .onDisappear {
            ttsService.stop()
        }
    }

    // MARK: - Actions
    private func speakAffirmation() {
        if ttsService.isSpeaking {
            ttsService.stop()
        } else {
            ttsService.speak(current.affirmation, as: .drHope)
        }
    }

    private func nextAffirmation() {
        ttsService.stop()
        withAnimation(.easeOut(duration: 0.3)) {
            fadeIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            currentIndex = (currentIndex + 1) % affirmations.count
            withAnimation(.easeOut(duration: 0.8)) {
                fadeIn = true
            }
        }
    }
}
