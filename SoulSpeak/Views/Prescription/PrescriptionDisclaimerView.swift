import SwiftUI

/// PrescriptionDisclaimerView — Health disclaimer for the Prescription Tracker.
/// Must be accepted before using the medication features.
/// Protects against liability for medication-related features.
struct PrescriptionDisclaimerView: View {
    @Binding var hasAccepted: Bool
    @State private var checkbox1 = false
    @State private var checkbox2 = false
    @State private var checkbox3 = false
    @State private var showError = false

    private var allChecked: Bool {
        checkbox1 && checkbox2 && checkbox3
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.08)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                        Text("Health Disclaimer")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)

                        Text("Please read before using the Prescription Tracker")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Disclaimer content
                    VStack(alignment: .leading, spacing: 14) {
                        disclaimerItem(
                            title: "Not Medical Advice",
                            text: "The Prescription Tracker and Taylor Hope AI are for INFORMATIONAL and ORGANIZATIONAL purposes only. They do NOT provide medical advice, diagnoses, or treatment recommendations."
                        )

                        disclaimerItem(
                            title: "Not a Replacement for Healthcare Providers",
                            text: "Taylor Hope is a fictional AI character, NOT a real nurse, psychiatrist, or medical professional. Always consult your actual prescribing doctor or pharmacist for medical decisions."
                        )

                        disclaimerItem(
                            title: "Medication Responsibility",
                            text: "YOU are solely responsible for taking your medications as prescribed by your healthcare provider. This app is a convenience tool for reminders and tracking only."
                        )

                        disclaimerItem(
                            title: "No Liability",
                            text: "MySoulSpeak, its creators, and operators shall NOT be held liable for any adverse health effects, missed medications, incorrect dosages, or any harm resulting from use of this feature."
                        )

                        disclaimerItem(
                            title: "Emergency Situations",
                            text: "If you experience a medical emergency, adverse drug reaction, or overdose, call 911 immediately. Do NOT rely on this app for emergency medical guidance."
                        )

                        disclaimerItem(
                            title: "Data Accuracy",
                            text: "Medication information provided by the AI may not always be current or complete. Drug information changes frequently. Always verify with your pharmacist or physician."
                        )
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.04))
                    )

                    // Checkboxes
                    VStack(spacing: 14) {
                        checkboxRow(isChecked: $checkbox1, text: "I understand that Taylor Hope is a fictional AI and NOT a real medical professional.")
                        checkboxRow(isChecked: $checkbox2, text: "I will always consult my real doctor or pharmacist for medical decisions and will NOT rely solely on this app.")
                        checkboxRow(isChecked: $checkbox3, text: "I accept full responsibility for my medication management and will call 911 in any emergency.")
                    }

                    if showError {
                        Text("Please check all three boxes to continue")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }

                    // Accept button
                    Button(action: accept) {
                        Text(allChecked ? "I Understand — Continue" : "Check All Boxes to Continue")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(allChecked ? .white : .white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(allChecked
                                          ? Color(red: 0.4, green: 0.8, blue: 0.6)
                                          : Color.white.opacity(0.06))
                            )
                    }
                    .disabled(!allChecked)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func disclaimerItem(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .frame(width: 5, height: 5)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(2)
        }
    }

    private func checkboxRow(isChecked: Binding<Bool>, text: String) -> some View {
        Button(action: {
            isChecked.wrappedValue.toggle()
            showError = false
        }) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isChecked.wrappedValue ? Color.green : Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isChecked.wrappedValue {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.green)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func accept() {
        if allChecked {
            hasAccepted = true
        } else {
            showError = true
        }
    }
}
