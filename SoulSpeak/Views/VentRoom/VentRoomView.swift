import SwiftUI
import UIKit

/// Vent Room - Premium feature for emotional release.
///
/// Flow:
/// 1. Mr. Hope intro video (presents the room, opens the door)
/// 2. Room with recording -> playback -> paper -> fireplace
/// 3. Interactive destruction tools (break, throw, smash, spray)
/// 4. "Release" button resets the room
///
/// Elite transitions with haptic pulses between each phase,
/// color temperature shifts, and smooth crossfade animations.
enum VentRoomPhase {
    case intro          // Mr. Hope video presenting the room
    case recording      // User records their vent
    case playback       // Playing back what they said
    case paperBurn      // Recording transforms to paper -> fireplace
    case destruction    // Interactive room destruction
    case release        // Release button -> room resets
}

struct VentRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorderService()
    @StateObject private var store = StoreKitService.shared

    @State private var phase: VentRoomPhase = .intro
    @State private var showPaywall = false
    @State private var phaseTransitionOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !store.isPremium {
                lockedView
            } else {
                // Phase content with transitions
                phaseContent
                    .opacity(phaseTransitionOpacity)
            }

            // Back button overlay (always visible)
            VStack {
                HStack {
                    Button(action: {
                        AudioPlayerService.shared.stopBackgroundMusic()
                        AudioPlayerService.shared.stopAll()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onDisappear {
            // Stop rock instrumental and all audio when leaving Vent Room
            AudioPlayerService.shared.stopBackgroundMusic()
            AudioPlayerService.shared.stopAll()
        }
    }

    // MARK: - Phase Content
    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .intro:
            ventRoomIntro
                .transition(.opacity)

        case .recording:
            VentRecordingView(
                recorder: recorder,
                onFinished: {
                    transitionToPhase(.playback)
                }
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity
            ))

        case .playback:
            VentPlaybackView(
                recorder: recorder,
                onFinished: {
                    transitionToPhase(.paperBurn)
                }
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)).animation(.easeInOut(duration: 0.5)),
                removal: .opacity.animation(.easeOut(duration: 0.3))
            ))

        case .paperBurn:
            PaperBurnView(
                onFinished: {
                    transitionToPhase(.destruction)
                }
            )
            .transition(.asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.6)),
                removal: .opacity.combined(with: .scale(scale: 1.05)).animation(.easeOut(duration: 0.4))
            ))

        case .destruction:
            DestructionRoomView(
                onRelease: {
                    transitionToPhase(.release)
                }
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.easeIn(duration: 0.5)),
                removal: .opacity.animation(.easeOut(duration: 0.6))
            ))

        case .release:
            ReleaseView(
                onComplete: {
                    transitionToPhase(.recording)
                },
                onExit: { dismiss() }
            )
            .transition(.opacity.animation(.easeIn(duration: 0.8)))
        }
    }

    // MARK: - Phase Transition with Haptic
    private func transitionToPhase(_ newPhase: VentRoomPhase) {
        // Haptic pulse for transition
        triggerPhaseHaptic(for: newPhase)

        // Smooth crossfade transition
        withAnimation(.easeInOut(duration: 0.5)) {
            phase = newPhase
        }
    }

    private func triggerPhaseHaptic(for newPhase: VentRoomPhase) {
        switch newPhase {
        case .recording:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred(intensity: 0.6)
        case .playback:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.7)
        case .paperBurn:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred(intensity: 0.8)
        case .destruction:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred(intensity: 1.0)
            // Double-tap for intensity
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let g2 = UIImpactFeedbackGenerator(style: .medium)
                g2.impactOccurred(intensity: 0.6)
            }
        case .release:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .intro:
            break
        }
    }

    // MARK: - Locked View (not premium)
    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.4, blue: 0.2).opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.85, green: 0.3, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("The Vent Room")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.white)

            Text("A safe space to release your frustration.\nRecord. Burn. Destroy. Let go.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: { showPaywall = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
                    Text("Unlock Premium")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 36)
                .background(
                    Capsule()
                        .fill(SSColors.gradientPrimary)
                )
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Go Back")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Mr. Hope Intro Video
    private var ventRoomIntro: some View {
        ZStack {
            FullScreenVideoBackground(
                videoName: "mr_hope_vent_room",
                fileExtension: "mp4",
                looping: false,
                onFinished: {
                    transitionToPhase(.recording)
                }
            )
        }
    }
}
