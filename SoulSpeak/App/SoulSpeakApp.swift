import SwiftUI
import SwiftData

@main
struct SoulSpeakApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JournalEntry.self,
            MoodEntry.self,
            UserSettings.self,
            UserProfile.self,
            AccountabilityEvent.self,
            Medication.self,
            PharmacyInfo.self,
            DoctorInfo.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(nil) // Controlled by settings
        }
    }
}
