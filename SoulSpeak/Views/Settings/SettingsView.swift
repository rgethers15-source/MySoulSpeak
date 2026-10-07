import SwiftUI
import SwiftData
import CoreLocation
import MapKit

/// Settings Screen: Theme toggle, notifications, mental health resources with GPS locator.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]

    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var reminderHour = 9
    @State private var reminderMinute = 0
    @State private var showResourceLocator = false
    @State private var showAbout = false
    @State private var showTutorials = false
    @StateObject private var auth = AuthService.shared

    private var currentSettings: UserSettings? { settings.first }

    var body: some View {
        List {
            // Appearance section
            appearanceSection

            // Notifications section
            notificationsSection

            // Mental health resources
            resourcesSection

            // About section
            aboutSection

            // Tutorials section
            tutorialsSection

            // Data section
            dataSection

            // Account section
            accountSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(SSColors.primary)
                }
            }
        }
        .onAppear { loadSettings() }
        .sheet(isPresented: $showResourceLocator) {
            ResourceLocatorView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showTutorials) {
            TutorialListView()
        }
    }

    // MARK: - Appearance
    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $isDarkMode) {
                HStack(spacing: 12) {
                    settingIcon("moon.fill", color: SSColors.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dark Mode")
                            .font(SSTypography.body)
                        Text("Easier on the eyes at night")
                            .font(SSTypography.small)
                            .foregroundColor(SSColors.textSecondary)
                    }
                }
            }
            .tint(SSColors.primary)
            .onChange(of: isDarkMode) { _, newValue in
                updateSetting { $0.isDarkMode = newValue }
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Notifications
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                HStack(spacing: 12) {
                    settingIcon("bell.fill", color: SSColors.energy)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminders")
                            .font(SSTypography.body)
                        Text("Gentle nudge to journal")
                            .font(SSTypography.small)
                            .foregroundColor(SSColors.textSecondary)
                    }
                }
            }
            .tint(SSColors.primary)
            .onChange(of: notificationsEnabled) { _, newValue in
                updateSetting { $0.notificationsEnabled = newValue }
                if newValue {
                    NotificationService.shared.requestPermission { granted in
                        if granted {
                            NotificationService.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
                        }
                    }
                } else {
                    NotificationService.shared.cancelDailyReminder()
                }
            }

            if notificationsEnabled {
                HStack(spacing: 12) {
                    settingIcon("clock.fill", color: SSColors.calm)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reminder Time")
                            .font(SSTypography.body)
                        Text("\(formattedTime)")
                            .font(SSTypography.caption)
                            .foregroundColor(SSColors.primary)
                    }
                    Spacer()
                    DatePicker("", selection: reminderDateBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 100)
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Mental Health Resources
    private var resourcesSection: some View {
        Section {
            Button(action: { showResourceLocator = true }) {
                HStack(spacing: 12) {
                    settingIcon("location.fill", color: SSColors.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Find Resources Near You")
                            .font(SSTypography.body)
                            .foregroundColor(SSColors.textPrimary)
                        Text("Mental health services & hotlines")
                            .font(SSTypography.small)
                            .foregroundColor(SSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SSColors.textSecondary)
                }
            }

            // Crisis hotlines
            crisisLink(
                name: "988 Suicide & Crisis Lifeline",
                phone: "988",
                icon: "phone.fill",
                color: .red
            )

            crisisLink(
                name: "Crisis Text Line",
                phone: "Text HOME to 741741",
                icon: "message.fill",
                color: SSColors.primary
            )

            crisisLink(
                name: "SAMHSA Helpline",
                phone: "1-800-662-4357",
                icon: "heart.fill",
                color: SSColors.love
            )

            crisisLink(
                name: "NAMI Helpline",
                phone: "1-800-950-6264",
                icon: "person.2.fill",
                color: SSColors.calm
            )
        } header: {
            Text("Mental Health Resources")
        } footer: {
            Text("If you're in crisis, please reach out. You are not alone.")
                .font(SSTypography.small)
                .foregroundColor(SSColors.textSecondary)
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        Section {
            Button(action: { showAbout = true }) {
                HStack(spacing: 12) {
                    settingIcon("info.circle.fill", color: SSColors.secondary)
                    Text("About SoulSpeak")
                        .font(SSTypography.body)
                        .foregroundColor(SSColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SSColors.textSecondary)
                }
            }

            HStack(spacing: 12) {
                settingIcon("sparkles", color: SSColors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version")
                        .font(SSTypography.body)
                    Text("1.0.0")
                        .font(SSTypography.small)
                        .foregroundColor(SSColors.textSecondary)
                }
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Tutorials
    private var tutorialsSection: some View {
        Section {
            Button(action: { showTutorials = true }) {
                HStack(spacing: 12) {
                    settingIcon("play.circle.fill", color: Color(red: 0.3, green: 0.7, blue: 0.9))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("How to Use MySoulSpeak")
                            .font(SSTypography.body)
                            .foregroundColor(SSColors.textPrimary)
                        Text("Watch interactive tutorials for each feature")
                            .font(SSTypography.small)
                            .foregroundColor(SSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SSColors.textSecondary)
                }
            }
        } header: {
            Text("Tutorials")
        }
    }

    // MARK: - Data
    private var dataSection: some View {
        Section {
            HStack(spacing: 12) {
                settingIcon("externaldrive.fill", color: SSColors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Data Storage")
                        .font(SSTypography.body)
                    Text("All data stored locally on device")
                        .font(SSTypography.small)
                        .foregroundColor(SSColors.textSecondary)
                }
            }
        } header: {
            Text("Privacy & Data")
        } footer: {
            Text("SoulSpeak never sends your personal data to external servers. Your journals and moods stay on your device.")
                .font(SSTypography.small)
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        Section {
            // Signed-in user info
            HStack(spacing: 12) {
                settingIcon("person.crop.circle.fill", color: SSColors.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(auth.displayName)
                        .font(SSTypography.body)
                        .foregroundColor(SSColors.textPrimary)
                    Text("Signed in with Apple")
                        .font(SSTypography.small)
                        .foregroundColor(SSColors.textSecondary)
                }
            }

            // Sign out button
            Button(action: { auth.signOut() }) {
                HStack(spacing: 12) {
                    settingIcon("rectangle.portrait.and.arrow.right", color: .red)
                    Text("Sign Out")
                        .font(SSTypography.body)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Helpers
    private func settingIcon(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: name)
                .font(.system(size: 14))
                .foregroundColor(color)
        }
    }

    private func crisisLink(name: String, phone: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            settingIcon(icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(SSTypography.body)
                Text(phone)
                    .font(SSTypography.caption)
                    .foregroundColor(SSColors.primary)
            }
            Spacer()
            if phone.count <= 5 || phone.hasPrefix("1-") {
                let cleanPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                Link(destination: URL(string: "tel://\(cleanPhone)")!) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SSColors.success)
                }
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 9
                reminderMinute = components.minute ?? 0
                updateSetting {
                    $0.dailyReminderHour = reminderHour
                    $0.dailyReminderMinute = reminderMinute
                }
                // Reschedule notification with new time
                if notificationsEnabled {
                    NotificationService.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
                }
            }
        )
    }

    private func loadSettings() {
        if let s = currentSettings {
            isDarkMode = s.isDarkMode
            notificationsEnabled = s.notificationsEnabled
            reminderHour = s.dailyReminderHour
            reminderMinute = s.dailyReminderMinute
            // Ensure notifications are scheduled if enabled
            if notificationsEnabled {
                NotificationService.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
            }
        } else {
            // Create default settings
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
        }
    }

    private func updateSetting(_ update: (UserSettings) -> Void) {
        if let s = currentSettings {
            update(s)
        }
    }
}

// MARK: - Resource Locator View (GPS-based)
struct ResourceLocatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.749, longitude: -84.388),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map
                Map(position: $position) {
                    ForEach(searchResults, id: \.self) { item in
                        Annotation(item.name ?? "", coordinate: item.placemark.coordinate) {
                            VStack(spacing: 2) {
                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(SSColors.primary)
                                Text(item.name ?? "")
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(height: 300)

                // Results list
                List {
                    if searchResults.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Searching for mental health resources nearby...")
                                    .font(SSTypography.caption)
                                    .foregroundColor(SSColors.textSecondary)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(searchResults, id: \.self) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Mental Health Service")
                                    .font(SSTypography.body)
                                    .foregroundColor(SSColors.textPrimary)
                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(SSTypography.small)
                                        .foregroundColor(SSColors.textSecondary)
                                }
                                if let phone = item.phoneNumber {
                                    Text(phone)
                                        .font(SSTypography.caption)
                                        .foregroundColor(SSColors.primary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Nearby Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                locationManager.requestLocation()
                searchNearbyResources()
            }
            .onChange(of: locationManager.lastLocation) { _, location in
                if let location = location {
                    position = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    ))
                    searchNearbyResources(near: location.coordinate)
                }
            }
        }
    }

    private func searchNearbyResources(near coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 33.749, longitude: -84.388)) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "mental health counseling therapy"
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let items = response?.mapItems {
                searchResults = items
            }
        }
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[SoulSpeak] Location error: \(error)")
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon
                    ZStack {
                        Circle()
                            .fill(SSColors.gradientPrimary)
                            .frame(width: 80, height: 80)
                        Image(systemName: "waveform.and.mic")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 32)

                    Text("SoulSpeak")
                        .font(SSTypography.largeTitle)
                        .foregroundColor(SSColors.textPrimary)

                    Text("A spiritual mental wellness app")
                        .font(SSTypography.body)
                        .foregroundColor(SSColors.textSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        aboutRow(icon: "heart.fill", text: "Dr. Hope — Your Gullah-style spiritual therapist")
                        aboutRow(icon: "hand.wave.fill", text: "Mr. Hope — Your warm greeter and encourager")
                        aboutRow(icon: "mic.fill", text: "Voice journaling with real-time feedback")
                        aboutRow(icon: "chart.line.uptrend.xyaxis", text: "Mood tracking & analytics")
                        aboutRow(icon: "book.fill", text: "Daily scripture & prayer")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    Spacer()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func aboutRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(SSColors.primary)
                .frame(width: 24)
            Text(text)
                .font(SSTypography.body)
                .foregroundColor(SSColors.textPrimary)
        }
    }
}
