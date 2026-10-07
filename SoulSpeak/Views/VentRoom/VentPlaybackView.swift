import SwiftUI
import AVFoundation
import UIKit

// MARK: - Floating Word Model
private struct FloatingWord: Identifiable {
    let id = UUID()
    var text: String
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
}

/// Elite Vent Playback View - Immersive audio playback with animated visualizer bars,
/// floating dissolving words, glowing progress trail, darkening atmosphere,
/// intensifying burn button, and fade-in quotes building tension toward release.
struct VentPlaybackView: View {
    @ObservedObject var recorder: VoiceRecorderService
    let onFinished: () -> Void

    // Playback state
    @State private var isPlaying = false
    @State private var playbackProgress: CGFloat = 0
    @State private var player: AVAudioPlayer?
    @State private var playbackDuration: TimeInterval = 5.0

    // Visualizer
    @State private var visualizerLevels: [CGFloat] = Array(repeating: 0.1, count: 32)
    @State private var visualizerTimer: Timer?

    // Floating words
    @State private var floatingWords: [FloatingWord] = []
    @State private var wordTimer: Timer?

    // Atmosphere
    @State private var atmosphereDarkness: Double = 0
    @State private var burnButtonGlow: Double = 0.3
    @State private var burnButtonScale: CGFloat = 1.0

    // Quotes
    @State private var currentQuote: String = ""
    @State private var quoteOpacity: Double = 0
    @State private var quoteIndex = 0
    private let quotes = [
        "These words no longer serve you",
        "Ready to let go?",
        "The fire awaits...",
        "Release them to the flames"
    ]

    // Progress glow
    @State private var progressGlowPhase: CGFloat = 0

    // Appearance
    @State private var viewReady = false

    var body: some View {
        ZStack {
            // Darkening background
            atmosphericBackground

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Speaker icon with floating words
                speakerWithWords

                Spacer().frame(height: 24)

                // Title
                Text("Playing back your words...")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(viewReady ? 1 : 0)

                Spacer().frame(height: 32)

                // Audio visualizer bars
                if isPlaying {
                    audioVisualizer
                }

                Spacer().frame(height: 28)

                // Glowing progress bar
                progressBar

                Spacer().frame(height: 20)

                // Fade-in quote
                quoteSection

                Spacer()

                // Burn button (intensifies over time)
                burnButton

                Spacer().frame(height: 16)

                Text("Listen one last time")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.3))
                    .italic()

                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                viewReady = true
            }
            startPlayback()
            startProgressGlow()
        }
        .onDisappear {
            visualizerTimer?.invalidate()
            wordTimer?.invalidate()
            player?.stop()
        }
    }

    // MARK: - Atmospheric Background
    private var atmosphericBackground: some View {
        ZStack {
            // Base dark with progressive darkening
            LinearGradient(
                colors: [
                    Color(red: 0.06 - atmosphereDarkness * 0.03, green: 0.04, blue: 0.06 + atmosphereDarkness * 0.02),
                    Color(red: 0.04, green: 0.03 - atmosphereDarkness * 0.02, blue: 0.05 + atmosphereDarkness * 0.03),
                    Color(red: 0.03, green: 0.02, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle vignette that deepens
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3 + atmosphereDarkness * 0.4)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Dim orange glow at bottom (fireplace hint)
            VStack {
                Spacer()
                RadialGradient(
                    colors: [
                        Color.orange.opacity(0.06 + burnButtonGlow * 0.04),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 10,
                    endRadius: 200
                )
                .frame(height: 180)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Speaker with Floating Words
    private var speakerWithWords: some View {
        ZStack {
            // Floating dissolving words
            ForEach(floatingWords) { word in
                Text(word.text)
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.4))
                    .opacity(word.opacity)
                    .scaleEffect(word.scale)
                    .position(x: word.x, y: word.y)
            }

            // Speaker icon with glow
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)

                Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.white.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
            }
        }
        .frame(width: 250, height: 120)
    }

    // MARK: - Audio Visualizer
    private var audioVisualizer: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<32, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: visualizerBarColors(index: index),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 6,
                        height: max(4, visualizerLevels[index] * 60)
                    )
                    .animation(.easeInOut(duration: 0.08), value: visualizerLevels[index])
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 24)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                // Filled portion with gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.5, blue: 0.2),
                                Color(red: 0.95, green: 0.35, blue: 0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * playbackProgress, height: 6)

                // Glowing head
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.orange.opacity(0.8), radius: 8)
                    .shadow(color: Color.orange.opacity(0.4), radius: 16)
                    .offset(x: geo.size.width * playbackProgress - 6)
                    .scaleEffect(1.0 + sin(progressGlowPhase) * 0.1)

                // Trail glow
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: min(40, geo.size.width * playbackProgress), height: 6)
                    .offset(x: max(0, geo.size.width * playbackProgress - 40))
                    .blur(radius: 3)
            }
        }
        .frame(height: 12)
        .padding(.horizontal, 40)
    }

    // MARK: - Quote Section
    private var quoteSection: some View {
        Text(currentQuote)
            .font(.system(size: 14, weight: .regular, design: .serif))
            .foregroundColor(Color(red: 0.8, green: 0.5, blue: 0.3).opacity(0.7))
            .italic()
            .opacity(quoteOpacity)
            .frame(height: 20)
            .padding(.horizontal, 40)
    }

    // MARK: - Burn Button
    private var burnButton: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            player?.stop()
            visualizerTimer?.invalidate()
            wordTimer?.invalidate()
            onFinished()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                Text("Burn it now")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.95, green: 0.45 + burnButtonGlow * 0.2, blue: 0.2))
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .stroke(
                        Color(red: 0.95, green: 0.4, blue: 0.15).opacity(0.4 + burnButtonGlow * 0.4),
                        lineWidth: 2
                    )
                    .shadow(color: Color.orange.opacity(burnButtonGlow * 0.6), radius: 12)
            )
            .scaleEffect(burnButtonScale)
        }
    }

    // MARK: - Visualizer Colors
    private func visualizerBarColors(index: Int) -> [Color] {
        let normalizedIndex = Double(index) / 32.0
        let progress = Double(playbackProgress)
        return [
            Color(red: 0.3 + progress * 0.5, green: 0.4 - progress * 0.3, blue: 0.7 - progress * 0.5).opacity(0.6),
            Color(red: 0.5 + progress * 0.4, green: 0.3 - progress * 0.2, blue: 0.5 - progress * 0.4).opacity(0.8),
            Color(red: 0.7 + normalizedIndex * 0.2, green: 0.2, blue: 0.1).opacity(0.4 + progress * 0.3)
        ]
    }

    // MARK: - Playback Logic
    private func startPlayback() {
        guard let url = recorder.recordingURL else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onFinished() }
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.isMeteringEnabled = true
            player?.play()
            isPlaying = true
            playbackDuration = player?.duration ?? 5.0

            // Animate progress
            withAnimation(.linear(duration: playbackDuration)) {
                playbackProgress = 1.0
            }

            // Atmosphere darkens over playback
            withAnimation(.linear(duration: playbackDuration)) {
                atmosphereDarkness = 1.0
            }

            // Burn button intensifies
            withAnimation(.easeIn(duration: playbackDuration)) {
                burnButtonGlow = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                burnButtonScale = 1.06
            }

            // Start visualizer updates
            startVisualizer()
            // Start floating words
            startFloatingWords()
            // Start quotes
            startQuoteCycle()

            // Auto-finish after playback
            DispatchQueue.main.asyncAfter(deadline: .now() + playbackDuration + 0.8) {
                onFinished()
            }
        } catch {
            print("[SoulSpeak] Playback error: \(error)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onFinished() }
        }
    }

    private func startVisualizer() {
        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { _ in
            DispatchQueue.main.async {
                player?.updateMeters()
                let power = player?.averagePower(forChannel: 0) ?? -50
                let normalizedPower = max(0, (power + 50) / 50) // 0 to 1

                // Generate bar levels with some randomness
                for i in 0..<32 {
                    let base = CGFloat(normalizedPower)
                    let variance = CGFloat.random(in: -0.2...0.2)
                    let centerBias = 1.0 - abs(CGFloat(i - 16) / 16.0) * 0.4
                    visualizerLevels[i] = max(0.05, min(1.0, (base + variance) * centerBias))
                }
            }
        }
    }

    private func startFloatingWords() {
        let words = ["anger", "pain", "frustration", "hurt", "rage", "tears", "weight", "burden", "enough", "why", "done", "free"]
        let screenWidth = UIScreen.main.bounds.width

        wordTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            DispatchQueue.main.async {
                let word = FloatingWord(
                    text: words.randomElement() ?? "release",
                    x: screenWidth / 2 + CGFloat.random(in: -40...40),
                    y: 160,
                    opacity: 0.6,
                    scale: 1.0
                )
                floatingWords.append(word)

                // Animate word floating up and dissolving
                withAnimation(.easeOut(duration: 2.5)) {
                    if let idx = floatingWords.firstIndex(where: { $0.id == word.id }) {
                        floatingWords[idx].y -= CGFloat.random(in: 40...80)
                        floatingWords[idx].x += CGFloat.random(in: -50...50)
                        floatingWords[idx].opacity = 0
                        floatingWords[idx].scale = 0.5
                    }
                }

                // Cleanup old words
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    floatingWords.removeAll { $0.opacity <= 0.01 }
                    if floatingWords.count > 15 { floatingWords.removeFirst(5) }
                }
            }
        }
    }

    private func startQuoteCycle() {
        cycleQuote()
    }

    private func cycleQuote() {
        guard isPlaying else { return }

        currentQuote = quotes[quoteIndex % quotes.count]
        withAnimation(.easeIn(duration: 0.8)) {
            quoteOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                quoteOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            quoteIndex += 1
            cycleQuote()
        }
    }

    private func startProgressGlow() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            progressGlowPhase = .pi * 2
        }
    }
}
