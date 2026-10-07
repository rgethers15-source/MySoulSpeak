import Foundation

/// Provides daily scriptures and Dr. Hope's closing quotes.
struct ScriptureService {
    struct Scripture: Identifiable {
        let id = UUID()
        let verse: String
        let reference: String
    }

    struct ClosingQuote: Identifiable {
        let id = UUID()
        let quote: String
        let attribution: String
    }

    static let scriptures: [Scripture] = [
        Scripture(verse: "The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures.", reference: "Psalm 23:1-2"),
        Scripture(verse: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.", reference: "Matthew 11:28"),
        Scripture(verse: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you.", reference: "Jeremiah 29:11"),
        Scripture(verse: "The Lord is close to the brokenhearted and saves those who are crushed in spirit.", reference: "Psalm 34:18"),
        Scripture(verse: "Cast all your anxiety on Him because He cares for you.", reference: "1 Peter 5:7"),
        Scripture(verse: "Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.", reference: "Joshua 1:9"),
        Scripture(verse: "Peace I leave with you; my peace I give you. I do not give to you as the world gives.", reference: "John 14:27"),
        Scripture(verse: "He heals the brokenhearted and binds up their wounds.", reference: "Psalm 147:3"),
        Scripture(verse: "Trust in the Lord with all thine heart; and lean not unto thine own understanding.", reference: "Proverbs 3:5"),
        Scripture(verse: "Weeping may endure for a night, but joy cometh in the morning.", reference: "Psalm 30:5"),
        Scripture(verse: "I can do all things through Christ which strengtheneth me.", reference: "Philippians 4:13"),
        Scripture(verse: "The Lord is my light and my salvation; whom shall I fear?", reference: "Psalm 27:1"),
        Scripture(verse: "And we know that all things work together for good to them that love God.", reference: "Romans 8:28"),
        Scripture(verse: "Fear thou not; for I am with thee: be not dismayed; for I am thy God.", reference: "Isaiah 41:10"),
    ]

    static let closingQuotes: [ClosingQuote] = [
        ClosingQuote(quote: "Baby, you done good today. The ancestors are proud. Rest now, hear?", attribution: "Dr. Hope"),
        ClosingQuote(quote: "Every step you take toward healing is a step the whole family tree feels. Keep goin'.", attribution: "Dr. Hope"),
        ClosingQuote(quote: "You ain't gotta carry it all tonight. Lay it down. The morning gonna bring new mercy.", attribution: "Dr. Hope"),
        ClosingQuote(quote: "Your spirit is stronger than you know. I seen it. The Lord seen it too.", attribution: "Dr. Hope"),
        ClosingQuote(quote: "Healing ain't linear, sugar. Some days you crawl. That still counts.", attribution: "Dr. Hope"),
        ClosingQuote(quote: "You showed up for yourself today. That's the bravest thing a soul can do.", attribution: "Dr. Hope"),
        ClosingQuote(quote: "The peace you seeking? It's already inside you. We just clearing the path to it.", attribution: "Dr. Hope"),
    ]

    static func dailyScripture() -> Scripture {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return scriptures[dayOfYear % scriptures.count]
    }

    static func dailyClosingQuote() -> ClosingQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return closingQuotes[dayOfYear % closingQuotes.count]
    }
}
