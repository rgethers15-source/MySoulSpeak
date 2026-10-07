import Foundation
import Speech
import AVFoundation

/// Real-time speech-to-text transcription service using Apple's Speech framework.
@MainActor
class SpeechRecognitionService: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }

    /// Start live transcription from the microphone.
    func startTranscribing() {
        guard authorizationStatus == .authorized else {
            requestAuthorization()
            return
        }

        // Cancel any existing task
        stopTranscribing()

        // Set up audio session first
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[SoulSpeak] Audio session setup failed: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        let inputNode = audioEngine.inputNode

        // Use the NATIVE format of the input node — don't override it
        // This avoids "isFormatSampleRateAndChannelCountValid" crashes on device
        let nativeFormat = inputNode.inputFormat(forBus: 0)

        // Install tap using native format
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || (result?.isFinal == true) {
                    self?.stopAudioEngine()
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isTranscribing = true
            transcribedText = ""
        } catch {
            print("[SoulSpeak] Audio engine failed to start: \(error)")
            stopAudioEngine()
        }
    }

    /// Stop transcription.
    func stopTranscribing() {
        stopAudioEngine()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        isTranscribing = false
    }

    /// Transcribe an already-recorded audio file (post-recording transcription).
    func transcribeAudioFile(url: URL) {
        guard authorizationStatus == .authorized else {
            requestAuthorization()
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true

        isTranscribing = true

        speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result = result, result.isFinal {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                if error != nil {
                    print("[SoulSpeak] Transcription error: \(error!)")
                }
                self?.isTranscribing = false
            }
        }
    }
}
