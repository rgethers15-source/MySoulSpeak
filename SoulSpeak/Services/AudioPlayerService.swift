import Foundation
import AVFoundation

/// Audio player service for character voices, background jazz, and prayer audio.
@MainActor
class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: String = ""
    @Published var volume: Float = 0.7

    private var voicePlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?

    static let shared = AudioPlayerService()

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[SoulSpeak] Audio session setup failed: \(error)")
        }
    }

    // MARK: - Voice Playback

    /// Play a character voice file (dr_hope_intro, mr_hope_greeting, etc.)
    func playVoice(fileName: String, fileExtension: String = "mp3", rate: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("[SoulSpeak] Voice file not found: \(fileName).\(fileExtension) — continuing without audio")
            return
        }
        do {
            voicePlayer = try AVAudioPlayer(contentsOf: url)
            voicePlayer?.volume = volume
            voicePlayer?.enableRate = true
            voicePlayer?.rate = rate
            voicePlayer?.play()
            isPlaying = true
            currentTrack = fileName
        } catch {
            print("[SoulSpeak] Voice playback failed: \(error)")
        }
    }

    func stopVoice() {
        voicePlayer?.stop()
        isPlaying = false
        currentTrack = ""
    }

    // MARK: - Background Music (Jazz Loops)

    /// Play background jazz loop (jazz_loop_1, jazz_loop_2, jazz_loop_3)
    func playBackgroundMusic(fileName: String, fileExtension: String = "mp3") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("[SoulSpeak] Music file not found: \(fileName).\(fileExtension) — continuing without music")
            return
        }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.volume = volume * 0.3
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.play()
        } catch {
            print("[SoulSpeak] Music playback failed: \(error)")
        }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
    }

    // MARK: - Prayer Audio

    func playPrayer(fileName: String = "dr_hope_prayer", fileExtension: String = "mp3") {
        playVoice(fileName: fileName, fileExtension: fileExtension)
    }

    // MARK: - Master Controls

    func stopAll() {
        voicePlayer?.stop()
        musicPlayer?.stop()
        isPlaying = false
        currentTrack = ""
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        voicePlayer?.volume = newVolume
        musicPlayer?.volume = newVolume * 0.3
    }
}
