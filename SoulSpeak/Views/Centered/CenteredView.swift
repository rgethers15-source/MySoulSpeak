import SwiftUI

/// Centered — A peaceful interactive session space for guided audio.
///
/// Features:
/// - Walking intro video (entering the Centered room)
/// - Categorized audio: Meditations, Pep Talks, Healing, Dr. Hope Closings
/// - Interactive office atmosphere with breathing animation
///
/// Video expected: centered_room_intro.mp4
struct CenteredView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @State private var showIntroVideo = true
    @State private var selectedCategory: AudioCategory = .music
    @State private var currentlyPlaying: String? = nil
    @State private var progressAnimation = false

    enum AudioCategory: String, CaseIterable {
        case music = "Music"
        case meditations = "Meditations"
        case pepTalks = "Pep Talks"
        case healing = "Healing"
        case closings = "Closings"

        var icon: String {
            switch self {
            case .music: return "music.note.list"
            case .meditations: return "sparkles"
            case .pepTalks: return "bolt.fill"
            case .healing: return "heart.fill"
            case .closings: return "hands.and.sparkles.fill"
            }
        }

        var color: Color {
            switch self {
            case .music: return Color(red: 0.5, green: 0.4, blue: 0.9)
            case .meditations: return Color(red: 0.4, green: 0.7, blue: 0.9)
            case .pepTalks: return Color(red: 0.9, green: 0.6, blue: 0.3)
            case .healing: return Color(red: 0.8, green: 0.4, blue: 0.6)
            case .closings: return Color(red: 0.7, green: 0.4, blue: 0.8)
            }
        }
    }

    var body: some View {
        ZStack {
            if showIntroVideo {
                centeredIntroVideo
            } else {
                centeredMainView
            }

            // Back button overlay
            VStack {
                HStack {
                    Button(action: {
                        stopPlaying()
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
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.leading, 16)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            stopPlaying()
        }
    }

    // MARK: - Intro Video
    private var centeredIntroVideo: some View {
        FullScreenVideoBackground(
            videoName: "centered_room_intro",
            fileExtension: "mp4",
            looping: false,
            onFinished: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showIntroVideo = false
                }
            }
        )
    }

    // MARK: - Main View
    private var centeredMainView: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.1, blue: 0.14),
                    Color(red: 0.12, green: 0.14, blue: 0.2),
                    Color(red: 0.06, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle ambient glow (static, no animation)
            RadialGradient(
                colors: [
                    selectedCategory.color.opacity(0.06),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                            .padding(.top, 80)

                        // Category picker
                        categoryPicker

                        // Track list
                        LazyVStack(spacing: 12) {
                            ForEach(tracks(for: selectedCategory)) { track in
                                trackRow(track)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, currentlyPlaying != nil ? 100 : 40)
                    }
                }

                // Now Playing bar with STOP
                if currentlyPlaying != nil {
                    nowPlayingBar
                }
            }
        }
        .onAppear {
            // Static view — no repeating animations
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(selectedCategory.color)

            Text("Find Your Center")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)

            Text("Breathe. Listen. Be still.")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.6))
                .italic()
        }
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AudioCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color.opacity(0.3) : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == category ? category.color.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Track Row
    private func trackRow(_ track: CenteredTrack) -> some View {
        Button(action: { toggleTrack(track) }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(currentlyPlaying == track.fileName ? track.color.opacity(0.25) : track.color.opacity(0.1))
                        .frame(width: 48, height: 48)

                    if currentlyPlaying == track.fileName {
                        // Animated equalizer
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(track.color)
                                    .frame(width: 3, height: progressAnimation ? CGFloat.random(in: 8...16) : 6)
                                    .animation(
                                        .easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.15),
                                        value: progressAnimation
                                    )
                            }
                        }
                    } else {
                        Image(systemName: track.icon)
                            .font(.system(size: 18))
                            .foregroundColor(track.color)
                    }
                }

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text(track.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(track.color.opacity(0.7))
                }

                Spacer()

                // Play/Stop icon
                Image(systemName: currentlyPlaying == track.fileName ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(currentlyPlaying == track.fileName ? .red.opacity(0.8) : .white.opacity(0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(currentlyPlaying == track.fileName ? track.color.opacity(0.06) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(currentlyPlaying == track.fileName ? track.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Now Playing Bar
    private var nowPlayingBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 16) {
                // Animated bars
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(selectedCategory.color)
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
                    Text(currentTrackName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                // STOP BUTTON
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
    private func toggleTrack(_ track: CenteredTrack) {
        if currentlyPlaying == track.fileName {
            stopPlaying()
        } else {
            stopPlaying()
            // Music category loops, everything else plays once (sped up for meditations/pep talks)
            if selectedCategory == .music {
                audioPlayer.playBackgroundMusic(fileName: track.fileName)
            } else if selectedCategory == .meditations || selectedCategory == .pepTalks {
                audioPlayer.playVoice(fileName: track.fileName, rate: 1.15)
            } else {
                audioPlayer.playVoice(fileName: track.fileName)
            }
            currentlyPlaying = track.fileName
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

    private var currentTrackName: String {
        guard let fileName = currentlyPlaying else { return "" }
        let allTracks = AudioCategory.allCases.flatMap { tracks(for: $0) }
        return allTracks.first(where: { $0.fileName == fileName })?.name ?? fileName
    }

    // MARK: - Track Data (organized by category)
    private func tracks(for category: AudioCategory) -> [CenteredTrack] {
        switch category {
        case .music:
            return [
                CenteredTrack(name: "Ambient Night Lofi", fileName: "ambient-night-lofi-chill-beat-hip-hop-sleepy-lazy-cozy-149582", subtitle: "Chill & Relaxing", icon: "moon.stars.fill", color: Color(red: 0.4, green: 0.3, blue: 0.7)),
                CenteredTrack(name: "Calm River Lofi", fileName: "calm-river-lofi-background-music-for-videos-7289", subtitle: "Peaceful Background", icon: "water.waves", color: Color(red: 0.3, green: 0.6, blue: 0.7)),
                CenteredTrack(name: "Emotional Piano", fileName: "emotional-piano-background-297572", subtitle: "Deep & Reflective", icon: "pianokeys", color: Color(red: 0.5, green: 0.4, blue: 0.7)),
                CenteredTrack(name: "Smooth Evening Saxophone", fileName: "smooth-evening-saxophone-jazz-background-music-for-youtube-345557", subtitle: "Jazz & Smooth", icon: "music.mic", color: Color(red: 0.9, green: 0.6, blue: 0.3)),
                CenteredTrack(name: "Soft Jazz", fileName: "soft-jazz-more-on-httpsmirceaiancubandcampcom-336322", subtitle: "Mellow & Easy", icon: "music.note", color: Color(red: 0.7, green: 0.5, blue: 0.3)),
            ]
        case .meditations:
            return [
                CenteredTrack(name: "Cooling the Fire", fileName: "anger_management_meditation", subtitle: "Anger Management", icon: "flame.fill", color: .red),
                CenteredTrack(name: "The Quiet Place Within", fileName: "inner_peace_meditation", subtitle: "Inner Peace", icon: "leaf.fill", color: Color(red: 0.3, green: 0.7, blue: 0.5)),
                CenteredTrack(name: "Making Peace Within", fileName: "internal_conflict_meditation", subtitle: "Internal Conflict", icon: "arrow.triangle.branch", color: Color(red: 0.5, green: 0.5, blue: 0.8)),
                CenteredTrack(name: "Lay the Weight Down", fileName: "stress_release_meditation", subtitle: "Stress Release", icon: "cloud.rain.fill", color: Color(red: 0.4, green: 0.6, blue: 0.8)),
                CenteredTrack(name: "Restoring Your Energy", fileName: "rejuvenation_meditation_dh", subtitle: "With Dr. Hope", icon: "bolt.heart.fill", color: Color(red: 0.7, green: 0.4, blue: 0.8)),
                CenteredTrack(name: "Restoring Your Energy", fileName: "rejuvenation_meditation_mh", subtitle: "With Mr. Hope", icon: "bolt.heart.fill", color: Color(red: 0.3, green: 0.6, blue: 0.9)),
            ]
        case .pepTalks:
            return [
                CenteredTrack(name: "Feminine Energy Pep Talk", fileName: "feminine_energy_pep_talk", subtitle: "Empowerment & Confidence", icon: "sparkles", color: Color(red: 0.9, green: 0.5, blue: 0.7)),
                CenteredTrack(name: "Masculine Energy Pep Talk", fileName: "masculine_energy_pep_talk", subtitle: "Strength & Purpose", icon: "shield.fill", color: Color(red: 0.3, green: 0.5, blue: 0.9)),
            ]
        case .healing:
            return [
                CenteredTrack(name: "Breaking Free", fileName: "breaking_free_abusive_relationship", subtitle: "Abusive Relationship Recovery", icon: "link.badge.plus", color: Color(red: 0.8, green: 0.4, blue: 0.5)),
                CenteredTrack(name: "Reclaiming Your Heart", fileName: "overcoming_harmful_relationship", subtitle: "Harmful Relationship Recovery", icon: "heart.fill", color: Color(red: 0.7, green: 0.3, blue: 0.4)),
                CenteredTrack(name: "Returning Love to Yourself", fileName: "returning_love_to_yourself", subtitle: "Self-Love Journey", icon: "heart.circle.fill", color: Color(red: 0.9, green: 0.6, blue: 0.4)),
            ]
        case .closings:
            return [
                CenteredTrack(name: "Closing Prayer", fileName: "dr_hope_closing prayer", subtitle: "Dr. Hope's Prayer", icon: "hands.and.sparkles.fill", color: Color(red: 0.7, green: 0.4, blue: 0.8)),
                CenteredTrack(name: "Closing Message", fileName: "dr_hope_closing", subtitle: "Dr. Hope's Farewell", icon: "hand.wave.fill", color: Color(red: 0.6, green: 0.4, blue: 0.7)),
                CenteredTrack(name: "Journaling Guidance", fileName: "dr_hope_journing", subtitle: "Dr. Hope Guides Your Writing", icon: "pencil.and.scribble", color: Color(red: 0.5, green: 0.6, blue: 0.8)),
            ]
        }
    }
}

// MARK: - Track Model
struct CenteredTrack: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let subtitle: String
    let icon: String
    let color: Color
}
