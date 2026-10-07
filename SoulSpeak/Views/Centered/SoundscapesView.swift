import SwiftUI

/// Soundscapes — Free playlist of relaxing soundscapes and instrumental music.
///
/// Audio files expected in bundle (all free/royalty-free):
/// - rain_gentle.mp3
/// - ocean_waves.mp3
/// - forest_birds.mp3
/// - creek_flowing.mp3
/// - thunder_distant.mp3
/// - night_crickets.mp3
/// - piano_calm.mp3
/// - guitar_acoustic.mp3
/// - flute_meditation.mp3
/// - jazz_soft.mp3
/// - harp_peaceful.mp3
/// - chimes_wind.mp3
struct SoundscapesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @State private var currentlyPlaying: String? = nil
    @State private var selectedCategory: SoundCategory = .nature

    enum SoundCategory: String, CaseIterable {
        case nature = "Meditations"
        case instrumental = "Pep Talks"
        case ambient = "Healing"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.1, blue: 0.16),
                        Color(red: 0.08, green: 0.12, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SoundCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Track list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tracks(for: selectedCategory)) { track in
                                trackRow(track)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }

                    // Now playing bar
                    if currentlyPlaying != nil {
                        nowPlayingBar
                    }
                }
            }
            .navigationTitle("Soundscapes")
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
                stopPlaying()
            }
        }
    }

    // MARK: - Track Row
    private func trackRow(_ track: SoundTrack) -> some View {
        Button(action: { playTrack(track) }) {
            HStack(spacing: 14) {
                // Play/pause icon
                ZStack {
                    Circle()
                        .fill(currentlyPlaying == track.fileName ? track.color.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 48, height: 48)

                    Image(systemName: currentlyPlaying == track.fileName ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(currentlyPlaying == track.fileName ? track.color : .white.opacity(0.6))
                }

                // Track info
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Text(track.duration)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Loop indicator
                Image(systemName: "repeat")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(currentlyPlaying == track.fileName ? track.color.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(currentlyPlaying == track.fileName ? track.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Now Playing Bar
    private var nowPlayingBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                // Animated bars
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.4, green: 0.7, blue: 0.9))
                            .frame(width: 3, height: CGFloat.random(in: 8...18))
                    }
                }

                Text("Now Playing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // STOP button — prominent and clear
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
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.9))
        }
    }

    // MARK: - Actions
    private func playTrack(_ track: SoundTrack) {
        if currentlyPlaying == track.fileName {
            stopPlaying()
        } else {
            audioPlayer.stopAll()
            // Play as background music (loops)
            audioPlayer.playBackgroundMusic(fileName: track.fileName)
            currentlyPlaying = track.fileName
            print("[SoulSpeak Soundscapes] Playing: \(track.fileName).mp3")
        }
    }

    private func stopPlaying() {
        audioPlayer.stopVoice()
        audioPlayer.stopBackgroundMusic()
        audioPlayer.stopAll()
        currentlyPlaying = nil
    }

    // MARK: - Track Data
    private func tracks(for category: SoundCategory) -> [SoundTrack] {
        switch category {
        case .nature:
            return [
                SoundTrack(name: "Inner Peace", fileName: "inner_peace_meditation", duration: "Loop", color: .blue),
                SoundTrack(name: "Stress Release", fileName: "stress_release_meditation", duration: "Loop", color: .cyan),
                SoundTrack(name: "Returning Love", fileName: "returning_love_to_yourself", duration: "Loop", color: .green),
                SoundTrack(name: "Internal Conflict", fileName: "internal_conflict_meditation", duration: "Loop", color: .teal),
                SoundTrack(name: "Rejuvenation (Dr. Hope)", fileName: "rejuvenation_meditation_dh", duration: "Loop", color: .purple),
                SoundTrack(name: "Rejuvenation (Mr. Hope)", fileName: "rejuvenation_meditation_mh", duration: "Loop", color: .indigo),
            ]
        case .instrumental:
            return [
                SoundTrack(name: "Feminine Energy Pep Talk", fileName: "feminine_energy_pep_talk", duration: "Full", color: .pink),
                SoundTrack(name: "Masculine Energy Pep Talk", fileName: "masculine_energy_pep_talk", duration: "Full", color: .orange),
                SoundTrack(name: "Anger Management", fileName: "anger_management_meditation", duration: "Full", color: .red),
            ]
        case .ambient:
            return [
                SoundTrack(name: "Breaking Free", fileName: "breaking_free_abusive_relationship", duration: "Full", color: .cyan),
                SoundTrack(name: "Overcoming Harm", fileName: "overcoming_harmful_relationship", duration: "Full", color: .purple),
            ]
        }
    }
}

struct SoundTrack: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let duration: String
    let color: Color
}
