import SwiftUI
import SwiftData
import MapKit

/// PharmacyView — Store and display pharmacy information.
/// Shows pharmacy name, address, phone, hours, and real-time open/closed status.
/// Users can save their pharmacy for quick access when refilling.
struct PharmacyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var pharmacies: [PharmacyInfo]

    @State private var showAddPharmacy = false
    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phone = ""
    @State private var hoursMonFri = "9:00 AM - 9:00 PM"
    @State private var hoursSat = "9:00 AM - 6:00 PM"
    @State private var hoursSun = "10:00 AM - 5:00 PM"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if pharmacies.isEmpty {
                            emptyState
                        } else {
                            ForEach(pharmacies, id: \.id) { pharmacy in
                                pharmacyCard(pharmacy)
                            }
                        }

                        // Add pharmacy button
                        Button(action: { showAddPharmacy = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Add Pharmacy")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("My Pharmacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .sheet(isPresented: $showAddPharmacy) {
                addPharmacySheet
            }
        }
    }

    // MARK: - Pharmacy Card
    private func pharmacyCard(_ pharmacy: PharmacyInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                Text(pharmacy.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Open/Closed badge
                Text(pharmacy.isOpen ? "OPEN" : "CLOSED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(pharmacy.isOpen ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(pharmacy.isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    )
            }

            // Address
            if !pharmacy.fullAddress.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text(pharmacy.fullAddress)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Phone
            if !pharmacy.phone.isEmpty {
                Button(action: { callPhone(pharmacy.phone) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                        Text(pharmacy.phone)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

            // Hours
            VStack(alignment: .leading, spacing: 4) {
                Text("Hours")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)

                hoursRow("Mon-Fri", pharmacy.hoursMonFri)
                hoursRow("Saturday", pharmacy.hoursSaturday)
                hoursRow("Sunday", pharmacy.hoursSunday)
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: { callPhone(pharmacy.phone) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Call")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.3)))
                }

                Button(action: { openMaps(pharmacy) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                        Text("Directions")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.blue.opacity(0.3)))
                }

                Spacer()

                Button(action: { deletePharmacy(pharmacy) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func hoursRow(_ day: String, _ hours: String) -> some View {
        HStack {
            Text(day)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 70, alignment: .leading)
            Text(hours)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cross.case")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.2))
            Text("No pharmacy saved")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            Text("Add your pharmacy for quick refill access")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Add Pharmacy Sheet
    private var addPharmacySheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        formField("Pharmacy Name", text: $name)
                        formField("Street Address", text: $address)
                        HStack(spacing: 10) {
                            formField("City", text: $city)
                            formField("State", text: $state).frame(width: 80)
                            formField("ZIP", text: $zipCode).frame(width: 80)
                        }
                        formField("Phone Number", text: $phone)
                        formField("Hours Mon-Fri", text: $hoursMonFri)
                        formField("Hours Saturday", text: $hoursSat)
                        formField("Hours Sunday", text: $hoursSun)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Pharmacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showAddPharmacy = false }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { savePharmacy() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(name.isEmpty ? .white.opacity(0.3) : Color(red: 0.4, green: 0.8, blue: 0.6))
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func formField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
    }

    // MARK: - Actions
    private func savePharmacy() {
        let pharmacy = PharmacyInfo(name: name, address: address, phone: phone)
        pharmacy.city = city
        pharmacy.state = state
        pharmacy.zipCode = zipCode
        pharmacy.hoursMonFri = hoursMonFri
        pharmacy.hoursSaturday = hoursSat
        pharmacy.hoursSunday = hoursSun
        modelContext.insert(pharmacy)
        showAddPharmacy = false
        clearForm()
    }

    private func deletePharmacy(_ pharmacy: PharmacyInfo) {
        modelContext.delete(pharmacy)
    }

    private func clearForm() {
        name = ""; address = ""; city = ""; state = ""; zipCode = ""; phone = ""
    }

    private func callPhone(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func openMaps(_ pharmacy: PharmacyInfo) {
        let query = pharmacy.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}
