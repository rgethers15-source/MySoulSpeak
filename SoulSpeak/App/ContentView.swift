import SwiftUI
import SwiftData
import CoreLocation
import UserNotifications
import AVFAudio

/// Root content view — app flow:
/// 1. DisclaimerView — mandatory every launch
/// 2. SignInView — Sign in with Apple (one time, stays logged in)
/// 3. Permission requests (location, notifications, mic)
/// 4. IntroSequenceView — plays once
/// 5. MainHubView — the main app experience
struct ContentView: View {
    @State private var hasAgreedToDisclaimer = false
    @StateObject private var auth = AuthService.shared
    @AppStorage("hasSeenIntroV3") private var hasSeenIntro = false
    @State private var introComplete = false
    @State private var permissionsRequested = false
    @Query private var settings: [UserSettings]

    var body: some View {
        ZStack {
            // Main content flow
            if hasAgreedToDisclaimer && auth.isSignedIn {
                if !introComplete && !hasSeenIntro {
                    IntroSequenceView(introComplete: $introComplete)
                        .transition(.opacity)
                        .onChange(of: introComplete) { _, newValue in
                            if newValue {
                                hasSeenIntro = true
                            }
                        }
                } else {
                    MainHubView()
                        .transition(.opacity)
                }
            }

            // Sign-in screen (after disclaimer, before content)
            if hasAgreedToDisclaimer && !auth.isSignedIn {
                SignInView()
                    .transition(.opacity)
                    .zIndex(998)
            }

            // Disclaimer overlay — BLOCKS EVERYTHING if not agreed
            if !hasAgreedToDisclaimer {
                DisclaimerView(hasAgreed: $hasAgreedToDisclaimer)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: hasAgreedToDisclaimer)
        .animation(.easeInOut(duration: 0.5), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.5), value: introComplete)
        .onAppear {
            if hasSeenIntro {
                introComplete = true
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: hasAgreedToDisclaimer) { _, agreed in
            if agreed && auth.isSignedIn && !permissionsRequested {
                permissionsRequested = true
                requestAllPermissions()
            }
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn && hasAgreedToDisclaimer && !permissionsRequested {
                permissionsRequested = true
                requestAllPermissions()
            }
        }
        .preferredColorScheme(settings.first?.isDarkMode == true ? .dark : .light)
    }

    // MARK: - Request All Permissions
    private func requestAllPermissions() {
        // 1. Notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("[SoulSpeak] Notifications permission: \(granted)")
        }

        // 2. Location (for Emergency feature + resource finder)
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        print("[SoulSpeak] Location permission requested")

        // 3. Microphone (for voice journal + speech recognition)
        AVAudioApplication.requestRecordPermission { granted in
            print("[SoulSpeak] Microphone permission: \(granted)")
        }
    }
}
