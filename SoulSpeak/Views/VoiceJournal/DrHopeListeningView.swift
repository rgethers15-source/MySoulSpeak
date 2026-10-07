import SwiftUI

/// Animated full-screen view of Dr. Hope listening during a recording session.
/// Uses the photo of Dr. Hope writing in her office with subtle animations
/// to make her feel alive — writing, nodding, occasionally looking up.
///
/// Image asset expected: "dr_hope_listening" in Assets.xcassets
/// (the photo of Dr. Hope in lavender blazer, writing on clipboard in her office)
struct DrHopeListeningView: View {
    // Animation states
    @State private var isWriting = false
    @State private var lookingUp = false
    @State private var penOffset: CGFloat = 0
    @State private var headTilt: Double = 0
    @State private var breathe = false
    @State private var warmGlow = false
    @State private var nodCycle = false

    var body: some View {
        ZStack {
            // Full-screen Dr. Hope image (her in the office writing)
            Image("dr_hope_listening")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                // Subtle breathing/scale animation — makes her feel alive
                .scaleEffect(breathe ? 1.008 : 1.0)
                // Very subtle vertical shift — like she's adjusting posture
                .offset(y: nodCycle ? -1.5 : 1.5)

            // Warm ambient overlay — soft golden light like the office lamp
            RadialGradient(
                colors: [
                    Color(red: 0.95, green: 0.8, blue: 0.4).opacity(warmGlow ? 0.06 : 0.03),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            // "Writing" pen motion indicator (subtle animated dots near her hand area)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // Pen writing animation — small dots that appear rhythmically
                    if isWriting {
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 4, height: 4)
                                    .offset(y: penOffset + CGFloat(i) * 2)
                                    .animation(
                                        .easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.15),
                                        value: penOffset
                                    )
                            }
                        }
                        .offset(x: -60, y: -180)
                        .transition(.opacity)
                    }
                    Spacer()
                }
            }

            // "Looking up" indicator — subtle eye contact glow
            if lookingUp {
                VStack {
                    // Warm glow near her face area
                    Circle()
                        .fill(Color(red: 0.9, green: 0.8, blue: 0.6).opacity(0.08))
                        .frame(width: 120, height: 120)
                        .offset(y: -100)
                        .transition(.opacity)
                    Spacer()
                }
            }

            // Soft vignette for depth
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.2)],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
        .onAppear {
            startListeningAnimations()
        }
    }

    // MARK: - Animations
    private func startListeningAnimations() {
        // Breathing — constant subtle scale
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            breathe = true
        }

        // Gentle nod/posture shift
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            nodCycle = true
        }

        // Warm glow flicker (like office lamp)
        withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
            warmGlow = true
        }

        // Writing animation — starts immediately
        withAnimation(.easeIn(duration: 0.3)) {
            isWriting = true
            penOffset = -3
        }

        // Cycle between writing and looking up
        startWritingCycle()
    }

    private func startWritingCycle() {
        // Write for 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            // Look up (making eye contact with user)
            withAnimation(.easeInOut(duration: 0.5)) {
                isWriting = false
                lookingUp = true
                headTilt = 2
            }

            // Back to writing after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    lookingUp = false
                    isWriting = true
                    headTilt = 0
                }

                // Repeat the cycle
                startWritingCycle()
            }
        }
    }
}
