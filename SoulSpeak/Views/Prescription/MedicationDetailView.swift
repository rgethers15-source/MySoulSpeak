import SwiftUI
import SwiftData
import AVFoundation

/// MedicationDetailView — Add or edit a medication.
/// Features: manual entry, barcode scanner, dosage/frequency picker,
/// pill count, pharmacy link, reminder setup.
struct MedicationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taylor = TaylorService.shared

    var existingMedication: Medication?

    @State private var name: String = ""
    @State private var genericName: String = ""
    @State private var dosage: String = ""
    @State private var form: MedicationForm = .tablet
    @State private var frequency: MedicationFrequency = .once_daily
    @State private var pillCount: Int = 30
    @State private var pillsPerDose: Int = 1
    @State private var purpose: String = ""
    @State private var instructions: String = ""
    @State private var prescribedBy: String = ""
    @State private var rxNumber: String = ""
    @State private var pharmacyName: String = ""
    @State private var pharmacyPhone: String = ""
    @State private var remindersEnabled: Bool = true
    @State private var selectedColor: String = "blue"
    @State private var showScanner = false
    @State private var showAskTaylor = false

    private var isEditing: Bool { existingMedication != nil }

    init() { self.existingMedication = nil }
    init(existingMedication: Medication) { self.existingMedication = existingMedication }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Medication name
                        nameSection

                        // Dosage & Form
                        dosageSection

                        // Frequency
                        frequencySection

                        // Pill count
                        pillCountSection

                        // Purpose & Instructions
                        detailsSection

                        // Pharmacy info
                        pharmacySection

                        // Reminders
                        reminderSection

                        // Color picker
                        colorSection

                        // Ask Taylor about this medication
                        askTaylorButton

                        // Delete (if editing)
                        if isEditing {
                            deleteButton
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") { saveMedication() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(name.isEmpty ? .white.opacity(0.3) : Color(red: 0.4, green: 0.8, blue: 0.6))
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .sheet(isPresented: $showAskTaylor) {
                TaylorChatView(medications: existingMedication != nil ? [existingMedication!] : [])
            }
        }
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medication Name")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack {
                TextField("e.g. Sertraline, Lisinopril...", text: $name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                // Scan barcode button
                Button(action: { showScanner = true }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            TextField("Generic name (optional)", text: $genericName)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.04))
                )
        }
    }

    // MARK: - Dosage & Form
    private var dosageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dosage & Form")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 12) {
                TextField("e.g. 50mg", text: $dosage)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    .frame(maxWidth: 120)

                // Form picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MedicationForm.allCases) { f in
                            Button(action: { form = f }) {
                                VStack(spacing: 4) {
                                    Image(systemName: f.icon)
                                        .font(.system(size: 14))
                                    Text(f.displayName)
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundColor(form == f ? .white : .white.opacity(0.4))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(form == f ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.25) : Color.white.opacity(0.04))
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Frequency
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How Often")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 8) {
                ForEach(MedicationFrequency.allCases) { freq in
                    Button(action: { frequency = freq }) {
                        Text(freq.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(frequency == freq ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(frequency == freq ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.25) : Color.white.opacity(0.04))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Pill Count
    private var pillCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pill Count")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Total Pills")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    HStack {
                        Button(action: { if pillCount > 0 { pillCount -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("\(pillCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 40)
                        Button(action: { pillCount += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                    }
                }

                VStack(spacing: 4) {
                    Text("Per Dose")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    HStack {
                        Button(action: { if pillsPerDose > 1 { pillsPerDose -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("\(pillsPerDose)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 30)
                        Button(action: { pillsPerDose += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
        }
    }

    // MARK: - Details
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            TextField("What is this medication for?", text: $purpose)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

            TextField("Special instructions (with food, etc.)", text: $instructions)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

            TextField("Prescribed by (doctor name)", text: $prescribedBy)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

            TextField("Rx Number", text: $rxNumber)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        }
    }

    // MARK: - Pharmacy
    private var pharmacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pharmacy")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            TextField("Pharmacy name", text: $pharmacyName)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

            TextField("Pharmacy phone", text: $pharmacyPhone)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .keyboardType(.phonePad)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        }
    }

    // MARK: - Reminders
    private var reminderSection: some View {
        Toggle(isOn: $remindersEnabled) {
            HStack(spacing: 10) {
                Image(systemName: "bell.fill")
                    .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text("Taylor will remind you when it's time to take this")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .tint(Color(red: 0.4, green: 0.8, blue: 0.6))
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }

    // MARK: - Color
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Label")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 10) {
                ForEach(["blue", "green", "purple", "orange", "red", "pink", "teal"], id: \.self) { c in
                    Button(action: { selectedColor = c }) {
                        Circle()
                            .fill(colorForName(c))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == c ? 2 : 0)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Ask Taylor
    private var askTaylorButton: some View {
        Button(action: { showAskTaylor = true }) {
            HStack(spacing: 10) {
                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 18))
                Text("Ask Taylor about this medication")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Delete
    private var deleteButton: some View {
        Button(action: deleteMedication) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                Text("Remove Medication")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.red.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.06))
            )
        }
    }

    // MARK: - Actions
    private func saveMedication() {
        if let med = existingMedication {
            med.name = name
            med.genericName = genericName
            med.dosage = dosage
            med.form = form.rawValue
            med.frequency = frequency.rawValue
            med.pillCount = pillCount
            med.pillsPerDose = pillsPerDose
            med.purpose = purpose
            med.instructions = instructions
            med.prescribedBy = prescribedBy
            med.rxNumber = rxNumber
            med.pharmacyName = pharmacyName
            med.pharmacyPhone = pharmacyPhone
            med.remindersEnabled = remindersEnabled
            med.color = selectedColor
        } else {
            let med = Medication(name: name, dosage: dosage, frequency: frequency.rawValue, pillCount: pillCount)
            med.genericName = genericName
            med.form = form.rawValue
            med.pillsPerDose = pillsPerDose
            med.purpose = purpose
            med.instructions = instructions
            med.prescribedBy = prescribedBy
            med.rxNumber = rxNumber
            med.pharmacyName = pharmacyName
            med.pharmacyPhone = pharmacyPhone
            med.remindersEnabled = remindersEnabled
            med.color = selectedColor
            modelContext.insert(med)

            // Schedule reminders
            if remindersEnabled {
                taylor.scheduleMedicationReminder(for: med)
            }
        }
        dismiss()
    }

    private func deleteMedication() {
        if let med = existingMedication {
            modelContext.delete(med)
        }
        dismiss()
    }

    private func loadExisting() {
        guard let med = existingMedication else { return }
        name = med.name
        genericName = med.genericName
        dosage = med.dosage
        form = MedicationForm(rawValue: med.form) ?? .tablet
        frequency = MedicationFrequency(rawValue: med.frequency) ?? .once_daily
        pillCount = med.pillCount
        pillsPerDose = med.pillsPerDose
        purpose = med.purpose
        instructions = med.instructions
        prescribedBy = med.prescribedBy
        rxNumber = med.rxNumber
        pharmacyName = med.pharmacyName
        pharmacyPhone = med.pharmacyPhone
        remindersEnabled = med.remindersEnabled
        selectedColor = med.color
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return Color(red: 0.3, green: 0.5, blue: 0.9)
        case "green": return Color(red: 0.3, green: 0.7, blue: 0.4)
        case "purple": return Color(red: 0.6, green: 0.4, blue: 0.8)
        case "orange": return Color(red: 0.9, green: 0.6, blue: 0.2)
        case "red": return Color(red: 0.9, green: 0.3, blue: 0.3)
        case "pink": return Color(red: 0.9, green: 0.4, blue: 0.6)
        case "teal": return Color(red: 0.3, green: 0.7, blue: 0.7)
        default: return .blue
        }
    }
}
