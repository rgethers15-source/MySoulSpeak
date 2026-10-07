import SwiftUI

/// Prayer/Outro Screen: Dr. Hope's closing quote, play prayer button, scripture of the day.
/// Dr. Hope speaks in warm Gullah-style, comforting and spiritual.
struct PrayerOutroView: View {
    @StateObject private var audioPlayer = AudioPlayerService.shared

    @State private var quoteOpacity: Double = 0
    @State private var scriptureOpacity: Double = 0
    @State private var prayerPlaying = false
    @State private var drHopeTalking = false
    @State private var glowPulse = false
    @State private var candleFlicker: CGFloat = 1.0
    @State private var backgroundShimmer = false

    private let closingQuote = ScriptureService.dailyClosingQuote()
    private let scripture = ScriptureService.dailyScripture()

    var body: some View {
        ZStack {
            // Peaceful dark background with warm tones
            prayerBackground

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)

                    // Dr. Hope avatar with candle glow
                    drHopeClosingSection

                    // Closing quote card
                    closingQuoteCard
                        .opacity(quoteOpacity)

                    // Play prayer section
                    prayerSection

                    // Scripture of the day
                    scriptureCard
                        .opacity(scriptureOpacity)

                    // Peaceful sign-off
                    signOffSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Prayer & Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            audioPlayer.stopAll()
        }
    }

    // MARK: - Background
    private var prayerBackground: some View {
        ZStack {
            // Deep spiritual gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.14),
                    Color(red: 0.14, green: 0.1, blue: 0.22),
                    Color(red: 0.1, green: 0.08, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle star-like shimmer
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(backgroundShimmer ? 0.3 : 0.1))
                    .frame(width: CGFloat.random(in: 2...4))
                    .offset(
                        x: CGFloat.random(in: -180...180),
                        y: CGFloat.random(in: -350...350)
                    )
            }

            // Warm candle-like glow at center
            RadialGradient(
                colors: [
                    Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 300
            )
            .ignoresSafeArea()
            .scaleEffect(candleFlicker)
        }
    }

    // MARK: - Dr. Hope Closing Section
    private var drHopeClosingSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Warm spiritual glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.3),
                                Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowPulse ? 1.1 : 1.0)

                // Avatar
                Image("dr_hope")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.9, green: 0.7, blue: 0.3), Color(red: 0.7, green: 0.4, blue: 0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.4), radius: 12)

                // Talking indicator
                if drHopeTalking {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color(red: 0.9, green: 0.7, blue: 0.3))
                                .frame(width: 3, height: CGFloat(5 + i * 3))
                                .animation(
                                    .easeInOut(duration: 0.25 + Double(i) * 0.08)
                                        .repeatForever(autoreverses: true),
                                    value: drHopeTalking
                                )
                        }
                    }
                    .offset(x: 50, y: 5)
                }
            }

            Text("Dr. Hope")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.8))
        }
    }

    // MARK: - Closing Quote Card
    private var closingQuoteCard: some View {
        VStack(spacing: 16) {
            // Decorative opening quote
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.6))

            Text(closingQuote.quote)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .italic()

            Text("— \(closingQuote.attribution)")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.7))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Prayer Section
    private var prayerSection: some View {
        VStack(spacing: 16) {
            Text(prayerPlaying ? "Praying with you..." : "Evening Prayer")
                .font(SSTypography.headline)
                .foregroundColor(.white.opacity(0.9))

            // Play prayer button
            Button(action: togglePrayer) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(prayerPlaying ? 0.2 : 0.1))
                        .frame(width: 88, height: 88)
                        .scaleEffect(prayerPlaying ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: prayerPlaying)

                    // Button circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.7, green: 0.4, blue: 0.8),
                                    Color(red: 0.5, green: 0.25, blue: 0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.5), radius: 10, y: 4)

                    Image(systemName: prayerPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .offset(x: prayerPlaying ? 0 : 2)
                }
            }

            Text(prayerPlaying ? "Tap to pause" : "Tap to play prayer")
                .font(SSTypography.small)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Scripture Card
    private var scriptureCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))
                Text("Scripture of the Day")
                    .font(SSTypography.caption)
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.8))
                Spacer()
            }

            Text("\"\(scripture.verse)\"")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineSpacing(5)

            HStack {
                Spacer()
                Text("— \(scripture.reference)")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(SSColors.secondary.opacity(0.8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Sign Off
    private var signOffSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(0.6))

            Text("Rest well tonight, baby.\nThe Lord's got you.")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .italic()
        }
        .padding(.top, 8)
    }

    // MARK: - Actions
    private func togglePrayer() {
        if prayerPlaying {
            audioPlayer.stopVoice()
            prayerPlaying = false
            drHopeTalking = false
        } else {
            audioPlayer.playPrayer(fileName: "dr_hope_prayer")
            prayerPlaying = true
            drHopeTalking = true

            // Stop talking indicator after typical prayer duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                if prayerPlaying {
                    drHopeTalking = false
                }
            }
        }
    }

    private func startAnimations() {
        // Glow pulse
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        // Candle flicker
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            candleFlicker = 1.03
        }

        // Background shimmer
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            backgroundShimmer = true
        }

        // Fade in quote
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                quoteOpacity = 1.0
            }
        }

        // Fade in scripture
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 1.0)) {
                scriptureOpacity = 1.0
            }
        }
    }
}
