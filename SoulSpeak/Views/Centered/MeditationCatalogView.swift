import SwiftUI

/// Meditation Catalog — Pre-recorded guided meditation sessions.
/// Audio files are already recorded with Dr. Hope and Mr. Hope voices.
struct MeditationCatalogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @State private var currentlyPlaying: String? = nil
    @State private var progressAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.14),
                        Color(red: 0.12, green: 0.08, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(sessions) { session in
                                sessionCard(session)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, currentlyPlaying != nil ? 120 : 40)
                    }

                    // Now Playing bar with STOP button
                    if currentlyPlaying != nil {
                        nowPlayingBar
                    }
                }
            }
            .navigationTitle("Meditations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        stopPlaying()
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .onDisappear {
                // Stop audio when leaving the view
                stopPlaying()
            }
        }
    }

    // MARK: - Session Card
    private func sessionCard(_ session: MeditationSession) -> some View {
        Button(action: { toggleSession(session) }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(session.color.opacity(currentlyPlaying == session.fileName ? 0.25 : 0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: session.icon)
                        .font(.system(size: 20))
                        .foregroundColor(session.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(session.guide)
                        .font(.system(size: 11))
                        .foregroundColor(session.color.opacity(0.8))
                }

                Spacer()

                // Play/Pause indicator
                if currentlyPlaying == session.fileName {
                    // Animated equalizer bars
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(session.color)
                                .frame(width: 3, height: progressAnimation ? CGFloat.random(in: 8...18) : 6)
                                .animation(
                                    .easeInOut(duration: 0.4)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.15),
                                    value: progressAnimation
                                )
                        }
                    }
                    .frame(width: 20)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(currentlyPlaying == session.fileName ? session.color.opacity(0.06) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(currentlyPlaying == session.fileName ? session.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Now Playing Bar (with prominent STOP button)
    private var nowPlayingBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 16) {
                // Animated bars
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.7, green: 0.4, blue: 0.8))
                            .frame(width: 3, height: progressAnimation ? CGFloat.random(in: 8...20) : 6)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.12),
                                value: progressAnimation
                            )
                    }
                }

                // Track name
                VStack(alignment: .leading, spacing: 2) {
                    Text("Now Playing")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text(currentSessionName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                // STOP BUTTON — prominent red square
                Button(action: stopPlaying) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Stop")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.8))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.9))
        }
    }

    // MARK: - Actions
    private func toggleSession(_ session: MeditationSession) {
        if currentlyPlaying == session.fileName {
            // STOP — not just pause
            stopPlaying()
        } else {
            // Stop any currently playing audio first
            stopPlaying()

            // Play the new session
            audioPlayer.playVoice(fileName: session.fileName)
            currentlyPlaying = session.fileName
            progressAnimation = true
        }
    }

    private func stopPlaying() {
        audioPlayer.stopVoice()
        audioPlayer.stopBackgroundMusic()
        audioPlayer.stopAll()
        currentlyPlaying = nil
        progressAnimation = false
    }

    // MARK: - Helpers
    private var currentSessionName: String {
        guard let fileName = currentlyPlaying else { return "" }
        return sessions.first(where: { $0.fileName == fileName })?.name ?? fileName
    }

    // MARK: - Sessions (matches your actual MP3 files)
    private var sessions: [MeditationSession] {
        [
            MeditationSession(
                name: "Cooling the Fire",
                fileName: "anger_management_meditation",
                guide: "Anger Management",
                icon: "flame.fill",
                color: .red
            ),
            MeditationSession(
                name: "Breaking Free",
                fileName: "breaking_free_abusive_relationship",
                guide: "Abusive Relationship Recovery",
                icon: "link.badge.plus",
                color: Color(red: 0.8, green: 0.4, blue: 0.5)
            ),
            MeditationSession(
                name: "Feminine Energy Pep Talk",
                fileName: "feminine_energy_pep_talk",
                guide: "Empowerment",
                icon: "sparkles",
                color: Color(red: 0.9, green: 0.5, blue: 0.7)
            ),
            MeditationSession(
                name: "The Quiet Place Within",
                fileName: "inner_peace_meditation",
                guide: "Inner Peace",
                icon: "leaf.fill",
                color: Color(red: 0.3, green: 0.7, blue: 0.5)
            ),
            MeditationSession(
                name: "Making Peace Within",
                fileName: "internal_conflict_meditation",
                guide: "Internal Conflict",
                icon: "arrow.triangle.branch",
                color: Color(red: 0.5, green: 0.5, blue: 0.8)
            ),
            MeditationSession(
                name: "Strength With Purpose",
                fileName: "masculine_energy_pep_talk",
                guide: "Masculine Energy",
                icon: "shield.fill",
                color: Color(red: 0.3, green: 0.5, blue: 0.9)
            ),
            MeditationSession(
                name: "Reclaiming Your Heart",
                fileName: "overcoming_harmful_relationship",
                guide: "Harmful Relationship Recovery",
                icon: "heart.fill",
                color: Color(red: 0.7, green: 0.3, blue: 0.4)
            ),
            MeditationSession(
                name: "Restoring Your Energy",
                fileName: "rejuvenation_meditation_dh",
                guide: "Dr. Hope",
                icon: "bolt.heart.fill",
                color: Color(red: 0.7, green: 0.4, blue: 0.8)
            ),
            MeditationSession(
                name: "Restoring Your Energy",
                fileName: "rejuvenation_meditation_mh",
                guide: "Mr. Hope",
                icon: "bolt.heart.fill",
                color: Color(red: 0.3, green: 0.6, blue: 0.9)
            ),
            MeditationSession(
                name: "Returning Love to Yourself",
                fileName: "returning_love_to_yourself",
                guide: "Self-Love",
                icon: "heart.circle.fill",
                color: Color(red: 0.9, green: 0.6, blue: 0.4)
            ),
            MeditationSession(
                name: "Lay the Weight Down",
                fileName: "stress_release_meditation",
                guide: "Stress Release",
                icon: "cloud.rain.fill",
                color: Color(red: 0.4, green: 0.6, blue: 0.8)
            ),
        ]
    }
}

struct MeditationSession: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let guide: String
    let icon: String
    let color: Color
}
