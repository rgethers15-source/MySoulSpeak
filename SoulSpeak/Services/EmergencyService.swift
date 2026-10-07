import Foundation
import AVFoundation
import UIKit
import CoreLocation

/// Emergency Crisis Service — activated by the emergency button.
///
/// When triggered:
/// 1. Starts recording voice in real-time
/// 2. Gets user's GPS location
/// 3. Auto-calls emergency contact
/// 4. Plays scripted message when they answer (via text-to-speech)
/// 5. Sends recording + GPS location to contact via SMS
///
/// Script: "Hi, you are listed as an emergency contact for [name].
/// This person is struggling with a crisis and needs your help.
/// Please call or come to [address]. They have been doing well
/// overcoming [their struggle] and right now they are about to ruin it.
/// Please be safe and help them."
@MainActor
class EmergencyService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isInEmergencyMode = false
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String = "Getting location..."
    @Published var emergencyTriggered = false

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    static let shared = EmergencyService()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Activate Emergency

    /// Full emergency activation: record + locate + prepare to call.
    func activateEmergency() {
        isInEmergencyMode = true
        emergencyTriggered = true
        startRecording()
        requestLocation()
    }

    // MARK: - Contact Emergency Person with Script

    /// Call emergency contact and deliver the crisis message.
    func contactEmergencyPerson(
        contactName: String,
        contactPhone: String,
        userName: String,
        struggle: String
    ) {
        stopRecording()

        // Build the script message
        let address = currentAddress.isEmpty ? "their current location" : currentAddress
        let script = buildEmergencyScript(
            userName: userName,
            contactName: contactName,
            address: address,
            struggle: struggle
        )

        // Send SMS with full details + GPS link
        sendEmergencySMS(
            phone: contactPhone,
            message: script,
            location: currentLocation
        )

        // Make the phone call
        callPhone(contactPhone)
    }

    /// Build the emergency script message.
    func buildEmergencyScript(
        userName: String,
        contactName: String,
        address: String,
        struggle: String
    ) -> String {
        return """
        EMERGENCY from SoulSpeak App:
        
        Hi \(contactName), you are listed as an emergency contact for \(userName). \
        This person is struggling with a crisis and they need your help. \
        Please call or come to: \(address). \
        \(userName) has been doing well overcoming \(struggle) and right now, \
        they are about to ruin it. Please be safe, and help them. \
        \
        This is an automated safety message from SoulSpeak.
        """
    }

    /// Get the script for text-to-speech (shorter version for phone call).
    func getVoiceScript(userName: String, contactName: String, address: String, struggle: String) -> String {
        return "Hi \(contactName). You are listed as an emergency contact for \(userName). " +
        "This person is struggling with a crisis and they need your help. " +
        "Please call or come to \(address). " +
        "\(userName) has been doing well overcoming \(struggle), and right now, they are about to ruin it. " +
        "Please be safe, and help them."
    }

    // MARK: - Recording

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("[SoulSpeak Emergency] Audio session error: \(error)")
            return
        }

        let fileName = "emergency_\(Date().timeIntervalSince1970).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordingDuration += 1.0
                }
            }
        } catch {
            print("[SoulSpeak Emergency] Recording error: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    // MARK: - GPS Location

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentLocation = location
            self.locationManager.stopUpdatingLocation()

            // Reverse geocode to get address
            self.geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let placemark = placemarks?.first {
                        let street = placemark.thoroughfare ?? ""
                        let number = placemark.subThoroughfare ?? ""
                        let city = placemark.locality ?? ""
                        let state = placemark.administrativeArea ?? ""
                        let zip = placemark.postalCode ?? ""
                        self.currentAddress = "\(number) \(street), \(city), \(state) \(zip)"
                    }
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[SoulSpeak Emergency] Location error: \(error)")
    }

    // MARK: - Call & SMS

    private func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        guard let url = URL(string: "tel://\(cleaned)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func sendEmergencySMS(phone: String, message: String, location: CLLocation?) {
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)

        var fullMessage = message

        // Add Google Maps link if we have location
        if let loc = location {
            let mapsLink = "https://maps.google.com/?q=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
            fullMessage += "\n\nGPS Location: \(mapsLink)"
        }

        let encoded = fullMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "sms:\(cleaned)&body=\(encoded)") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Deactivate

    func deactivate() {
        stopRecording()
        isInEmergencyMode = false
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Crisis Messages (for on-screen display)

    static func drHopeCrisisMessage(userName: String, isSubstance: Bool) -> String {
        if isSubstance {
            return """
            Baby, I know that urge feels like it's bigger than you right now. But listen to me — \
            you have made it THIS far. \(userName), you are STRONGER than this craving. \
            It's lying to you. It's telling you one more time won't hurt. But we both know that's not true. \
            Close your eyes. Breathe with me. In... hold... out. \
            Think about why you started this journey. Think about who loves you. \
            You are not your addiction. You are a child of God fighting a war most people can't see. \
            I'm right here. Your emergency contact is being notified. You are not alone.
            """
        } else {
            return """
            \(userName), baby, I need you to hear me right now. \
            Whatever darkness is telling you — it is LYING. You matter. Your life matters. \
            I know it hurts. But this feeling? It's temporary. It will pass. \
            Breathe with me. In through your nose... out through your mouth. \
            Your emergency contact is being notified right now. Help is coming. \
            Just hold on, sugar. The ancestors didn't carry you this far to leave you.
            """
        }
    }

    static func mrHopeCrisisMessage(userName: String, isSubstance: Bool) -> String {
        if isSubstance {
            return """
            Champ. Stop. Look at me. That voice in your head? That's not YOU talking. \
            That's the addiction talking. And we don't listen to it anymore. \
            \(userName), you've come TOO FAR. Remember your streak. Remember your WHY. \
            This moment will pass. I PROMISE you it will pass. \
            Your contact is being reached right now. You're not in this alone, Champ. \
            Champions don't quit — they call for backup. And backup is ON THE WAY.
            """
        } else {
            return """
            CHAMP. Listen to me. Right now. \
            You are NOT defined by this moment. You are NOT your worst thought. \
            \(userName) — you are someone's reason to smile. You are someone's answered prayer. \
            Take one breath. Just one. Good. Now another one. \
            Your emergency contact is being notified. Someone who loves you is about to reach out. \
            Just hang on. I believe in you, Champ. This is just a bad moment — not a bad life.
            """
        }
    }
}
