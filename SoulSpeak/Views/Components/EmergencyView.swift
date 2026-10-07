import SwiftUI
import SwiftData

/// Emergency Crisis Screen — activated by the emergency button.
/// Shows Dr. Hope or Mr. Hope crisis talk-down message,
/// auto-records, and contacts emergency person.
struct EmergencyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @ObservedObject private var emergency = EmergencyService.shared
    @State private var selectedHelper: GeminiService.Character = .drHope
    @State private var showMessage = false
    @State private var breatheIn = false
    @State private var pulseRed = false
    @State private var contactSent = false
    @State private var showEditContact = false
    @State private var editName = ""
    @State private var editPhone = ""
    @State private var editRelationship = ""
    @State private var showConfirmSMS = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.02, blue: 0.02)
                .ignoresSafeArea()

            // Pulsing red border (urgency)
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.red.opacity(pulseRed ? 0.4 : 0.1), lineWidth: 4)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Recording indicator
                    if emergency.isRecording {
                        recordingBanner
                    }

                    // Character selector
                    characterSelector

                    // Crisis message
                    if showMessage {
                        crisisMessageCard
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Breathing exercise
                    breathingSection

                    // Contact emergency button
                    if !contactSent {
                        contactButton
                    } else {
                        contactSentConfirmation
                    }

                    // Edit emergency contact
                    editContactSection

                    // Crisis hotlines
                    hotlinesSection

                    // Exit button
                    exitButton

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            emergency.activateEmergency()
            startAnimations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showMessage = true
                }
            }
        }
    }


    // MARK: - Recording Banner
    private var recordingBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
            Text("Recording — your words are safe")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(formatTime(emergency.recordingDuration))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.1)))
    }

    // MARK: - Character Selector
    private var characterSelector: some View {
        VStack(spacing: 12) {
            Text("Who do you need right now?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 20) {
                characterOption(.drHope, name: "Dr. Hope", image: "dr_hope")
                characterOption(.mrHope, name: "Mr. Hope", image: "mr_hope")
            }
        }
    }

    private func characterOption(_ character: GeminiService.Character, name: String, image: String) -> some View {
        Button(action: { selectedHelper = character; showMessage = true }) {
            VStack(spacing: 8) {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(selectedHelper == character ? Color.white : Color.clear, lineWidth: 2))
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Crisis Message
    private var crisisMessageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(selectedHelper == .drHope ? "dr_hope" : "mr_hope")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                Text(selectedHelper.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(crisisMessage)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(5)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    // MARK: - Breathing
    private var breathingSection: some View {
        VStack(spacing: 12) {
            Text(breatheIn ? "Breathe in..." : "Breathe out...")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.7))

            Circle()
                .fill(Color(red: 0.3, green: 0.6, blue: 0.8).opacity(0.3))
                .frame(width: breatheIn ? 120 : 60, height: breatheIn ? 120 : 60)
                .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breatheIn)
        }
    }

    // MARK: - Contact Button
    private var contactButton: some View {
        Button(action: sendToEmergencyContact) {
            HStack(spacing: 10) {
                Image(systemName: "phone.arrow.up.right.fill")
                    .font(.system(size: 18))
                Text("Contact \(profile?.emergencyContactName ?? "Emergency Contact")")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red)
                    .shadow(color: .red.opacity(0.4), radius: 8, y: 4)
            )
        }
    }

    private var contactSentConfirmation: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            Text("Emergency contact notified")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1)))
    }

    // MARK: - Hotlines
    private var hotlinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Crisis Hotlines")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
            hotlineRow("988 Suicide & Crisis", "988")
            hotlineRow("Crisis Text Line", "741741")
            hotlineRow("SAMHSA", "1-800-662-4357")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }

    private func hotlineRow(_ name: String, _ number: String) -> some View {
        HStack {
            Text(name).font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
            Spacer()
            Link(number, destination: URL(string: "tel://\(number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression))")!)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.red)
        }
    }

    // MARK: - Exit
    private var exitButton: some View {
        Button(action: { dismiss() }) {
            Text("I'm okay now")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        }
    }

    // MARK: - Edit Emergency Contact Section
    private var editContactSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                editName = profile?.emergencyContactName ?? ""
                editPhone = profile?.emergencyContactPhone ?? ""
                withAnimation { showEditContact.toggle() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16))
                    Text(profile?.emergencyContactName.isEmpty == false ? "Edit Emergency Contact" : "Set Up Emergency Contact")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.vertical, 10)
            }

            // Current contact info display
            if let p = profile, !p.emergencyContactName.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.4))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.emergencyContactName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(p.emergencyContactPhone)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            }

            // Edit form (expandable)
            if showEditContact {
                VStack(spacing: 12) {
                    TextField("Contact Name", text: $editName)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    TextField("Phone Number", text: $editPhone)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .keyboardType(.phonePad)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    TextField("Relationship (e.g. Mother, Best Friend)", text: $editRelationship)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    // Save & Notify button
                    Button(action: saveAndNotifyContact) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Save & Notify This Person")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(editName.isEmpty || editPhone.isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.3, green: 0.7, blue: 0.5))
                        )
                    }
                    .disabled(editName.isEmpty || editPhone.isEmpty)

                    Text("A text will be sent to let them know you've chosen them as your emergency contact.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Save Contact & Send Introduction SMS
    private func saveAndNotifyContact() {
        // Save to profile
        if let p = profile {
            p.emergencyContactName = editName
            p.emergencyContactPhone = editPhone
        } else {
            let newProfile = UserProfile(
                name: "",
                preferredName: "",
                emergencyContactName: editName,
                emergencyContactPhone: editPhone
            )
            modelContext.insert(newProfile)
        }

        // Send introduction SMS to the emergency contact
        sendIntroductionSMS()

        withAnimation {
            showEditContact = false
        }
    }

    private func sendIntroductionSMS() {
        let userName = profile?.preferredName.isEmpty == false ? profile!.preferredName : (profile?.name ?? "Someone")
        let relationship = editRelationship.isEmpty ? "their loved one" : editRelationship
        let contactName = editName

        let message = """
        Hi \(contactName),

        \(userName) has chosen you as their Emergency Contact on the MySoulSpeak app — a mental wellness and spiritual health application.

        What this means: If \(userName) ever feels overwhelmed, in crisis, or needs support, the app may reach out to you on their behalf with their location and a message asking for help.

        This is a sign of TRUST and COURAGE. \(userName) is taking real steps to manage their mental health and live a healthier life. Your role is simple: be there. Be open-minded. Be encouraging.

        Here's how you can help:
        • If you receive an emergency alert, respond with compassion — not judgment
        • Check in on \(userName) regularly
        • Encourage their progress — they chose accountability over silence

        Thank you for being someone \(userName) trusts. That matters more than you know.

        — The MySoulSpeak Team
        (This is an automated message from the MySoulSpeak wellness app)
        """

        let cleaned = editPhone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:\(cleaned)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers
    private var crisisMessage: String {
        let name = profile?.preferredName ?? profile?.name ?? "friend"
        let isSubstance = profile?.isInRecovery ?? false
        switch selectedHelper {
        case .drHope:
            return EmergencyService.drHopeCrisisMessage(userName: name, isSubstance: isSubstance)
        case .mrHope:
            return EmergencyService.mrHopeCrisisMessage(userName: name, isSubstance: isSubstance)
        }
    }

    private func sendToEmergencyContact() {
        guard let p = profile else { return }
        let struggle = p.isInRecovery ? (p.substanceType ?? "their struggle") : "their personal challenges"
        emergency.contactEmergencyPerson(
            contactName: p.emergencyContactName,
            contactPhone: p.emergencyContactPhone,
            userName: p.preferredName.isEmpty ? p.name : p.preferredName,
            struggle: struggle
        )
        withAnimation { contactSent = true }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulseRed = true }
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { breatheIn = true }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
