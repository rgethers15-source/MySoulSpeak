import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var content: String
    var mood: String
    var duration: TimeInterval
    var drHopeFeedback: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        content: String = "",
        mood: String = "neutral",
        duration: TimeInterval = 0,
        drHopeFeedback: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.mood = mood
        self.duration = duration
        self.drHopeFeedback = drHopeFeedback
        self.createdAt = createdAt
    }
}
