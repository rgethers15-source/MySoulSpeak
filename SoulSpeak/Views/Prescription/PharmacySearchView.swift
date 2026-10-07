import SwiftUI
import MapKit
import SwiftData

/// PharmacySearchView — GPS-powered pharmacy search.
/// Auto-populates pharmacy info (name, address, phone, hours) by searching
/// nearby pharmacies using MapKit. User selects one and it fills everything.
struct PharmacySearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = PharmacyLocationManager()

    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchQuery = "pharmacy"
    @State private var savedMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Results
                    if isSearching {
                        loadingView
                    } else if searchResults.isEmpty {
                        emptyView
                    } else {
                        resultsList
                    }
                }

                // Saved confirmation
                if !savedMessage.isEmpty {
                    savedBanner
                }
            }
            .navigationTitle("Find Pharmacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                locationManager.requestLocation()
                searchNearbyPharmacies()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))

            TextField("Search pharmacies...", text: $searchQuery)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .onSubmit { searchNearbyPharmacies() }

            Button(action: searchNearbyPharmacies) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Results List
    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(searchResults, id: \.self) { item in
                    pharmacyResultRow(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private func pharmacyResultRow(_ item: MKMapItem) -> some View {
        Button(action: { savePharmacy(item) }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Pharmacy")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    if let address = item.placemark.title {
                        Text(address)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(2)
                    }

                    if let phone = item.phoneNumber {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 9))
                            Text(phone)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.green.opacity(0.8))
                    }
                }

                Spacer()

                // Add button
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    Text("Add")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(.white)
            Text("Searching nearby pharmacies...")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
        }
    }

    // MARK: - Empty
    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text("No pharmacies found nearby")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            Text("Try searching by name or enable location services")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }

    // MARK: - Saved Banner
    private var savedBanner: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(savedMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.2)))
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Actions
    private func searchNearbyPharmacies() {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery

        if let location = locationManager.lastLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let items = response?.mapItems {
                searchResults = items
            }
        }
    }

    private func savePharmacy(_ item: MKMapItem) {
        let pharmacy = PharmacyInfo(
            name: item.name ?? "Pharmacy",
            address: item.placemark.thoroughfare ?? "",
            phone: item.phoneNumber ?? ""
        )
        pharmacy.city = item.placemark.locality ?? ""
        pharmacy.state = item.placemark.administrativeArea ?? ""
        pharmacy.zipCode = item.placemark.postalCode ?? ""
        pharmacy.latitude = item.placemark.coordinate.latitude
        pharmacy.longitude = item.placemark.coordinate.longitude

        modelContext.insert(pharmacy)

        savedMessage = "\(item.name ?? "Pharmacy") saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            savedMessage = ""
        }
    }
}

// MARK: - Location Manager for Pharmacy Search
class PharmacyLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Pharmacy GPS] Location error: \(error)")
    }
}
