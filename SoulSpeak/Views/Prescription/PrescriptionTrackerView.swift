import SwiftUI
import SwiftData

/// PrescriptionTrackerView — Main hub for medication management.
/// Shows all medications, pill counts, refill alerts, today's schedule,
/// and Taylor Hope's floating avatar for AI assistance.
///
/// Organized by Taylor Hope — Mr. Hope & Dr. Hope's daughter.
/// She's an RN in her final year of psychiatry residency.
struct PrescriptionTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Medication.name) private var medications: [Medication]
    @StateObject private var taylor = TaylorService.shared

    @State private var showAddMedication = false
    @State private var showTaylorChat = false
    @State private var showPharmacy = false
    @State private var showPharmacySearch = false
    @State private var showDoctors = false
    @State private var showDisclaimer = true
    @State private var selectedMedication: Medication? = nil
    @AppStorage("hasAcceptedRxDisclaimer") private var hasAcceptedRxDisclaimer = false
    @AppStorage("hasSeenTaylorIntro") private var hasSeenTaylorIntro = false
    @State private var showIntroVideo = true

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.1),
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.04, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !hasAcceptedRxDisclaimer {
                PrescriptionDisclaimerView(hasAccepted: $hasAcceptedRxDisclaimer)
            } else if showIntroVideo && !hasSeenTaylorIntro {
                taylorIntroVideo
            } else {
                mainContent
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddMedication) {
            MedicationDetailView()
        }
        .sheet(item: $selectedMedication) { med in
            MedicationDetailView(existingMedication: med)
        }
        .sheet(isPresented: $showTaylorChat) {
            TaylorChatView(medications: medications)
        }
        .sheet(isPresented: $showPharmacy) {
            PharmacyView()
        }
        .sheet(isPresented: $showPharmacySearch) {
            PharmacySearchView()
        }
        .sheet(isPresented: $showDoctors) {
            DoctorView()
        }
    }

    // MARK: - Taylor Intro Video
    private var taylorIntroVideo: some View {
        FullScreenVideoBackground(
            videoName: "taylor_intro",
            fileExtension: "mp4",
            looping: false,
            onFinished: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showIntroVideo = false
                    hasSeenTaylorIntro = true
                }
            }
        )
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                prescriptionHeader

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Today's schedule
                        todaySection

                        // Medication list
                        medicationListSection

                        // Refill alerts
                        if !runningLowMeds.isEmpty {
                            refillAlertSection
                        }

                        // Quick actions
                        quickActionsSection

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }

            // Taylor floating avatar (bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    taylorFloatingButton
                }
            }

            // Add medication button (bottom-left)
            VStack {
                Spacer()
                HStack {
                    addMedicationButton
                    Spacer()
                }
            }
        }
    }

    // MARK: - Header
    private var prescriptionHeader: some View {
        HStack(spacing: 14) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Prescriptions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Managed by Taylor Hope, RN")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Pharmacy button
            Button(action: { showPharmacy = true }) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .padding(10)
                    .background(Circle().fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.15)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Today's Schedule
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                Text("Today's Medications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(takenTodayCount)/\(activeMeds.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(takenTodayCount == activeMeds.count ? .green : .white.opacity(0.5))
            }

            if activeMeds.isEmpty {
                emptyStateView
            } else {
                ForEach(activeMeds, id: \.id) { med in
                    todayMedRow(med)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func todayMedRow(_ med: Medication) -> some View {
        HStack(spacing: 14) {
            // Take button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    med.takeDose()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(med.isTakenToday ? Color.green.opacity(0.2) : med.displayColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    if med.isTakenToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 22))
                            .foregroundColor(med.displayColor)
                    }
                }
            }
            .disabled(med.isTakenToday)

            // Med info
            VStack(alignment: .leading, spacing: 3) {
                Text(med.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(med.isTakenToday ? .white.opacity(0.5) : .white)
                    .strikethrough(med.isTakenToday)

                HStack(spacing: 8) {
                    Text(med.dosage)
                        .font(.system(size: 11))
                        .foregroundColor(med.displayColor.opacity(0.8))

                    Text(med.frequencyDisplayName)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            // Pill count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(med.pillsRemaining)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(med.isRunningLow ? .orange : .white.opacity(0.6))
                Text("pills left")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }

            // Edit
            Button(action: { selectedMedication = med }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(med.isTakenToday ? Color.green.opacity(0.04) : Color.white.opacity(0.03))
        )
    }

    // MARK: - Medication List
    private var medicationListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pill.fill")
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.8))
                Text("All Medications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(medications.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }

            ForEach(medications, id: \.id) { med in
                medicationCard(med)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func medicationCard(_ med: Medication) -> some View {
        Button(action: { selectedMedication = med }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(med.displayColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: MedicationForm(rawValue: med.form)?.icon ?? "pill.fill")
                        .font(.system(size: 16))
                        .foregroundColor(med.displayColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(med.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        if !med.isActive {
                            Text("Inactive")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.15)))
                        }
                    }
                    Text("\(med.dosage) • \(med.frequencyDisplayName) • \(med.formDisplayName)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                // Status indicators
                VStack(alignment: .trailing, spacing: 4) {
                    if med.isRunningLow {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text("Low")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.orange)
                    }
                    Text("\(med.pillsRemaining) left")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    // MARK: - Refill Alert Section
    private var refillAlertSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Refill Needed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            ForEach(runningLowMeds, id: \.id) { med in
                HStack(spacing: 12) {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.orange)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(med.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(med.pillsRemaining) pills left (~\(med.daysUntilEmpty) days)")
                            .font(.system(size: 11))
                            .foregroundColor(.orange.opacity(0.8))
                    }

                    Spacer()

                    if !med.pharmacyPhone.isEmpty {
                        Button(action: { callPharmacy(med.pharmacyPhone) }) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Circle().fill(Color.green.opacity(0.15)))
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orange.opacity(0.04))
        )
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                quickActionButton(icon: "barcode.viewfinder", label: "Scan Rx", color: .blue) {
                    showAddMedication = true
                }
                quickActionButton(icon: "location.fill", label: "Find Pharmacy", color: .green) {
                    showPharmacySearch = true
                }
            }
            HStack(spacing: 12) {
                quickActionButton(icon: "stethoscope", label: "My Doctors", color: Color(red: 0.3, green: 0.6, blue: 0.9)) {
                    showDoctors = true
                }
                quickActionButton(icon: "questionmark.circle.fill", label: "Ask Taylor", color: .purple) {
                    showTaylorChat = true
                }
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "pill.circle")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text("No medications tracked yet")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            Text("Tap + to add your first medication, or ask Taylor for help")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Taylor Floating Button
    private var taylorFloatingButton: some View {
        Button(action: { showTaylorChat = true }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.4, green: 0.2, blue: 0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.4), radius: 8, y: 4)

                // Taylor icon (will be replaced with her image when available)
                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Add Medication Button
    private var addMedicationButton: some View {
        Button(action: { showAddMedication = true }) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.4), radius: 8, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.leading, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Helpers
    private var activeMeds: [Medication] {
        medications.filter { $0.isActive }
    }

    private var runningLowMeds: [Medication] {
        medications.filter { $0.isRunningLow && $0.isActive }
    }

    private var takenTodayCount: Int {
        activeMeds.filter { $0.isTakenToday }.count
    }

    private func callPharmacy(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}
