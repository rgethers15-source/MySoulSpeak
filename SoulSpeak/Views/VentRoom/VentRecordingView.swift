import SwiftUI
import UIKit

// MARK: - Dust Particle
private struct DustParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
}

/// Elite Vent Recording View - Atmospheric, moody recording experience with floating dust,
/// dramatic waveform visualization, heartbeat pulse, audio-reactive background,
/// motivational micro-text, and magnetic recording button.
struct VentRecordingView: View {
    @ObservedObject var recorder: VoiceRecorderService
    let onFinished: () -> Void

    // Animation states
    @State private var pulsePhase: CGFloat = 0
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var heartbeatPhase = 0
    @State private var backgroundPulse: Double = 0
    @State private var dustParticles: [DustParticle] = []
    @State private var dustPhase: CGFloat = 0

    // Waveform gradient shift
    @State private var recordingElapsed: TimeInterval = 0
    @State private var elapsedTimer: Timer?

    // Motivational text
    @State private var motivationalText: String = ""
    @State private var motivationalOpacity: Double = 0
    @State private var motivationalIndex = 0
    private let motivationalMessages = [
        "Let it out...",
        "It is safe here...",
        "Release the weight...",
        "No one is judging...",
        "This is YOUR space...",
        "Speak your truth..."
    ]

    // Button states
    @State private var buttonMagneticScale: CGFloat = 1.0
    @State private var captureFlash: Double = 0
    @State private var timerGlow: CGFloat = 0

    // Intro
    @State private var viewAppeared = false

    var body: some View {
        ZStack {
            // Audio-reactive dark moody background
            audioReactiveBackground

            // Floating dust particles
            dustParticleLayer

            // Main content
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                // Room ambience icon
                ventIcon

                Spacer().frame(height: 24)

                // Title
                titleSection

                Spacer().frame(height: 20)

                // Motivational micro-text
                motivationalSection

                Spacer().frame(height: 32)

                // Waveform visualization (larger, dramatic)
                if recorder.isRecording {
                    dramaticWaveform
                }

                Spacer().frame(height: 20)

                // Timer with glowing red outline
                if recorder.isRecording {
                    timerView
                }

                Spacer()

                // Recording button with magnetic pull
                recordButton

                Spacer().frame(height: 16)

                Text(recorder.isRecording ? "Tap to finish" : "Tap to vent")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Spacer().frame(height: 60)
            }

            // Capture flash overlay
            if captureFlash > 0 {
                Color.white.opacity(captureFlash)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            setupDustParticles()
            startDustAnimation()
            startHeartbeat()
            withAnimation(.easeIn(duration: 0.8)) {
                viewAppeared = true
            }
        }
        .onDisappear {
            elapsedTimer?.invalidate()
        }
        .onChange(of: recorder.isRecording) { _, isRecording in
            if isRecording {
                startRecordingEffects()
            }
        }
    }

    // MARK: - Audio Reactive Background
    private var audioReactiveBackground: some View {
        let avgLevel = recorder.audioLevels.isEmpty ? 0.0 : Double(recorder.audioLevels.reduce(0, +)) / Double(max(1, recorder.audioLevels.count))

        return ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08 + backgroundPulse * 0.04, green: 0.04, blue: 0.04),
                    Color(red: 0.12 + backgroundPulse * 0.06, green: 0.05, blue: 0.05 + backgroundPulse * 0.02),
                    Color(red: 0.06, green: 0.03, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Pulse with audio levels
            RadialGradient(
                colors: [
                    Color.red.opacity(0.08 * avgLevel),
                    Color(red: 0.4, green: 0.1, blue: 0.1).opacity(0.05 * avgLevel),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.1), value: recorder.audioLevels)

            // Warm fireplace glow at bottom
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        Color(red: 0.8, green: 0.3, blue: 0.1).opacity(0.12 + backgroundPulse * 0.05),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 20,
                    endRadius: 200
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Dust Particle Layer
    private var dustParticleLayer: some View {
        ForEach(dustParticles) { particle in
            Circle()
                .fill(Color.white.opacity(particle.opacity))
                .frame(width: particle.size, height: particle.size)
                .position(
                    x: particle.x + sin(dustPhase * CGFloat(particle.speed) + particle.y * 0.01) * 20,
                    y: particle.y + cos(dustPhase * CGFloat(particle.speed) * 0.7) * 15
                )
                .blur(radius: particle.size > 3 ? 1 : 0)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Vent Icon
    private var ventIcon: some View {
        ZStack {
            // Glow behind icon
            Circle()
                .fill(Color(red: 0.9, green: 0.3, blue: 0.1).opacity(0.15))
                .frame(width: 80, height: 80)
                .blur(radius: 20)

            Image(systemName: "flame.fill")
                .font(.system(size: 38))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.5, blue: 0.1), Color(red: 0.85, green: 0.25, blue: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(viewAppeared ? 1 : 0)
                .scaleEffect(viewAppeared ? 1 : 0.5)
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(recorder.isRecording ? "Let it out..." : "Ready to vent?")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .animation(.easeInOut(duration: 0.3), value: recorder.isRecording)

            Text(recorder.isRecording
                 ? "Say whatever you need to say.\nNo one will hear this but you."
                 : "Tap the button to start recording.\nThis is YOUR space.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Motivational Section
    private var motivationalSection: some View {
        Group {
            if recorder.isRecording {
                Text(motivationalText)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.3).opacity(0.7))
                    .opacity(motivationalOpacity)
                    .frame(height: 20)
            } else {
                Spacer().frame(height: 20)
            }
        }
    }

    // MARK: - Dramatic Waveform
    private var dramaticWaveform: some View {
        let gradientProgress = min(1.0, recordingElapsed / 30.0) // Shifts over 30 seconds

        return VStack(spacing: 0) {
            HStack(spacing: 3) {
                ForEach(Array(recorder.audioLevels.enumerated()), id: \.offset) { index, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: waveformColors(progress: gradientProgress, level: level),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(
                            width: 5,
                            height: max(6, level * 80)
                        )
                        .animation(.easeInOut(duration: 0.07), value: level)
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 30)

            // Waveform glow beneath
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.9 * gradientProgress + 0.2, green: 0.3 * (1 - gradientProgress), blue: 0.8 * (1 - gradientProgress)).opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 20)
                .blur(radius: 8)
                .padding(.horizontal, 30)
        }
    }

    // MARK: - Timer View
    private var timerView: some View {
        Text(recorder.formattedDuration)
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(.red.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.4 + Double(timerGlow) * 0.4), lineWidth: 2)
                    .shadow(color: Color.red.opacity(0.3), radius: 6)
            )
            .shadow(color: Color.red.opacity(0.2), radius: 10)
    }

    // MARK: - Record Button
    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                // Outer magnetic glow ring
                if !recorder.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.15), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(buttonMagneticScale)
                }

                // Heartbeat pulse rings when recording
                if recorder.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 95, height: 95)
                        .scaleEffect(heartbeatScale)
                        .opacity(Double(2.0 - heartbeatScale))

                    Circle()
                        .stroke(Color.red.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 95, height: 95)
                        .scaleEffect(heartbeatScale * 1.1)
                        .opacity(Double(2.0 - heartbeatScale * 1.1) * 0.5)
                }

                // Main button ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 82, height: 82)

                // Inner shape
                if recorder.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.red, Color(red: 0.7, green: 0.1, blue: 0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: Color.red.opacity(0.5), radius: 8)
                } else {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.red, Color(red: 0.7, green: 0.05, blue: 0.05)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.red.opacity(0.4), radius: 10)
                }
            }
        }
        .scaleEffect(buttonMagneticScale)
        .onAppear {
            // Magnetic pull animation for non-recording state
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                buttonMagneticScale = 1.05
            }
        }
    }

    // MARK: - Waveform Color Calculation
    private func waveformColors(progress: Double, level: CGFloat) -> [Color] {
        // Shifts from cool blue to hot red over time
        let r = 0.3 + progress * 0.6
        let g = 0.4 * (1 - progress) + Double(level) * 0.2
        let b = 0.8 * (1 - progress)
        return [
            Color(red: r * 0.7, green: g * 0.5, blue: b),
            Color(red: r, green: g, blue: b * 0.5),
            Color(red: min(1, r + 0.2), green: g * 0.3, blue: 0)
        ]
    }

    // MARK: - Actions
    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
            triggerCaptureEffect()
            // Delay to let flash play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onFinished()
            }
        } else {
            recorder.startRecording()
        }
    }

    private func startRecordingEffects() {
        recordingElapsed = 0
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                recordingElapsed += 0.5
            }
        }

        // Start motivational text cycle
        cycleMotivationalText()

        // Timer glow
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            timerGlow = 1.0
        }

        // Background pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            backgroundPulse = 1.0
        }
    }

    private func cycleMotivationalText() {
        guard recorder.isRecording else { return }

        motivationalText = motivationalMessages[motivationalIndex % motivationalMessages.count]
        withAnimation(.easeIn(duration: 0.8)) {
            motivationalOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                self.motivationalOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.motivationalIndex += 1
            self.cycleMotivationalText()
        }
    }

    private func triggerCaptureEffect() {
        // Flash
        captureFlash = 0.6
        withAnimation(.easeOut(duration: 0.35)) {
            captureFlash = 0
        }

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    // MARK: - Dust Setup
    private func setupDustParticles() {
        let bounds = UIScreen.main.bounds
        dustParticles = (0..<25).map { _ in
            DustParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 1.5...4),
                opacity: Double.random(in: 0.08...0.25),
                speed: Double.random(in: 0.3...1.0)
            )
        }
    }

    private func startDustAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            dustPhase = .pi * 2
        }
    }

    private func startHeartbeat() {
        // Double-pulse heartbeat rhythm
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            guard recorder.isRecording else { return }
            DispatchQueue.main.async {
                // First beat
                withAnimation(.easeOut(duration: 0.15)) {
                    heartbeatScale = 1.25
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        heartbeatScale = 1.0
                    }
                }
                // Second beat (slightly delayed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.12)) {
                        heartbeatScale = 1.18
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                        withAnimation(.easeIn(duration: 0.2)) {
                            heartbeatScale = 1.0
                        }
                    }
                }
            }
        }
    }
}
