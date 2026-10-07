import SwiftUI
import UIKit

// MARK: - Ash Particle Model
private struct AshParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var rotation: Double
    var driftX: CGFloat
}

// MARK: - Ember Particle Model
private struct EmberParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
}

/// Elite Paper Burn View - Recording transforms into paper, user drags it into a volumetric fireplace.
/// Features: multi-axis paper rotation, progressive fire spread from bottom edge, paper curling,
/// ash particles floating upward, ember scatter, volumetric layered fire, heat distortion,
/// room illumination that grows with the fire, and haptic crackle on ignition.
struct PaperBurnView: View {
    let onFinished: () -> Void

    // Paper state
    @State private var paperOffset: CGSize = .zero
    @State private var paperRotationX: Double = 0
    @State private var paperRotationY: Double = 0
    @State private var paperRotationZ: Double = 0
    @State private var paperScale: CGFloat = 1.0
    @State private var paperOpacity: Double = 1.0
    @State private var paperPlaced = false

    // Burn progression
    @State private var burnProgress: CGFloat = 0 // 0 to 1
    @State private var burning = false
    @State private var ignited = false

    // Fire state
    @State private var fireIntensity: CGFloat = 0
    @State private var flamePhase: CGFloat = 0
    @State private var flameTipPhase: CGFloat = 0

    // Room illumination
    @State private var roomWarmth: Double = 0

    // Particles
    @State private var ashParticles: [AshParticle] = []
    @State private var emberParticles: [EmberParticle] = []

    // UI state
    @State private var showInstruction = true
    @State private var instructionOpacity: Double = 1.0
    @State private var heatDistortion: CGFloat = 1.0

    // Timers
    @State private var burnTimer: Timer?
    @State private var particleTimer: Timer?

    var body: some View {
        ZStack {
            // Dynamic room background that warms as fire grows
            roomBackground

            // Heat distortion zone above fireplace
            if burning {
                heatDistortionLayer
            }

            // Volumetric fireplace at bottom
            VStack {
                Spacer()
                eliteFireplaceView
            }
            .ignoresSafeArea(edges: .bottom)

            // Ash particles floating upward
            ForEach(ashParticles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }

            // Ember particles scattering
            ForEach(emberParticles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow, Color.orange, Color.red.opacity(0.5)],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
                    .blur(radius: 0.5)
            }

            // The draggable paper
            if !paperPlaced {
                paperView
                    .offset(paperOffset)
                    .rotation3DEffect(
                        .degrees(paperRotationX),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.3
                    )
                    .rotation3DEffect(
                        .degrees(paperRotationY),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.3
                    )
                    .rotationEffect(.degrees(paperRotationZ))
                    .scaleEffect(paperScale)
                    .opacity(paperOpacity)
                    .gesture(paperDragGesture)
            }

            // Burning paper overlay (paper that is catching fire in place)
            if paperPlaced && burnProgress < 1.0 {
                burningPaperView
            }

            // Instruction overlay
            if showInstruction {
                instructionOverlay
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                fireIntensity = 0.15
            }
            startFlameAnimation()
        }
        .onDisappear {
            burnTimer?.invalidate()
            particleTimer?.invalidate()
        }
    }

    // MARK: - Room Background
    private var roomBackground: some View {
        ZStack {
            // Base dark room
            LinearGradient(
                colors: [
                    Color(red: 0.04 + roomWarmth * 0.08, green: 0.03, blue: 0.03),
                    Color(red: 0.06 + roomWarmth * 0.12, green: 0.03 + roomWarmth * 0.03, blue: 0.02),
                    Color(red: 0.08 + roomWarmth * 0.15, green: 0.04 + roomWarmth * 0.04, blue: 0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Warm glow that increases with fire
            RadialGradient(
                colors: [
                    Color.orange.opacity(roomWarmth * 0.3),
                    Color(red: 0.9, green: 0.3, blue: 0.1).opacity(roomWarmth * 0.15),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.85),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Subtle flicker on walls
            if burning {
                Color.orange.opacity(roomWarmth * 0.05 * (1 + Foundation.sin(flamePhase * 3) * 0.5))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Heat Distortion Layer
    private var heatDistortionLayer: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(Color.clear)
                .frame(height: 200)
                .overlay(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.03), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(x: heatDistortion, y: 1.0)
                .blur(radius: burning ? 1 : 0)
                .offset(y: -240)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Paper View
    private var paperView: some View {
        ZStack {
            // Paper shadow
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.4))
                .frame(width: 190, height: 250)
                .offset(x: 4, y: 6)
                .blur(radius: 8)

            // Paper body
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.93, blue: 0.86),
                                Color(red: 0.93, green: 0.89, blue: 0.82),
                                Color(red: 0.90, green: 0.86, blue: 0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 190, height: 250)

                // Paper texture lines (handwriting simulation)
                VStack(spacing: 11) {
                    ForEach(0..<12, id: \.self) { i in
                        HStack {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(red: 0.25, green: 0.25, blue: 0.35).opacity(0.35 + Double(i % 3) * 0.1))
                                .frame(width: CGFloat(50 + (i * 17) % 110), height: 1.5)
                            Spacer()
                        }
                        .padding(.leading, CGFloat(15 + (i * 7) % 20))
                    }
                }
                .frame(width: 190, height: 250)
                .padding(.vertical, 20)

                // "Your words" watermark
                VStack {
                    HStack {
                        Text("Your words")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray.opacity(0.5))
                        Spacer()
                    }
                    .padding(10)
                    Spacer()
                }
                .frame(width: 190, height: 250)

                // Paper edge highlight
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    .frame(width: 190, height: 250)
            }
        }
    }

    // MARK: - Burning Paper View (in fireplace)
    private var burningPaperView: some View {
        VStack {
            Spacer()
            ZStack {
                // Paper that is burning - shrinks from bottom
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.89, blue: 0.82),
                                Color(red: 0.6, green: 0.4, blue: 0.2).opacity(1.0 - burnProgress),
                                Color(red: 0.2, green: 0.1, blue: 0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120 * (1 - burnProgress * 0.4), height: 160 * (1 - burnProgress))
                    .scaleEffect(x: 1 - burnProgress * 0.3, y: 1 - burnProgress, anchor: .top)
                    .opacity(1.0 - burnProgress)
                    .overlay(
                        // Orange fire edge at bottom
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [Color.clear, Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                            .blur(radius: 4)
                        }
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 120, height: 160)
                    )
            }
            .offset(y: -260)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Elite Fireplace View
    private var eliteFireplaceView: some View {
        ZStack {
            // Stone hearth base
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.08, blue: 0.05),
                            Color(red: 0.08, green: 0.05, blue: 0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.3, blue: 0.15),
                                    Color(red: 0.35, green: 0.2, blue: 0.1),
                                    Color(red: 0.25, green: 0.15, blue: 0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 14
                        )
                )
                .shadow(color: burning ? Color.orange.opacity(0.7) : Color.orange.opacity(0.1), radius: burning ? 60 : 10)

            // Inner fire chamber
            if burning || fireIntensity > 0 {
                ZStack {
                    // Deep ember bed
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.red.opacity(0.9 * Double(fireIntensity)),
                                    Color.orange.opacity(0.5 * Double(fireIntensity)),
                                    Color(red: 0.3, green: 0.1, blue: 0).opacity(0.3 * Double(fireIntensity)),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 100
                            )
                        )
                        .frame(width: 220, height: 50)
                        .offset(y: 70)

                    // Layer 1: Deep red outer flame
                    flameLayer(
                        width: 180, height: 160,
                        colors: [Color(red: 0.6, green: 0.1, blue: 0), Color.red.opacity(0.8), Color.red.opacity(0)],
                        blur: 15, yOffset: -10, phaseOffset: 0
                    )

                    // Layer 2: Orange middle flame
                    flameLayer(
                        width: 140, height: 140,
                        colors: [Color(red: 1, green: 0.4, blue: 0), Color.orange, Color.orange.opacity(0)],
                        blur: 10, yOffset: 0, phaseOffset: 0.5
                    )

                    // Layer 3: Bright inner flame
                    flameLayer(
                        width: 90, height: 110,
                        colors: [Color.yellow, Color(red: 1, green: 0.6, blue: 0), Color.orange.opacity(0)],
                        blur: 6, yOffset: 10, phaseOffset: 1.0
                    )

                    // Layer 4: White-hot core
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.9), Color.yellow.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 30
                            )
                        )
                        .frame(width: 50, height: 30)
                        .blur(radius: 8)
                        .offset(y: 50)
                        .opacity(Double(fireIntensity))

                    // Animated flame tips (individual tongues of fire)
                    ForEach(0..<9, id: \.self) { i in
                        flameTip(index: i)
                    }

                    // Sparks rising
                    if burning {
                        ForEach(0..<15, id: \.self) { i in
                            Circle()
                                .fill(
                                    i % 3 == 0 ? Color.yellow : (i % 3 == 1 ? Color.orange : Color.red)
                                )
                                .frame(width: CGFloat(1 + i % 3), height: CGFloat(1 + i % 3))
                                .offset(
                                    x: CGFloat(Foundation.sin(Double(i) * 0.7 + Double(flamePhase)) * 50),
                                    y: CGFloat(-60 - Double(i) * 12) + CGFloat(Foundation.sin(Double(flamePhase) + Double(i)) * 8)
                                )
                                .opacity(Double(1.0 - CGFloat(i) / 15.0) * Double(fireIntensity))
                        }
                    }
                }
                .opacity(Double(fireIntensity))
            }

            // Smoke wisps
            if burning {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(Color.gray.opacity(0.08))
                        .frame(width: CGFloat(20 + i * 5), height: CGFloat(40 + i * 10))
                        .blur(radius: 12)
                        .offset(
                            x: CGFloat(Foundation.sin(Double(flamePhase) * 0.5 + Double(i)) * 30),
                            y: CGFloat(-120 - i * 15)
                        )
                }
            }
        }
        .frame(height: 260)
    }

    // MARK: - Flame Layer Helper
    private func flameLayer(width: CGFloat, height: CGFloat, colors: [Color], blur: CGFloat, yOffset: CGFloat, phaseOffset: CGFloat) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: width, height: height)
            .blur(radius: blur)
            .offset(y: yOffset)
            .scaleEffect(
                x: 1.0 + CGFloat(Foundation.sin(Double(flamePhase + phaseOffset) * 2)) * 0.05,
                y: 1.0 + CGFloat(Foundation.cos(Double(flamePhase + phaseOffset) * 1.5)) * 0.08
            )
    }

    // MARK: - Flame Tip Helper
    private func flameTip(index: Int) -> some View {
        let xPos = CGFloat(index * 22 - 88)
        let baseHeight = CGFloat(25 + (index * 7) % 30)
        let tipColors: [Color] = index % 2 == 0
            ? [Color.yellow.opacity(0.9), Color.orange.opacity(0.6), Color.red.opacity(0)]
            : [Color.orange.opacity(0.9), Color(red: 1, green: 0.3, blue: 0).opacity(0.6), Color.red.opacity(0)]

        return Capsule()
            .fill(
                LinearGradient(colors: tipColors, startPoint: .bottom, endPoint: .top)
            )
            .frame(width: CGFloat(3 + index % 3 * 2), height: baseHeight)
            .blur(radius: 2)
            .offset(x: xPos, y: CGFloat(-40 - index * 4))
            .scaleEffect(
                y: 1.0 + CGFloat(sin(Double(flameTipPhase) + Double(index) * 0.8)) * 0.4
            )
            .opacity(Double(fireIntensity))
    }

    // MARK: - Instruction Overlay
    private var instructionOverlay: some View {
        VStack {
            Spacer().frame(height: 80)

            VStack(spacing: 12) {
                Text("Drag your words into the fire")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.white.opacity(0.8))

                Image(systemName: "arrow.down")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white.opacity(0.4))
                    .offset(y: sin(flamePhase * 2) * 4)

                Text("Let them burn away")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.4))
                    .blur(radius: 1)
            )
            .opacity(instructionOpacity)

            Spacer()
        }
    }

    // MARK: - Paper Drag Gesture
    private var paperDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                paperOffset = value.translation

                // Multi-axis rotation based on drag position
                let normalizedX = value.translation.width / 200
                let normalizedY = value.translation.height / 400

                paperRotationY = Double(normalizedX) * 15
                paperRotationX = Double(-normalizedY) * 10
                paperRotationZ = Double(normalizedX) * 5

                // Paper crumples slightly as dragged further
                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                paperScale = max(0.85, 1.0 - distance / 1500)

                // Fade instruction as user drags
                if showInstruction {
                    instructionOpacity = max(0, 1.0 - Double(distance) / 100)
                }
            }
            .onEnded { value in
                // If dragged down far enough toward fireplace
                if value.translation.height > 180 {
                    placePaperInFire()
                } else {
                    // Spring back
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        paperOffset = .zero
                        paperRotationX = 0
                        paperRotationY = 0
                        paperRotationZ = 0
                        paperScale = 1.0
                    }
                }
            }
    }

    // MARK: - Actions
    private func placePaperInFire() {
        showInstruction = false
        paperPlaced = true

        // Animate paper dropping into fireplace
        withAnimation(.easeIn(duration: 0.6)) {
            paperOffset = CGSize(width: 0, height: 350)
            paperScale = 0.4
            paperRotationX = 25
            paperOpacity = 0.0
        }

        // Ignite after paper lands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            ignited = true
            burning = true
            triggerIgnitionHaptics()
            startBurning()
            startParticleSystem()
        }
    }

    private func startBurning() {
        // Ramp up fire intensity
        withAnimation(.easeIn(duration: 1.5)) {
            fireIntensity = 1.0
        }

        // Room warmth increases
        withAnimation(.easeIn(duration: 2.5)) {
            roomWarmth = 1.0
        }

        // Heat distortion
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            heatDistortion = 1.02
        }

        // Burn progress timer
        burnTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            DispatchQueue.main.async {
                if burnProgress < 1.0 {
                    burnProgress += 0.015
                } else {
                    timer.invalidate()
                    finishBurn()
                }
            }
        }
    }

    private func startParticleSystem() {
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            DispatchQueue.main.async {
                if !burning { timer.invalidate(); return }
                spawnAshParticle()
                if Int.random(in: 0...2) == 0 {
                    spawnEmberParticle()
                }
                cleanupParticles()
            }
        }
    }

    private func spawnAshParticle() {
        let screenWidth = UIScreen.main.bounds.width
        let particle = AshParticle(
            x: screenWidth / 2 + CGFloat.random(in: -80...80),
            y: UIScreen.main.bounds.height - 260,
            size: CGFloat.random(in: 3...8),
            opacity: Double.random(in: 0.3...0.7),
            rotation: Double.random(in: 0...360),
            driftX: CGFloat.random(in: -1...1)
        )
        ashParticles.append(particle)

        // Animate upward
        withAnimation(.easeOut(duration: Double.random(in: 2.0...4.0))) {
            if let idx = ashParticles.firstIndex(where: { $0.id == particle.id }) {
                ashParticles[idx].y -= CGFloat.random(in: 200...500)
                ashParticles[idx].x += CGFloat.random(in: -60...60)
                ashParticles[idx].opacity = 0
                ashParticles[idx].rotation += Double.random(in: 90...360)
            }
        }
    }

    private func spawnEmberParticle() {
        let screenWidth = UIScreen.main.bounds.width
        let particle = EmberParticle(
            x: screenWidth / 2 + CGFloat.random(in: -60...60),
            y: UIScreen.main.bounds.height - 280,
            size: CGFloat.random(in: 2...5),
            opacity: 1.0,
            velocityX: CGFloat.random(in: -3...3),
            velocityY: CGFloat.random(in: (-5)...(-2))
        )
        emberParticles.append(particle)

        withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5))) {
            if let idx = emberParticles.firstIndex(where: { $0.id == particle.id }) {
                emberParticles[idx].y -= CGFloat.random(in: 80...160)
                emberParticles[idx].x += CGFloat.random(in: -40...40)
                emberParticles[idx].opacity = 0
            }
        }
    }

    private func cleanupParticles() {
        ashParticles.removeAll { $0.opacity <= 0.01 }
        emberParticles.removeAll { $0.opacity <= 0.01 }
        // Cap particle count
        if ashParticles.count > 30 { ashParticles.removeFirst(5) }
        if emberParticles.count > 20 { emberParticles.removeFirst(3) }
    }

    private func finishBurn() {
        // Final burst
        for _ in 0..<5 { spawnEmberParticle() }

        // Fade fire down
        withAnimation(.easeOut(duration: 1.5)) {
            fireIntensity = 0.3
            roomWarmth = 0.4
        }

        // Trigger completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            onFinished()
        }
    }

    private func startFlameAnimation() {
        // Continuous flame movement
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            flamePhase = .pi * 2
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            flameTipPhase = .pi
        }
    }

    private func triggerIgnitionHaptics() {
        // Crackle sequence - rapid light haptics simulating paper catching fire
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()

        let delays: [Double] = [0, 0.05, 0.12, 0.18, 0.25, 0.35, 0.42, 0.5, 0.6, 0.72, 0.85, 1.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                generator.impactOccurred(intensity: CGFloat.random(in: 0.4...1.0))
            }
        }

        // Medium impact for the main ignition moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
        }
    }
}
