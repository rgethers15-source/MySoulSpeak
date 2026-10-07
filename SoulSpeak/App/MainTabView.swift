import SwiftUI

/// Main tab navigation: Journal, Talk, Vent Room, Mood, Analytics, Prayer, Settings.
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showConversation = false
    @State private var showVentRoom = false
    @State private var selectedCharacter: GeminiService.Character = .drHope
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @StateObject private var store = StoreKitService.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // Voice Journal tab
            NavigationStack {
                VoiceJournalView()
            }
            .tabItem {
                Image(systemName: "mic.fill")
                Text("Journal")
            }
            .tag(0)

            // Talk to Dr. Hope / Mr. Hope (Premium)
            NavigationStack {
                TalkTabView(
                    showConversation: $showConversation,
                    selectedCharacter: $selectedCharacter
                )
            }
            .tabItem {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("Talk")
            }
            .tag(1)

            // Vent Room (Premium)
            NavigationStack {
                VentRoomEntryView(showVentRoom: $showVentRoom)
            }
            .tabItem {
                Image(systemName: "flame.fill")
                Text("Vent")
            }
            .tag(2)

            // Mood Tracker tab
            NavigationStack {
                MoodTrackerView()
            }
            .tabItem {
                Image(systemName: "face.smiling.fill")
                Text("Mood")
            }
            .tag(3)

            // Analytics tab
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Analytics")
            }
            .tag(4)

            // Centered (meditation/soundscapes/bible)
            NavigationStack {
                CenteredView()
            }
            .tabItem {
                Image(systemName: "leaf.circle.fill")
                Text("Centered")
            }
            .tag(5)

            // Prayer/Outro tab
            NavigationStack {
                PrayerOutroView()
            }
            .tabItem {
                Image(systemName: "hands.and.sparkles.fill")
                Text("Prayer")
            }
            .tag(6)

            // Settings tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            .tag(7)
        }
        .tint(SSColors.primary)
        .onAppear {
            audioPlayer.playBackgroundMusic(fileName: "jazz_loop_2")
            // Make tab bar visible with solid background
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 0.95)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .fullScreenCover(isPresented: $showConversation) {
            ConversationView(character: selectedCharacter)
        }
        .fullScreenCover(isPresented: $showVentRoom) {
            VentRoomView()
        }
    }
}

// MARK: - Talk Tab View (Choose Dr. Hope or Mr. Hope)
struct TalkTabView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showConversation: Bool
    @Binding var selectedCharacter: GeminiService.Character
    @StateObject private var store = StoreKitService.shared
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.08, blue: 0.18),
                    Color(red: 0.14, green: 0.1, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                    .frame(height: 40)

                Text("Who would you like\nto talk to?")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("AI-powered conversations that listen and talk back")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                // Dr. Hope card
                characterCard(
                    character: .drHope,
                    imageName: "dr_hope",
                    subtitle: "Spiritual Therapist",
                    description: "Deep, healing conversations with Gullah wisdom",
                    color: Color(red: 0.7, green: 0.4, blue: 0.8)
                )

                // Mr. Hope card
                characterCard(
                    character: .mrHope,
                    imageName: "mr_hope",
                    subtitle: "Wellness Companion",
                    description: "Uplifting, motivational talks — hey Champ!",
                    color: Color(red: 0.3, green: 0.6, blue: 0.9)
                )

                Spacer()

                // Premium badge
                if !store.isPremium {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
                        Text("Premium Feature")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()
                    .frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Talk")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func characterCard(character: GeminiService.Character, imageName: String, subtitle: String, description: String, color: Color) -> some View {
        Button(action: {
            if store.isPremium {
                selectedCharacter = character
                showConversation = true
            } else {
                showPaywall = true
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
}

// MARK: - Vent Room Entry View
struct VentRoomEntryView: View {
    @Binding var showVentRoom: Bool
    @StateObject private var store = StoreKitService.shared
    @State private var showPaywall = false
    @State private var flameGlow = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.05),
                    Color(red: 0.15, green: 0.08, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Flame icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.4, blue: 0.1).opacity(flameGlow ? 0.2 : 0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(flameGlow ? 1.15 : 1.0)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.1))
                }

                Text("The Vent Room")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Text("Record your frustrations.\nBurn them to ash.\nDestroy the room.\nThen release it all.")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()

                // Enter button
                Button(action: {
                    if store.isPremium {
                        showVentRoom = true
                    } else {
                        showPaywall = true
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                        Text("Enter the Room")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 44)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.9, green: 0.4, blue: 0.1), Color(red: 0.7, green: 0.25, blue: 0.05)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(red: 0.9, green: 0.4, blue: 0.1).opacity(0.4), radius: 10, y: 4)
                    )
                }

                if !store.isPremium {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
                        Text("Premium Feature")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 8)
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Vent Room")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                flameGlow = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
