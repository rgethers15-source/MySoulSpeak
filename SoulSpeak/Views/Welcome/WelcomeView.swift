import SwiftUI

/// Welcome Screen: Mr. Hope greets the user as "Champ" and introduces them to Dr. Hope.
/// Features animated Mr. Hope avatar that looks like he's talking, immersive office background.
struct WelcomeView: View {
    @Binding var showWelcome: Bool
    @StateObject private var audioPlayer = AudioPlayerService.shared

    @State private var avatarBreathing = false
    @State private var isTalking = false
    @State private var mouthScale: CGFloat = 1.0
    @State private var headNod: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var backgroundPulse = false
    @State private var jazzPlaying = false

    var body: some View {
        ZStack {
            // Immersive office background
            officeBackground

            VStack(spacing: 0) {
                Spacer()

                // Mr. Hope animated avatar
                mrHopeAvatar
                    .padding(.bottom, 32)

                // Greeting text
                greetingSection
                    .padding(.bottom, 48)

                // Start button
                startButton
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startEntryAnimations()
        }
        .onDisappear {
            audioPlayer.stopAll()
        }
    }

    // MARK: - Office Background
    private var officeBackground: some View {
        ZStack {
            // Try to load the office render image
            Image("mr_hope_office_render")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                )

            // Warm ambient glow
            RadialGradient(
                colors: [
                    Color(red: 0.9, green: 0.75, blue: 0.4).opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .scaleEffect(backgroundPulse ? 1.05 : 1.0)
        }
    }

    // MARK: - Mr. Hope Avatar (Animated Talking)
    private var mrHopeAvatar: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.25))
                .frame(width: 200, height: 200)
                .scaleEffect(avatarBreathing ? 1.12 : 1.0)

            // Middle glow
            Circle()
                .stroke(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.3), lineWidth: 2)
                .frame(width: 180, height: 180)
                .scaleEffect(avatarBreathing ? 1.06 : 0.96)

            // Avatar image
            Image("mr_hope")
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.6, blue: 0.9), Color(red: 0.5, green: 0.8, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.5), radius: 15, y: 5)
                .offset(y: headNod)
                .rotation3DEffect(.degrees(isTalking ? 2 : -1), axis: (x: 0.1, y: 1, z: 0))

            // Talking indicator - sound waves
            if isTalking {
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 4, height: CGFloat.random(in: 8...20) * mouthScale)
                            .animation(
                                .easeInOut(duration: 0.2 + Double(i) * 0.1)
                                    .repeatForever(autoreverses: true),
                                value: mouthScale
                            )
                    }
                }
                .offset(x: 85, y: 10)
            }
        }
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(spacing: 16) {
            Text("Dr. Hope will see you\nshortly, Champ")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            Text("Take a deep breath. You're in good hands.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .opacity(textOpacity)
    }

    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                showWelcome = false
            }
            audioPlayer.stopAll()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                Text("Start Session")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 48)
            .background(
                Capsule()
                    .fill(SSColors.gradientPrimary)
                    .shadow(color: SSColors.primary.opacity(0.5), radius: 12, y: 6)
            )
        }
        .opacity(buttonOpacity)
        .scaleEffect(buttonOpacity > 0 ? 1.0 : 0.8)
    }

    // MARK: - Animations
    private func startEntryAnimations() {
        // Play Mr. Hope greeting audio
        audioPlayer.playVoice(fileName: "mr_hope_greeting")

        // Start jazz background
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            audioPlayer.playBackgroundMusic(fileName: "jazz_loop_1")
            jazzPlaying = true
        }

        // Breathing animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            avatarBreathing = true
        }

        // Background pulse
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            backgroundPulse = true
        }

        // Head nod
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            headNod = -3
        }

        // Start talking animation
        withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
            isTalking = true
            mouthScale = 1.5
        }

        // Show text after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.8)) {
                textOpacity = 1.0
            }
        }

        // Show button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                buttonOpacity = 1.0
            }
        }

        // Stop talking after greeting would finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                isTalking = false
                mouthScale = 1.0
            }
        }
    }
}
