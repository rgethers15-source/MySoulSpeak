import SwiftUI

/// Main Hub — Beautiful lobby room as the home screen.
/// After the intro video, this is what the user sees.
/// Icons overlay on the room image. Tapping each opens its door scene.
///
/// Image needed: "main_lobby" in Assets.xcassets
/// (The warm office room with brick walls, books, plants, leather chair)
struct MainHubView: View {
    @State private var showJournal = false
    @State private var showVent = false
    @State private var showCentered = false
    @State private var showMood = false
    @State private var showMirror = false
    @State private var showAccountability = false
    @State private var showPrescription = false
    @State private var showBibleStudy = false
    @State private var showEmergency = false
    @State private var showSettings = false
    @State private var showCharacterPicker = false
    @State private var showConversation = false
    @State private var selectedCharacter: GeminiService.Character = .drHope
    @State private var pulseGlow = false

    var body: some View {
        ZStack {
            // Beautiful lobby background (full screen)
            Image("main_lobby")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Stronger dark overlay for better icon visibility
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Content overlay
            VStack {
                // Top bar: Settings (left) + Emergency (right)
                HStack {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Button(action: { showEmergency = true }) {
                        Image(systemName: "sos.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                            .shadow(color: .red.opacity(0.6), radius: 10)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)

                Spacer()

                // Main navigation icons
                VStack(spacing: 22) {
                    // Row 1: Journal, Talk, Vent
                    HStack(spacing: 26) {
                        hubIcon(
                            name: "Journal",
                            icon: "mic.fill",
                            color: Color(red: 0.8, green: 0.4, blue: 0.9),
                            action: { showJournal = true }
                        )

                        hubIcon(
                            name: "Talk",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: Color(red: 0.3, green: 0.6, blue: 1.0),
                            action: { showCharacterPicker = true }
                        )

                        hubIcon(
                            name: "Vent",
                            icon: "flame.fill",
                            color: Color(red: 1.0, green: 0.4, blue: 0.15),
                            action: { showVent = true }
                        )
                    }

                    // Row 2: Centered, Mirror, Mood
                    HStack(spacing: 26) {
                        hubIcon(
                            name: "Centered",
                            icon: "leaf.circle.fill",
                            color: Color(red: 0.3, green: 0.85, blue: 0.5),
                            action: { showCentered = true }
                        )

                        hubIcon(
                            name: "Mirror",
                            icon: "person.crop.circle",
                            color: Color(red: 0.85, green: 0.75, blue: 1.0),
                            action: { showMirror = true }
                        )

                        hubIcon(
                            name: "Mood",
                            icon: "face.smiling.fill",
                            color: Color(red: 1.0, green: 0.75, blue: 0.2),
                            action: { showMood = true }
                        )
                    }

                    // Row 3: Accountability, Prescriptions, Bible
                    HStack(spacing: 26) {
                        hubIcon(
                            name: "Accountability",
                            icon: "calendar.badge.clock",
                            color: Color(red: 0.3, green: 0.7, blue: 0.9),
                            action: { showAccountability = true }
                        )

                        hubIcon(
                            name: "Prescriptions",
                            icon: "pill.fill",
                            color: Color(red: 0.4, green: 0.8, blue: 0.6),
                            action: { showPrescription = true }
                        )

                        hubIcon(
                            name: "Bible",
                            icon: "book.fill",
                            color: Color(red: 0.85, green: 0.65, blue: 0.2),
                            action: { showBibleStudy = true }
                        )
                    }
                }
                .padding(.bottom, 70)
            }

            // MARK: - Character Picker Overlay
            if showCharacterPicker {
                characterPickerOverlay
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
        .fullScreenCover(isPresented: $showJournal) {
            TutorialGateView(tutorial: .journal) {
                NavigationStack { VoiceJournalView() }
            }
        }
        .fullScreenCover(isPresented: $showConversation) {
            ConversationView(character: selectedCharacter)
        }
        .fullScreenCover(isPresented: $showVent) {
            TutorialGateView(tutorial: .vent) {
                VentRoomView()
            }
        }
        .fullScreenCover(isPresented: $showCentered) {
            TutorialGateView(tutorial: .centered) {
                NavigationStack { CenteredView() }
            }
        }
        .fullScreenCover(isPresented: $showMirror) {
            TutorialGateView(tutorial: .mirror) {
                NavigationStack { MirrorView() }
            }
        }
        .fullScreenCover(isPresented: $showMood) {
            TutorialGateView(tutorial: .mood) {
                NavigationStack { MoodTrackerView() }
            }
        }
        .fullScreenCover(isPresented: $showAccountability) {
            TutorialGateView(tutorial: .accountability) {
                NavigationStack { AccountabilityCalendarView() }
            }
        }
        .fullScreenCover(isPresented: $showPrescription) {
            TutorialGateView(tutorial: .prescriptions) {
                NavigationStack { PrescriptionTrackerView() }
            }
        }
        .fullScreenCover(isPresented: $showBibleStudy) {
            NavigationStack { BibleStudyView() }
        }
        .fullScreenCover(isPresented: $showEmergency) {
            EmergencyView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
    }

    // MARK: - Character Picker (inline overlay — no nested fullScreenCover)
    private var characterPickerOverlay: some View {
        ZStack {
            // Fully opaque background — nothing shows through
            Color.black
                .ignoresSafeArea()

            // Gradient on top for style
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.08, blue: 0.18),
                    Color(red: 0.14, green: 0.1, blue: 0.22),
                    Color(red: 0.08, green: 0.06, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showCharacterPicker = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 24)
                }

                Spacer()

                Text("Who would you like\nto talk to?")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("AI-powered conversations that listen and talk back")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                // Dr. Hope card
                characterPickerCard(
                    character: .drHope,
                    imageName: "dr_hope",
                    subtitle: "Spiritual Therapist",
                    description: "Deep, healing conversations with Gullah wisdom",
                    color: Color(red: 0.7, green: 0.4, blue: 0.8)
                )

                // Mr. Hope card
                characterPickerCard(
                    character: .mrHope,
                    imageName: "mr_hope",
                    subtitle: "Wellness Companion",
                    description: "Uplifting, motivational talks — hey Champ!",
                    color: Color(red: 0.3, green: 0.6, blue: 0.9)
                )

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
        }
        .transition(.opacity)
    }

    private func characterPickerCard(character: GeminiService.Character, imageName: String, subtitle: String, description: String, color: Color) -> some View {
        Button(action: {
            selectedCharacter = character
            withAnimation(.easeOut(duration: 0.2)) {
                showCharacterPicker = false
            }
            // Small delay so the overlay dismisses before presenting fullScreenCover
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConversation = true
            }
        }) {
            HStack(spacing: 16) {
                // Avatar
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: color.opacity(0.3), radius: 6)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color.opacity(0.8))

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Hub Icon (larger, more vibrant, dark solid background)
    private func hubIcon(name: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Dark solid circle background for contrast
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 74, height: 74)

                    // Colored ring
                    Circle()
                        .stroke(color, lineWidth: 3)
                        .frame(width: 74, height: 74)
                        .shadow(color: color.opacity(pulseGlow ? 0.7 : 0.3), radius: 10)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3)
            }
        }
    }
}
