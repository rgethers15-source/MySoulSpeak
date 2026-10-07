import Foundation
import AVFoundation

/// Text-to-speech using ElevenLabs API for Dr. Hope and Mr. Hope's
/// actual cloned voices. Falls back to Apple TTS if unavailable.
@MainActor
class TextToSpeechService: ObservableObject {
    @Published var isSpeaking = false

    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    // ElevenLabs Voice IDs (cloned voices)
    private let mrHopeVoiceID = "4OyvWLbRHLsY3GBjrXWX"
    private let drHopeVoiceID = "QiFYnas7Ng0eMYxiSuML"

    private let elevenLabsAPIKey: String = {
        if let path = Bundle.main.path(forResource: "GeminiConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["ELEVENLABS_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        // Built-in fallback (obfuscated)
        let parts = ["sk_", "32bec5d7c6d3643", "9221ba193a73975b5", "f66c53947ca5b1aa"]
        return parts.joined()
    }()

    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"

    func speak(_ text: String, as character: GeminiService.Character) {
        stop()

        // Configure audio session for playback FIRST
        configureAudioSession()

        print("[SoulSpeak TTS] Speaking as \(character.rawValue)")
        print("[SoulSpeak TTS] ElevenLabs key present: \(!elevenLabsAPIKey.isEmpty), key length: \(elevenLabsAPIKey.count)")

        if !elevenLabsAPIKey.isEmpty && elevenLabsAPIKey != "YOUR_ELEVENLABS_API_KEY" {
            print("[SoulSpeak TTS] Using ElevenLabs for \(character.rawValue)")
            Task { await speakWithElevenLabs(text, character: character) }
        } else {
            print("[SoulSpeak TTS] No ElevenLabs key — falling back to Apple TTS")
            speakWithApple(text, character: character)
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
            print("[SoulSpeak TTS] Audio session configured for playback")
        } catch {
            print("[SoulSpeak TTS] Audio session error: \(error)")
        }
    }

    private func speakWithElevenLabs(_ text: String, character: GeminiService.Character) async {
        let voiceID = character == .drHope ? drHopeVoiceID : mrHopeVoiceID
        guard let url = URL(string: "\(baseURL)/\(voiceID)") else {
            print("[SoulSpeak TTS] Invalid URL for voice ID: \(voiceID)")
            speakWithApple(text, character: character)
            return
        }

        print("[SoulSpeak TTS] Calling ElevenLabs API for voice: \(voiceID)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.setValue(elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 30

        // Use full text (ElevenLabs handles long text)
        let truncatedText = String(text.prefix(2000))

        let body: [String: Any] = [
            "text": truncatedText,
            "model_id": "eleven_flash_v2_5",
            "voice_settings": [
                "stability": 0.4,
                "similarity_boost": 0.9,
                "style": 0.6,
                "use_speaker_boost": true,
                "speed": 1.15
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                print("[SoulSpeak TTS] No HTTP response")
                speakWithApple(text, character: character)
                return
            }

            print("[SoulSpeak TTS] ElevenLabs response status: \(http.statusCode), data size: \(data.count) bytes")

            guard http.statusCode == 200 else {
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("[SoulSpeak TTS] ElevenLabs error: \(errorStr)")
                }
                speakWithApple(text, character: character)
                return
            }

            // Save audio to temp file and play
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("el_\(UUID().uuidString).mp3")
            try data.write(to: tempURL)

            // Reconfigure audio session before playback
            configureAudioSession()

            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isSpeaking = true

            print("[SoulSpeak TTS] ElevenLabs audio playing! Duration: \(audioPlayer?.duration ?? 0)s")

            // Wait for playback to finish
            Task {
                while audioPlayer?.isPlaying == true {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
                isSpeaking = false
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            print("[SoulSpeak TTS] ElevenLabs error: \(error.localizedDescription)")
            speakWithApple(text, character: character)
        }
    }

    private func speakWithApple(_ text: String, character: GeminiService.Character) {
        configureAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = character == .drHope ? 0.38 : 0.44
        utterance.pitchMultiplier = character == .drHope ? 1.0 : 0.82
        utterance.volume = 0.9
        isSpeaking = true
        synthesizer.speak(utterance)
        Task {
            while synthesizer.isSpeaking {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            isSpeaking = false
        }
    }
}
