import SwiftUI
import SwiftData
import MapKit

/// DoctorInfo — SwiftData model for storing doctor information.
@Model
final class DoctorInfo {
    var id: UUID = UUID()
    var name: String = ""
    var specialty: String = ""
    var phone: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var officeName: String = ""
    var fax: String = ""
    var email: String = ""
    var notes: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var isDefault: Bool = false
    var createdAt: Date = Date()

    init(name: String, specialty: String = "", phone: String = "") {
        self.id = UUID()
        self.name = name
        self.specialty = specialty
        self.phone = phone
        self.createdAt = Date()
    }

    var fullAddress: String {
        var parts: [String] = []
        if !address.isEmpty { parts.append(address) }
        if !city.isEmpty { parts.append(city) }
        if !state.isEmpty { parts.append(state) }
        if !zipCode.isEmpty { parts.append(zipCode) }
        return parts.joined(separator: ", ")
    }
}

/// DoctorView — Manage doctor information with GPS auto-populate.
/// Users can search for doctors nearby or enter manually.
struct DoctorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var doctors: [DoctorInfo]

    @State private var showAddDoctor = false
    @State private var showSearchDoctor = false
    @State private var editingDoctor: DoctorInfo? = nil

    // Manual entry fields
    @State private var name = ""
    @State private var specialty = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var officeName = ""
    @State private var email = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if doctors.isEmpty {
                            emptyState
                        } else {
                            ForEach(doctors, id: \.id) { doctor in
                                doctorCard(doctor)
                            }
                        }

                        // Action buttons
                        VStack(spacing: 10) {
                            // Search nearby doctors
                            Button(action: { showSearchDoctor = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16))
                                    Text("Find Doctor Nearby")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }

                            // Add manually
                            Button(action: { showAddDoctor = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Add Doctor Manually")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.08))
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("My Doctors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .sheet(isPresented: $showAddDoctor) { addDoctorSheet }
            .sheet(isPresented: $showSearchDoctor) { DoctorSearchView() }
        }
    }

    // MARK: - Doctor Card
    private func doctorCard(_ doctor: DoctorInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))

                VStack(alignment: .leading, spacing: 2) {
                    Text(doctor.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    if !doctor.specialty.isEmpty {
                        Text(doctor.specialty)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.8))
                    }
                }

                Spacer()

                Button(action: { deleteDoctor(doctor) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.5))
                }
            }

            if !doctor.officeName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text(doctor.officeName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            if !doctor.fullAddress.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text(doctor.fullAddress)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            if !doctor.phone.isEmpty {
                Button(action: { callDoctor(doctor.phone) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                        Text(doctor.phone)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.green)
                }
            }

            // Quick actions
            HStack(spacing: 10) {
                if !doctor.phone.isEmpty {
                    actionButton(icon: "phone.fill", label: "Call", color: .green) {
                        callDoctor(doctor.phone)
                    }
                }
                actionButton(icon: "map.fill", label: "Directions", color: .blue) {
                    openMaps(doctor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.12)))
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "stethoscope")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text("No doctors saved")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            Text("Add your doctors for quick access")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Add Doctor Sheet
    private var addDoctorSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        formField("Doctor's Name", text: $name)
                        formField("Specialty (e.g. Psychiatrist, PCP)", text: $specialty)
                        formField("Office/Practice Name", text: $officeName)
                        formField("Phone", text: $phone)
                        formField("Address", text: $address)
                        HStack(spacing: 10) {
                            formField("City", text: $city)
                            formField("State", text: $state).frame(width: 70)
                            formField("ZIP", text: $zipCode).frame(width: 80)
                        }
                        formField("Email", text: $email)
                        formField("Notes", text: $notes)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showAddDoctor = false }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveDoctor() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(name.isEmpty ? .white.opacity(0.3) : Color(red: 0.3, green: 0.6, blue: 0.9))
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
    private func saveDoctor() {
        let doctor = DoctorInfo(name: name, specialty: specialty, phone: phone)
        doctor.officeName = officeName
        doctor.address = address
        doctor.city = city
        doctor.state = state
        doctor.zipCode = zipCode
        doctor.email = email
        doctor.notes = notes
        modelContext.insert(doctor)
        showAddDoctor = false
        clearForm()
    }

    private func deleteDoctor(_ doctor: DoctorInfo) {
        modelContext.delete(doctor)
    }

    private func clearForm() {
        name = ""; specialty = ""; phone = ""; address = ""
        city = ""; state = ""; zipCode = ""; officeName = ""; email = ""; notes = ""
    }

    private func callDoctor(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func openMaps(_ doctor: DoctorInfo) {
        let query = doctor.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Doctor Search View (GPS-powered)
struct DoctorSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = PharmacyLocationManager()

    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchQuery = "doctor physician"
    @State private var savedMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Search doctors, clinics...", text: $searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onSubmit { searchNearby() }
                        Button(action: searchNearby) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Results
                    if isSearching {
                        Spacer()
                        ProgressView().tint(.white)
                        Text("Searching...").font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(searchResults, id: \.self) { item in
                                    resultRow(item)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                    }
                }

                if !savedMessage.isEmpty {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text(savedMessage).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.2)))
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Find Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                locationManager.requestLocation()
                searchNearby()
            }
        }
    }

    private func resultRow(_ item: MKMapItem) -> some View {
        Button(action: { saveDoctor(item) }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name ?? "Doctor")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    if let addr = item.placemark.title {
                        Text(addr)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(2)
                    }
                    if let phone = item.phoneNumber {
                        Text(phone)
                            .font(.system(size: 10))
                            .foregroundColor(.green.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
        }
    }

    private func searchNearby() {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        if let loc = locationManager.lastLocation {
            request.region = MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        MKLocalSearch(request: request).start { response, _ in
            isSearching = false
            searchResults = response?.mapItems ?? []
        }
    }

    private func saveDoctor(_ item: MKMapItem) {
        let doctor = DoctorInfo(name: item.name ?? "Doctor", phone: item.phoneNumber ?? "")
        doctor.address = item.placemark.thoroughfare ?? ""
        doctor.city = item.placemark.locality ?? ""
        doctor.state = item.placemark.administrativeArea ?? ""
        doctor.zipCode = item.placemark.postalCode ?? ""
        doctor.latitude = item.placemark.coordinate.latitude
        doctor.longitude = item.placemark.coordinate.longitude
        modelContext.insert(doctor)
        savedMessage = "\(item.name ?? "Doctor") saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedMessage = "" }
    }
}
