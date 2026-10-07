import Foundation
import SwiftData

@Model
final class MoodEntry {
    @Attribute(.unique) var id: UUID
    var mood: String
    var intensity: Int
    var note: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        mood: String,
        intensity: Int = 5,
        note: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.mood = mood
        self.intensity = intensity
        self.note = note
        self.timestamp = timestamp
    }
}
