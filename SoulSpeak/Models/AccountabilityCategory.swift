import SwiftUI

/// All available accountability categories the user can select.
/// These customize notifications, AI context, and support resources.
enum AccountabilityCategory: String, CaseIterable, Identifiable {
    case suicidalThoughts = "Suicidal Thoughts"
    case depression = "Depression"
    case anxiety = "Anxiety"
    case angerManagement = "Anger Management"
    case pornography = "Pornography"
    case alcoholism = "Alcoholism"
    case drugAddiction = "Drug Addiction"
    case gambling = "Gambling"
    case eatingDisorder = "Eating Disorder"
    case selfHarm = "Self-Harm"
    case grief = "Grief & Loss"
    case loneliness = "Loneliness"
    case trauma = "Trauma / PTSD"
    case relationships = "Relationships"
    case smoking = "Smoking / Vaping"
    case socialMedia = "Social Media Addiction"
    case lowSelfEsteem = "Low Self-Esteem"
    case insomnia = "Insomnia / Sleep"
    case stress = "Chronic Stress"
    case spiritualGrowth = "Spiritual Growth"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .suicidalThoughts: return "heart.slash.fill"
        case .depression: return "cloud.rain.fill"
        case .anxiety: return "bolt.heart.fill"
        case .angerManagement: return "flame.fill"
        case .pornography: return "eye.slash.fill"
        case .alcoholism: return "drop.fill"
        case .drugAddiction: return "pills.fill"
        case .gambling: return "dice.fill"
        case .eatingDisorder: return "fork.knife"
        case .selfHarm: return "bandage.fill"
        case .grief: return "heart.fill"
        case .loneliness: return "person.fill.questionmark"
        case .trauma: return "brain.head.profile"
        case .relationships: return "person.2.fill"
        case .smoking: return "smoke.fill"
        case .socialMedia: return "iphone"
        case .lowSelfEsteem: return "person.crop.circle.badge.minus"
        case .insomnia: return "moon.zzz.fill"
        case .stress: return "waveform.path.ecg"
        case .spiritualGrowth: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .suicidalThoughts: return .red
        case .depression: return Color(red: 0.4, green: 0.5, blue: 0.8)
        case .anxiety: return .orange
        case .angerManagement: return Color(red: 0.9, green: 0.3, blue: 0.2)
        case .pornography: return Color(red: 0.6, green: 0.3, blue: 0.6)
        case .alcoholism: return Color(red: 0.5, green: 0.7, blue: 0.9)
        case .drugAddiction: return Color(red: 0.8, green: 0.4, blue: 0.4)
        case .gambling: return Color(red: 0.9, green: 0.7, blue: 0.2)
        case .eatingDisorder: return Color(red: 0.7, green: 0.5, blue: 0.3)
        case .selfHarm: return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .grief: return Color(red: 0.5, green: 0.4, blue: 0.7)
        case .loneliness: return Color(red: 0.4, green: 0.6, blue: 0.7)
        case .trauma: return Color(red: 0.6, green: 0.4, blue: 0.5)
        case .relationships: return Color(red: 0.8, green: 0.5, blue: 0.6)
        case .smoking: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .socialMedia: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .lowSelfEsteem: return Color(red: 0.6, green: 0.5, blue: 0.4)
        case .insomnia: return Color(red: 0.3, green: 0.3, blue: 0.6)
        case .stress: return Color(red: 0.7, green: 0.5, blue: 0.3)
        case .spiritualGrowth: return Color(red: 0.9, green: 0.75, blue: 0.3)
        }
    }

    /// Notification messages specific to this category.
    var checkInMessages: [String] {
        switch self {
        case .suicidalThoughts:
            return [
                "Hey baby — Dr. Hope checking in. How's your spirit today? You matter. You are loved.",
                "Champ, just making sure you're okay. Remember: bad moments don't mean a bad life.",
                "Have you talked to someone today? You don't have to carry this alone. We're here.",
            ]
        case .depression:
            return [
                "Sugar, even getting out of bed counts as a win today. Did you get some sunshine?",
                "Depression lies. It says nothing will help. But you showed up yesterday. Show up again today.",
                "One small thing, baby. Just one. Brush your teeth. Walk to the mailbox. That's enough.",
            ]
        case .anxiety:
            return [
                "Breathe, Champ. In for 4... hold for 4... out for 4. You're safe right now.",
                "Is your mind racing? Ground yourself: name 5 things you can see. You're here. You're okay.",
                "Baby, worry is just imagination pointed the wrong way. Let's redirect it. Come journal.",
            ]
        case .angerManagement:
            return [
                "Feeling heated today? Before you react — pause. Take 10 breaths. Then decide.",
                "Champ, anger is information, not instruction. What's it trying to tell you?",
                "Count to 10 before you speak. Count to 100 before you act. You're in control.",
            ]
        case .pornography:
            return [
                "Champ — how are your eyes today? Remember: what you feed grows. Starve what doesn't serve you.",
                "Feeling tempted? Get up. Move your body. Change the environment. You're stronger than the urge.",
                "Every day you choose differently is a day you reclaim your mind. Keep choosing YOU.",
            ]
        case .alcoholism:
            return [
                "One day at a time, Champ. You don't have to be sober forever — just today. Can you do today?",
                "Baby, that craving? It'll peak and pass in 15 minutes. Distract yourself. Call someone. You got this.",
                "Your sobriety is the bravest thing you do every single day. Don't forget that.",
            ]
        case .drugAddiction:
            return [
                "Champ — the old you would have given in by now. But you're not that person anymore.",
                "That urge is a test, not a command. You've passed this test before. Pass it again.",
                "Sugar, every clean day is a deposit in your future. Don't withdraw. Keep building.",
            ]
        case .gambling:
            return [
                "Champ, the house always wins. But YOU win every day you don't play. That's the real jackpot.",
                "Feeling the itch? Delete the app. Block the site. Call someone. Do it NOW before it gets louder.",
                "The money you save by not gambling? That's freedom money. Stack it up.",
            ]
        case .eatingDisorder:
            return [
                "Baby, your body is not your enemy. It's your home. Have you nourished it today?",
                "Food is not punishment or reward — it's fuel. Eat something gentle today.",
                "You are more than a number on a scale. So much more. Remember that.",
            ]
        case .selfHarm:
            return [
                "Baby, put ice on your wrist instead. The cold gives the same shock without the damage. You're safe.",
                "Your body has carried you through everything. Be gentle with it today.",
                "When the urge comes, write it down instead. Let the pen bleed, not your skin.",
            ]
        case .grief:
            return [
                "It's okay to miss them today. Grief is just love with nowhere to go. Let it flow.",
                "Sugar, you don't have to be 'over it' on anyone's timeline. Heal at YOUR pace.",
                "Talk to them today. Out loud. They're still listening.",
            ]
        case .loneliness:
            return [
                "Feeling alone? You're not. God is with you. Dr. Hope is here. Text someone right now.",
                "Champ — isolation is the enemy's favorite weapon. Fight it. Go outside. Be around people.",
                "You are seen. You are known. You are not forgotten. Open the app and talk to us.",
            ]
        case .trauma:
            return [
                "If today feels heavy, remember: you survived 100% of your worst days. This one too.",
                "Baby, your past happened TO you, not because of you. You're healing. Keep going.",
                "Flashbacks lie about time. You're HERE now. You're SAFE now. Touch something real.",
            ]
        case .relationships:
            return [
                "Have you communicated your needs today? You deserve to be heard, not just tolerated.",
                "Boundaries aren't walls — they're doors with locks. You choose who gets the key.",
                "Champ, healthy relationships start with how you treat yourself. How'd you treat you today?",
            ]
        case .smoking:
            return [
                "Craving a smoke? Chew gum. Drink cold water. Take 5 deep breaths. The craving will pass.",
                "Every cigarette/vape you skip is a win for your lungs, your wallet, and your future.",
                "Champ, your body is healing from the FIRST DAY you quit. Don't reset that clock.",
            ]
        case .socialMedia:
            return [
                "How much time on your phone today, Champ? Set a timer. When it rings — put it DOWN.",
                "Comparison is the thief of joy. What you see online isn't real life. YOUR life is real.",
                "Take a 30-minute break from screens. Read. Walk. Breathe. Be present where you ARE.",
            ]
        case .lowSelfEsteem:
            return [
                "Say one kind thing about yourself right now. Out loud. You DESERVE your own kindness.",
                "Baby, you are not what people said about you. You are what GOD says about you.",
                "Look in the mirror. That person has survived everything thrown at them. Respect that warrior.",
            ]
        case .insomnia:
            return [
                "Put the phone down, sugar. Blue light steals your sleep. Your body needs rest tonight.",
                "Try this: breathe in for 4, hold for 7, out for 8. Repeat. Your body will follow.",
                "Can't sleep? Don't fight it. Get up, journal for 5 minutes, then lay back down.",
            ]
        case .stress:
            return [
                "What's ONE thing on your plate you can let go of today? You can't carry it all.",
                "Champ, stress means you care. But caring too much without rest? That's burnout. Slow down.",
                "Take 60 seconds right now. Close your eyes. Breathe. Nothing else matters for this minute.",
            ]
        case .spiritualGrowth:
            return [
                "Have you read your Word today? Even one verse plants a seed.",
                "Baby, growth isn't always forward. Sometimes it's going deeper. Root yourself today.",
                "Talk to God today like He's your friend. Because He is. No fancy words needed.",
            ]
        }
    }
}
