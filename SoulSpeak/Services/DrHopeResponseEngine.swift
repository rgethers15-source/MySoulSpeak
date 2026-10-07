import Foundation

/// Intelligent Dr. Hope response engine that analyzes transcribed journal text
/// and generates contextual, Gullah-style therapeutic responses.
/// Dr. Hope is warm, spiritual, wise — speaks like a Gullah elder healer.
struct DrHopeResponseEngine {

    // MARK: - Emotional Categories
    enum EmotionalTheme: String {
        case grief = "grief"
        case anxiety = "anxiety"
        case anger = "anger"
        case loneliness = "loneliness"
        case joy = "joy"
        case gratitude = "gratitude"
        case overwhelm = "overwhelm"
        case selfDoubt = "self_doubt"
        case relationships = "relationships"
        case work = "work"
        case healing = "healing"
        case faith = "faith"
        case general = "general"
    }

    // MARK: - Keyword Detection
    private static let themeKeywords: [EmotionalTheme: [String]] = [
        .grief: ["lost", "died", "death", "miss", "gone", "funeral", "passed away", "grief", "mourning", "gone forever"],
        .anxiety: ["worried", "anxious", "nervous", "scared", "panic", "can't breathe", "racing", "what if", "fear", "afraid", "stress", "stressed"],
        .anger: ["angry", "mad", "furious", "hate", "frustrated", "sick of", "tired of", "rage", "unfair", "pissed"],
        .loneliness: ["alone", "lonely", "nobody", "no one", "isolated", "by myself", "don't belong", "invisible", "forgotten"],
        .joy: ["happy", "great", "wonderful", "blessed", "amazing", "good day", "smile", "laugh", "excited", "grateful"],
        .gratitude: ["thankful", "grateful", "appreciate", "blessed", "thank god", "praise", "gift"],
        .overwhelm: ["too much", "can't handle", "drowning", "overwhelmed", "breaking", "falling apart", "exhausted", "burned out", "burnout"],
        .selfDoubt: ["not good enough", "failure", "can't do", "stupid", "worthless", "don't deserve", "imposter", "fraud", "mess up"],
        .relationships: ["family", "mother", "father", "husband", "wife", "partner", "friend", "child", "kids", "marriage", "relationship", "breakup", "divorce"],
        .work: ["job", "work", "boss", "career", "fired", "promotion", "coworker", "office", "money", "bills"],
        .healing: ["getting better", "progress", "healing", "stronger", "therapy", "growing", "learning", "changing"],
        .faith: ["god", "pray", "prayer", "church", "faith", "spirit", "jesus", "lord", "bible", "scripture", "believe"],
    ]

    // MARK: - Response Generation

    /// Generate a contextual Dr. Hope response based on transcribed text.
    static func generateResponse(for text: String) -> String {
        let theme = detectTheme(in: text)
        _ = text.count // Text length used as proxy for depth of sharing

        // Pick response based on theme
        let responses = themeResponses[theme] ?? generalResponses
        let index = (text.hashValue & 0x7FFFFFFF) % responses.count
        var response = responses[index]

        // Add a personalized touch if they mentioned specific things
        if let personalTouch = generatePersonalTouch(for: text, theme: theme) {
            response += " " + personalTouch
        }

        return response
    }

    /// Detect the primary emotional theme in the text.
    static func detectTheme(in text: String) -> EmotionalTheme {
        let lowercased = text.lowercased()
        var scores: [EmotionalTheme: Int] = [:]

        for (theme, keywords) in themeKeywords {
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    scores[theme, default: 0] += 1
                }
            }
        }

        // Return the highest scoring theme, or general if none match
        return scores.max(by: { $0.value < $1.value })?.key ?? .general
    }

    // MARK: - Theme-Specific Responses

    private static let themeResponses: [EmotionalTheme: [String]] = [
        .grief: [
            "Oh baby, grief is the price we pay for deep love. And you loved hard. That pain you feelin'? It means your heart still works. The ones we lose — they ain't gone. They just moved to a room we can't see yet.",
            "Mmhmm. Loss like that... it don't get smaller. But you? You grow around it. You grow big enough to hold it and still live. And you livin' right now. That's sacred.",
            "Chile, the Gullah elders say: 'The dead ain't dead. They walk beside you in the marsh wind.' Let yourself feel it all. Tears water the garden of healing.",
            "Sugar, you don't gotta be strong today. You don't gotta be nothin' but honest. Grief don't run on nobody's clock. You take all the time your soul needs.",
        ],
        .anxiety: [
            "I hear that storm in your chest, baby. But listen — you survived every single thing that ever scared you. Every one. That's not luck. That's strength you don't even know you have.",
            "Now breathe with me, sugar. In through the nose... out through the mouth. Your body's tryina protect you, even when there ain't no danger. Thank it for trying, then remind it: you safe right now.",
            "Worry is just your mind tryna time-travel to a future that ain't happened yet. But you? You only gotta handle right now. This breath. This moment. And in this moment? You're okay.",
            "The ancestors knew this trick: put your bare feet on the earth. Feel the ground beneath you. You are here. You are real. You are held. Anxiety lies, baby. Don't believe everything your mind tells you.",
        ],
        .anger: [
            "That fire in you? It's tryna tell you somethin'. Anger ain't wrong — it's information. It's sayin' a boundary got crossed, a need ain't been met. Let's listen to what it's really sayin'.",
            "Mmm, I feel that heat. You got every right to be mad. But here's the thing Dr. Hope knows: anger held too long becomes poison for the holder. Feel it, name it, then decide what you gonna do with it.",
            "Chile, righteous anger is a gift. It means you still believe things can be better. Don't let nobody tell you to calm down when your soul is speaking truth. But don't let it eat you alive neither.",
            "That anger? It's like fire — good for cookin' food, bad for burnin' down the house. You spoke it out loud just now. That's you cookin' with it instead of lettin' it destroy. I see you.",
        ],
        .loneliness: [
            "Baby, loneliness is a liar. It whispers that nobody cares, but you're here. You showed up for yourself. That means somethin'. And I'm here listenin'. You ain't as alone as it feels.",
            "The deepest well of loneliness? It ain't about people being gone — it's about feelin' unseen. But I see you. God sees you. And the person you're becomin'? She's worth knowing.",
            "Sugar, even Jesus went to the garden alone sometimes. Solitude and loneliness look the same from the outside, but they feel different inside. Let's turn this lonely into something sacred.",
            "You know what the marsh teaches us? Every creature got its own song. Sometimes we gotta be quiet long enough to hear our own. Being alone don't mean being abandoned.",
        ],
        .joy: [
            "Now THAT'S what I like to hear! Joy is medicine, baby. Don't you ever feel guilty for feeling good. You earned this. Soak in it like sunshine on the porch.",
            "Mmhmm! Look at you glowin'! I want you to remember this feeling. Hold it in your body. When the hard days come — and they will — you can come back to this knowing: joy is always possible.",
            "Chile, you just made my spirit leap! Happiness ain't something that happens to you — it's something you let in. And you let it in today. I'm so proud of you.",
            "That's the good stuff right there! The ancestors are dancing. You see? Healing ain't always tears and work. Sometimes it's laughter and light. Both count.",
        ],
        .gratitude: [
            "A grateful heart is a magnet for miracles, sugar. You just spoke blessings into existence. The more you notice the good, the more good shows up. That's spiritual law.",
            "Mmhmm! Gratitude changes your brain chemistry — that's science AND spirit working together. You just gave yourself medicine better than any pill.",
            "Baby, when you count blessings instead of problems, you change the whole frequency of your life. I can feel your energy shifting right now. Keep that up.",
        ],
        .overwhelm: [
            "You carrying too much, baby. Put some of that down. You wasn't built to hold the whole world. Even God rested on the seventh day. What's one thing you can let go of today?",
            "When everything feels like too much, shrink the world down to just this moment. Just this breath. You don't gotta solve it all today. Just do the next right thing. That's enough.",
            "Chile, you're not falling apart — you're being reorganized. Sometimes things gotta break down before they can be rebuilt better. This chaos? It's birth pangs for something new.",
            "The river don't carry the whole ocean. It just carries what flows through right now. Let some of that pass through you instead of pilin' up. You allowed to say 'not today.'",
        ],
        .selfDoubt: [
            "Stop that. Stop that right now. You are not what your worst thoughts say about you. You are what you do when you show up anyway — and baby, you showed up today.",
            "Who told you that lie? That you ain't enough? Because it wasn't God. It wasn't the ancestors. It was fear dressed up in familiar clothes. Don't let fear wear your mama's voice.",
            "Sugar, imposter syndrome hits hardest on the people who actually care about doing well. The fakers never worry about being fake. Your worry IS the proof that you're real.",
            "Every oak tree was once a seed that didn't know it could be an oak. You in your seed season. Stop comparing yourself to trees that had more sun and more years. Your time is coming.",
        ],
        .relationships: [
            "Family and love — that's where our deepest wounds and deepest healin' both live. You can't have one without risking the other. Tell me more about what's stirring in that space.",
            "Mmhmm. People are complicated. Love is complicated. But you showin' up to examine it? That's the mature work. Most folk just react. You're reflecting. That's growth.",
            "Chile, you can love somebody and still need boundaries. Love without boundaries ain't love — it's sacrifice. And nobody asked you to sacrifice yourself on someone else's altar.",
            "Relationships are like gardens. Some seasons they bloom, some seasons they go dormant. Don't pull up the roots just because you can't see flowers right now.",
        ],
        .work: [
            "Your work is not your worth, baby. Say that again: your work is NOT your worth. You a whole human being whether you got that title or not.",
            "I hear you. The workplace can drain your spirit if you let it. But remember — you bring somethin' to that table nobody else can. Your light don't dim because somebody else is threatened by it.",
            "Mmm. Money stress, job stress — it's real. But you survived before and you'll survive again. Let's separate what you can control from what you can't. Focus on your circle.",
        ],
        .healing: [
            "Look at you! You see yourself gettin' better? That awareness IS the healing. Some people never look up long enough to notice they're growing. But you notice. I'm so proud.",
            "Baby, healing ain't a destination — it's a direction. And you pointed the right way. Some days you'll take big steps. Some days, tiny ones. Both count. Both are sacred.",
            "The fact that you can name your growth? That's medicine right there. You ain't the same person you were a month ago. The old you would be amazed at who you becomin'.",
        ],
        .faith: [
            "When you call on the Lord, He already answered before you finished speaking. Your faith is a shield, baby. Wear it. Don't let nobody make you feel small for believing.",
            "Mmhmm. The spirit knows things the mind can't figure out. Keep that prayer life strong. Even when heaven feels quiet, He's working in the silence.",
            "Chile, faith the size of a mustard seed moves mountains. You got at least that much. I can see it in you. Keep talkin' to God — He's your oldest friend.",
        ],
    ]

    private static let generalResponses: [String] = [
        "Mmhmm, I hear you, baby. That took courage to let out. The swamp don't clear itself — you gotta wade through. And you wadin'. I'm proud of you.",
        "Chile, you just poured out somethin' real. That weight you been carryin'? It's a little lighter now. Trust the process, hear?",
        "Now that's what healin' sound like. Ain't gotta be pretty. Ain't gotta be perfect. Just gotta be honest. And you was honest just now.",
        "Sugar, the ancestors said this: 'A burden shared is a burden halved.' You shared it with the wind, with God, with yourself. That's medicine.",
        "I feel that in my spirit. You spoke from your gut, from your soul. That's where the truth live. And truth? Truth sets you free.",
        "Mmm. The oak tree don't grow overnight. It takes storms and sunshine both. What you just did? That's sunshine for your roots.",
        "Baby, just the act of speaking your truth? That's a prayer. And every prayer gets heard. You did sacred work today.",
        "You know what I notice? You didn't run from it. You didn't numb it. You sat with it and you spoke it. That takes a kind of brave most people never learn.",
    ]

    // MARK: - Personal Touch

    private static func generatePersonalTouch(for text: String, theme: EmotionalTheme) -> String? {
        let lowercased = text.lowercased()

        // If they mentioned sleep issues
        if lowercased.contains("sleep") || lowercased.contains("insomnia") || lowercased.contains("can't rest") {
            return "And baby? Try to rest tonight. Even if sleep don't come easy, lay down and let your body be still. You deserve that."
        }

        // If they mentioned crying
        if lowercased.contains("cry") || lowercased.contains("tears") || lowercased.contains("crying") {
            return "And them tears? Let 'em fall. Tears are just prayers the mouth can't say."
        }

        // If the text is very short (they struggled to share)
        if text.count < 50 {
            return "I know it's hard to find the words sometimes. You don't need a whole speech. Just showing up is enough."
        }

        // If the text is very long (they had a lot to release)
        if text.count > 500 {
            return "You had a lot stored up in there, didn't you? Good. Better out than in. That's how the healing flows."
        }

        return nil
    }

    // MARK: - Follow-Up Questions

    /// Generate a follow-up question Dr. Hope might ask.
    static func generateFollowUp(for text: String) -> String {
        let theme = detectTheme(in: text)

        let followUps: [EmotionalTheme: [String]] = [
            .grief: ["Who did you love? Tell me about them — the good parts.", "What's one memory that still makes you smile through the tears?"],
            .anxiety: ["What's the biggest 'what if' circling your mind right now?", "If that worry wasn't there, what would you do with that energy?"],
            .anger: ["What boundary needs to be set that hasn't been set yet?", "If you could say one thing to the person who upset you, what would it be?"],
            .loneliness: ["When's the last time you felt truly seen by someone?", "What would connection look like for you right now?"],
            .selfDoubt: ["Who first planted that seed of doubt in you?", "What would you say to a friend who felt this way about themselves?"],
            .relationships: ["What do you need from that person that you haven't asked for?", "What would healthy look like in that situation?"],
            .general: ["What's one thing you need to hear right now?", "If your soul could talk, what would it say?"],
        ]

        let options = followUps[theme] ?? followUps[.general]!
        let index = (text.hashValue & 0x7FFFFFFF) % options.count
        return options[index]
    }
}
