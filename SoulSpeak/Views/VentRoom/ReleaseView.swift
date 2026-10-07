import SwiftUI
import UIKit

// MARK: - Healing Orb Model
private struct HealingOrb: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var hue: Double // 0 = gold, 1 = green
    var speed: Double
    var phase: CGFloat
}

/// Elite Release View - The cathartic conclusion. Opens with dramatic white light breath,
/// features golden/green healing orbs, breathing circle guide, typewriter text reveal,
/// aurora color waves, success haptic sequence, floating released text, and glowing buttons.
struct ReleaseView: View {
    let onComplete: () -> Void
    let onExit: () -> Void

    // White light intro
    @State private var whiteBreath: Double = 1.0
    @State private var sceneRevealed = false

    // Healing particles
    @State private var healingOrbs: [HealingOrb] = []
    @State private var orbPhase: CGFloat = 0

    // Breathing circle
    @State private var breathingScale: CGFloat = 0.6
    @State private var breathingOpacity: Double = 0.6
    @State private var breathingText: String = "Breathe in..."

    // Typewriter text
    @State private var revealedText: String = ""
    @State private var fullText: String = "Released."
    @State private var typewriterIndex = 0
    @State private var typewriterTimer: Timer?

    // Sub-text
    @State private var subTextOpacity: Double = 0
    @State private var subText: String = "The room is restored. Your spirit is lighter."

    // Aurora
    @State private var auroraPhase: CGFloat = 0
    @State private var auroraColors: [Color] = [
        Color(red: 0.2, green: 0.6, blue: 0.4),
        Color(red: 0.3, green: 0.7, blue: 0.5),
        Color(red: 0.5, green: 0.8, blue: 0.3),
        Color(red: 0.6, green: 0.75, blue: 0.4)
    ]

    // Float/bob animation
    @State private var releasedFloat: CGFloat = 0

    // Buttons
    @State private var buttonsRevealed = false
    @State private var buttonGlow: Double = 0

    // Leaf icon
    @State private var leafScale: CGFloat = 0.3
    @State private var leafRotation: Double = -10
    @State private var leafGlow: Double = 0

    var body: some View {
        ZStack {
            // Aurora background
            auroraBackground

            // Healing orbs
            healingOrbLayer

            // Central content
            VStack(spacing: 0) {
                Spacer()

                // Breathing circle
                breathingCircle
                    .opacity(sceneRevealed ? 1 : 0)

                Spacer().frame(height: 30)

                // Leaf icon
                leafIcon
                    .opacity(sceneRevealed ? 1 : 0)

                Spacer().frame(height: 20)

                // Typewriter "Released." text with float
                Text(revealedText)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.4), radius: 10)
                    .offset(y: releasedFloat)
                    .opacity(sceneRevealed ? 1 : 0)

                Spacer().frame(height: 14)

                // Sub text
                Text(subText)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .opacity(subTextOpacity)
                    .padding(.horizontal, 40)

                Spacer()

                // Action buttons with glow
                if buttonsRevealed {
                    actionButtons
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 60)
            }

            // White light breath overlay (fades out to reveal scene)
            Color.white
                .opacity(whiteBreath)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            performEntrance()
        }
        .onDisappear {
            typewriterTimer?.invalidate()
        }
    }

    // MARK: - Aurora Background
    private var auroraBackground: some View {
        ZStack {
            // Deep peaceful base
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.15, blue: 0.12),
                    Color(red: 0.04, green: 0.12, blue: 0.1),
                    Color(red: 0.03, green: 0.08, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Aurora wave 1
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.12),
                            Color(red: 0.4, green: 0.8, blue: 0.3).opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 500, height: 200)
                .rotationEffect(.degrees(Double(auroraPhase) * 5))
                .offset(x: sin(auroraPhase) * 50, y: -150 + cos(auroraPhase * 0.7) * 30)
                .blur(radius: 30)

            // Aurora wave 2
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.5, green: 0.8, blue: 0.4).opacity(0.08),
                            Color(red: 0.3, green: 0.6, blue: 0.5).opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: 400, height: 180)
                .rotationEffect(.degrees(-Double(auroraPhase) * 3))
                .offset(x: cos(auroraPhase * 1.3) * 40, y: -80 + sin(auroraPhase * 0.5) * 40)
                .blur(radius: 25)

            // Aurora wave 3 (golden)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.8, green: 0.7, blue: 0.3).opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 150)
                .offset(x: sin(auroraPhase * 0.8) * 60, y: cos(auroraPhase) * 50)
                .blur(radius: 20)

            // Central peace glow
            RadialGradient(
                colors: [
                    Color(red: 0.3, green: 0.75, blue: 0.5).opacity(sceneRevealed ? 0.15 : 0),
                    Color.clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 250
            )
        }
    }

    // MARK: - Healing Orb Layer
    private var healingOrbLayer: some View {
        ForEach(healingOrbs) { orb in
            ZStack {
                // Soft glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                orbColor(hue: orb.hue).opacity(0.6),
                                orbColor(hue: orb.hue).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: orb.size
                        )
                    )
                    .frame(width: orb.size * 2.5, height: orb.size * 2.5)
                    .blur(radius: orb.size * 0.4)

                // Core
                Circle()
                    .fill(orbColor(hue: orb.hue).opacity(0.8))
                    .frame(width: orb.size, height: orb.size)
            }
            .opacity(orb.opacity)
            .position(
                x: orb.x + sin(orbPhase * CGFloat(orb.speed) + orb.phase) * 30,
                y: orb.y + cos(orbPhase * CGFloat(orb.speed) * 0.7 + orb.phase) * 25
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Breathing Circle
    private var breathingCircle: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.5),
                            Color(red: 0.5, green: 0.9, blue: 0.4).opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: 100, height: 100)
                .scaleEffect(breathingScale)
                .opacity(breathingOpacity)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(breathingScale)

            // Breathing guide text
            Text(breathingText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.6))
        }
    }

    // MARK: - Leaf Icon
    private var leafIcon: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color(red: 0.3, green: 0.8, blue: 0.5).opacity(leafGlow * 0.3))
                .frame(width: 80, height: 80)
                .blur(radius: 20)

            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.85, blue: 0.5),
                            Color(red: 0.25, green: 0.7, blue: 0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(leafScale)
                .rotationEffect(.degrees(leafRotation))
                .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.4), radius: 10)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Vent Again button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                onComplete()
            }) {
                Text("Vent Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2 + buttonGlow * 0.15), lineWidth: 1)
                            )
                            .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.5).opacity(buttonGlow * 0.2), radius: 8)
                    )
            }
            .scaleEffect(1.0)
            .buttonStyle(SpringButtonStyle())

            // Leave Room button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onExit()
            }) {
                Text("I am done - leave room")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.25, green: 0.65, blue: 0.45),
                                        Color(red: 0.18, green: 0.55, blue: 0.38)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(red: 0.3, green: 0.7, blue: 0.5).opacity(buttonGlow * 0.4), radius: 12)
                    )
            }
            .buttonStyle(SpringButtonStyle())
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Orb Color Helper
    private func orbColor(hue: Double) -> Color {
        if hue < 0.5 {
            // Gold
            return Color(red: 0.85 + hue * 0.1, green: 0.7, blue: 0.2 + hue * 0.2)
        } else {
            // Green
            return Color(red: 0.2 + (1 - hue) * 0.2, green: 0.7 + hue * 0.1, blue: 0.4)
        }
    }

    // MARK: - Entrance Sequence
    private func performEntrance() {
        // Trigger success haptic sequence
        triggerSuccessHaptics()

        // White breath fades to reveal scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.8)) {
                whiteBreath = 0
            }
        }

        // Scene elements appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                sceneRevealed = true
                leafScale = 1.0
                leafRotation = 0
            }
        }

        // Start aurora animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 12.0).repeatForever(autoreverses: false)) {
                auroraPhase = .pi * 2
            }
        }

        // Setup healing orbs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            setupHealingOrbs()
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                orbPhase = .pi * 2
            }
        }

        // Start breathing circle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            startBreathingCycle()
        }

        // Typewriter text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            startTypewriter()
        }

        // Sub text fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                subTextOpacity = 1.0
            }
        }

        // Float/bob animation for released text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                releasedFloat = -5
            }
        }

        // Leaf glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                leafGlow = 1.0
            }
        }

        // Reveal buttons
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                buttonsRevealed = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                buttonGlow = 1.0
            }
        }
    }

    // MARK: - Typewriter Effect
    private func startTypewriter() {
        typewriterIndex = 0
        revealedText = ""
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { timer in
            DispatchQueue.main.async {
                if typewriterIndex < fullText.count {
                    let index = fullText.index(fullText.startIndex, offsetBy: typewriterIndex)
                    revealedText += String(fullText[index])
                    typewriterIndex += 1

                    // Soft haptic per character
                    if typewriterIndex % 2 == 0 {
                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred(intensity: 0.3)
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    // MARK: - Breathing Cycle
    private func startBreathingCycle() {
        breatheIn()
    }

    private func breatheIn() {
        breathingText = "Breathe in..."
        withAnimation(.easeInOut(duration: 3.0)) {
            breathingScale = 1.2
            breathingOpacity = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            breatheOut()
        }
    }

    private func breatheOut() {
        breathingText = "Breathe out..."
        withAnimation(.easeInOut(duration: 3.5)) {
            breathingScale = 0.6
            breathingOpacity = 0.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            breatheIn()
        }
    }

    // MARK: - Healing Orbs Setup
    private func setupHealingOrbs() {
        let bounds = UIScreen.main.bounds
        healingOrbs = (0..<18).map { _ in
            HealingOrb(
                x: CGFloat.random(in: 30...(bounds.width - 30)),
                y: CGFloat.random(in: 100...(bounds.height - 100)),
                size: CGFloat.random(in: 5...14),
                opacity: Double.random(in: 0.3...0.7),
                hue: Double.random(in: 0...1),
                speed: Double.random(in: 0.4...1.2),
                phase: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }

    // MARK: - Haptics
    private func triggerSuccessHaptics() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Soft sequence
        let soft = UIImpactFeedbackGenerator(style: .soft)
        let delays: [Double] = [0.3, 0.5, 0.7, 0.9]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                soft.impactOccurred(intensity: 0.4)
            }
        }

        // Final gentle confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.impactOccurred(intensity: 0.6)
        }
    }
}

// MARK: - Spring Button Style
private struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
