import SwiftUI

// MARK: - Affliction Model
/// Each affliction represents a structured course the user can work through.
/// Courses contain multiple lessons with reflective exercises.
struct Affliction: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let category: AfflictionCategory
    let lessonCount: Int
    let description: String
    let dailyAffirmation: String
}

enum AfflictionCategory: String, CaseIterable {
    case behavioral = "Behavioral"
    case emotional = "Emotional"
    case relational = "Relational"
    case identity = "Identity"
    case lifeSkills = "Life Skills"
    case parenting = "Parenting"

    var icon: String {
        switch self {
        case .behavioral: return "arrow.triangle.2.circlepath"
        case .emotional: return "heart.slash"
        case .relational: return "person.2"
        case .identity: return "person.crop.circle.badge.questionmark"
        case .lifeSkills: return "star.circle.fill"
        case .parenting: return "figure.and.child.holdinghands"
        }
    }

    var color: Color {
        switch self {
        case .behavioral: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .emotional: return Color(red: 0.4, green: 0.5, blue: 0.9)
        case .relational: return Color(red: 0.8, green: 0.4, blue: 0.6)
        case .identity: return Color(red: 0.5, green: 0.8, blue: 0.6)
        case .lifeSkills: return Color(red: 0.3, green: 0.7, blue: 0.8)
        case .parenting: return Color(red: 0.9, green: 0.6, blue: 0.4)
        }
    }
}

// MARK: - Lesson Model
struct MirrorLesson: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let title: String
    let type: LessonType
    let duration: String
    let prompts: [String]
    let affirmation: String
    let isCompleted: Bool

    enum LessonType: String {
        case reflection = "Self-Reflection"
        case exercise = "Exercise"
        case journaling = "Journaling"
        case confrontation = "Confrontation"
        case meditation = "Guided Meditation"
        case awareness = "Awareness"
    }
}

// MARK: - Mirror View (Main Hub)
/// "Mirror" — Look at yourself honestly. Confront your afflictions.
/// Structured self-paced courses inspired by Omna's therapy-style approach.
/// Themed after "Man in the Mirror" — real change starts with looking at yourself.
///
/// Premium feature — the money-maker of MySoulSpeak.
struct MirrorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitService.shared
    @State private var selectedCategory: AfflictionCategory = .behavioral
    @State private var selectedAffliction: Affliction? = nil
    @State private var showPaywall = false
    @State private var showProgress = false
    @State private var searchText = ""
    @AppStorage("mirrorOnboardingComplete") private var onboardingComplete = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                mirrorHeader

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Quote banner
                        quoteBanner

                        // Category selector
                        categorySelector

                        // Affliction cards
                        afflictionGrid

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .sheet(item: $selectedAffliction) { affliction in
            if store.isPremium {
                MirrorSessionView(affliction: affliction)
            } else {
                PaywallView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showProgress) {
            MirrorProgressView()
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.04, blue: 0.08),
                Color(red: 0.08, green: 0.06, blue: 0.14),
                Color(red: 0.05, green: 0.04, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Header
    private var mirrorHeader: some View {
        HStack(spacing: 14) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("The Mirror")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Look at yourself. Start the change.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Progress button
            Button(action: { showProgress = true }) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }

            // Premium badge
            if !store.isPremium {
                Button(action: { showPaywall = true }) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
                        .padding(8)
                        .background(Circle().fill(Color(red: 0.95, green: 0.78, blue: 0.3).opacity(0.15)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .padding(.top, 50)
    }

    // MARK: - Quote Banner
    private var quoteBanner: some View {
        VStack(spacing: 12) {
            // Mirror reflection icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "person.crop.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("\"I'm starting with the man in the mirror.\nI'm asking him to change his ways.\"")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .italic()
                .lineSpacing(4)

            Text("Your journey to change begins with honest self-reflection.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Category Selector
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AfflictionCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 11))
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color.opacity(0.3) : Color.white.opacity(0.05))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == category ? category.color.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Affliction Grid
    private var afflictionGrid: some View {
        LazyVStack(spacing: 14) {
            ForEach(filteredAfflictions) { affliction in
                afflictionCard(affliction)
            }
        }
        .padding(.horizontal, 20)
    }

    private var filteredAfflictions: [Affliction] {
        allAfflictions.filter { $0.category == selectedCategory }
    }

    // MARK: - Affliction Card
    private func afflictionCard(_ affliction: Affliction) -> some View {
        Button(action: { selectedAffliction = affliction }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(affliction.color.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: affliction.icon)
                        .font(.system(size: 22))
                        .foregroundColor(affliction.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(affliction.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(affliction.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(affliction.color.opacity(0.8))

                    // Course info
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 9))
                            Text("\(affliction.lessonCount) lessons")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.4))

                        if !store.isPremium {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                Text("Premium")
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3).opacity(0.7))
                        }
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(affliction.color.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - All Afflictions Data
    private var allAfflictions: [Affliction] {
        [
            // BEHAVIORAL
            Affliction(name: "Procrastination", subtitle: "Break the delay cycle", icon: "clock.arrow.circlepath", color: Color(red: 0.9, green: 0.6, blue: 0.2), category: .behavioral, lessonCount: 14, description: "Understand why you avoid and learn to take action despite resistance.", dailyAffirmation: "I choose action over avoidance. Each step forward counts."),

            Affliction(name: "Pornography Addiction", subtitle: "Reclaim your mind", icon: "eye.slash.fill", color: Color(red: 0.7, green: 0.3, blue: 0.3), category: .behavioral, lessonCount: 21, description: "Break free from compulsive patterns and rebuild healthy connections.", dailyAffirmation: "I am more than my urges. I choose real connection over illusion."),

            Affliction(name: "Self-Harm", subtitle: "Find safer outlets", icon: "bandage.fill", color: Color(red: 0.6, green: 0.3, blue: 0.5), category: .behavioral, lessonCount: 18, description: "Learn to sit with pain and discover healthier ways to cope.", dailyAffirmation: "My pain is valid. I deserve gentleness, not punishment."),

            Affliction(name: "Substance Dependency", subtitle: "One day at a time", icon: "pills.fill", color: Color(red: 0.5, green: 0.4, blue: 0.7), category: .behavioral, lessonCount: 21, description: "Build awareness around triggers and develop resilience against cravings.", dailyAffirmation: "I am choosing sobriety. Every clean moment is a victory."),

            Affliction(name: "Disordered Eating", subtitle: "Heal your relationship with food", icon: "fork.knife", color: Color(red: 0.8, green: 0.5, blue: 0.4), category: .behavioral, lessonCount: 16, description: "Unpack emotional eating, restriction, and body image struggles.", dailyAffirmation: "My body deserves nourishment, not punishment."),

            Affliction(name: "Social Media Addiction", subtitle: "Disconnect to reconnect", icon: "iphone.slash", color: Color(red: 0.3, green: 0.6, blue: 0.8), category: .behavioral, lessonCount: 10, description: "Break the scroll cycle and reclaim your time and attention.", dailyAffirmation: "My worth is not measured in likes. I am enough offline."),

            // EMOTIONAL
            Affliction(name: "Depression", subtitle: "Lift the weight", icon: "cloud.rain.fill", color: Color(red: 0.4, green: 0.5, blue: 0.8), category: .emotional, lessonCount: 21, description: "Gently work through darkness with daily micro-steps toward light.", dailyAffirmation: "The darkness is temporary. I will feel lightness again."),

            Affliction(name: "Anxiety & Worry", subtitle: "Quiet the racing mind", icon: "tornado", color: Color(red: 0.6, green: 0.5, blue: 0.9), category: .emotional, lessonCount: 16, description: "Learn to observe anxious thoughts without being controlled by them.", dailyAffirmation: "I release what I cannot control. This moment is enough."),

            Affliction(name: "Anger Management", subtitle: "Channel the fire", icon: "flame.fill", color: Color(red: 0.9, green: 0.35, blue: 0.2), category: .emotional, lessonCount: 14, description: "Transform destructive rage into constructive power.", dailyAffirmation: "My anger is information, not instruction. I choose my response."),

            Affliction(name: "Grief & Loss", subtitle: "Honor what was", icon: "leaf.fill", color: Color(red: 0.4, green: 0.6, blue: 0.5), category: .emotional, lessonCount: 18, description: "Move through loss at your own pace without rushing healing.", dailyAffirmation: "Grief is love with nowhere to go. I honor what I've lost."),

            Affliction(name: "Shame & Guilt", subtitle: "Unburden yourself", icon: "lock.open.fill", color: Color(red: 0.6, green: 0.4, blue: 0.4), category: .emotional, lessonCount: 14, description: "Separate who you are from what you've done. Find self-forgiveness.", dailyAffirmation: "I am not my mistakes. I am growing and learning."),

            Affliction(name: "Loneliness", subtitle: "You are not invisible", icon: "person.fill.questionmark", color: Color(red: 0.5, green: 0.5, blue: 0.7), category: .emotional, lessonCount: 12, description: "Reconnect with yourself and learn to build meaningful bonds.", dailyAffirmation: "I am worthy of connection. My presence matters."),

            // RELATIONAL
            Affliction(name: "Co-Dependency", subtitle: "Find yourself again", icon: "person.2.slash.fill", color: Color(red: 0.7, green: 0.4, blue: 0.5), category: .relational, lessonCount: 16, description: "Learn where you end and others begin. Reclaim your identity.", dailyAffirmation: "I am whole on my own. My happiness is not someone else's responsibility."),

            Affliction(name: "Childhood Trauma", subtitle: "Heal your inner child", icon: "figure.and.child.holdinghands", color: Color(red: 0.6, green: 0.5, blue: 0.8), category: .relational, lessonCount: 21, description: "Revisit and reparent the wounded parts of yourself with compassion.", dailyAffirmation: "The child in me deserves the love they never got. I give it now."),

            Affliction(name: "Toxic Relationships", subtitle: "Break the pattern", icon: "link.badge.plus", color: Color(red: 0.8, green: 0.3, blue: 0.4), category: .relational, lessonCount: 14, description: "Recognize unhealthy dynamics and learn to set firm boundaries.", dailyAffirmation: "I deserve relationships that feel safe. I choose peace over chaos."),

            Affliction(name: "People Pleasing", subtitle: "Your needs matter too", icon: "theatermasks.fill", color: Color(red: 0.7, green: 0.6, blue: 0.3), category: .relational, lessonCount: 12, description: "Stop abandoning yourself to keep others comfortable.", dailyAffirmation: "Saying no is an act of self-love. I matter too."),

            Affliction(name: "Trust Issues", subtitle: "Open safely", icon: "shield.slash.fill", color: Color(red: 0.5, green: 0.5, blue: 0.6), category: .relational, lessonCount: 14, description: "Rebuild trust in yourself and learn to discern who is safe.", dailyAffirmation: "I can protect myself AND let love in. Both are possible."),

            Affliction(name: "Abandonment Fear", subtitle: "You won't be left behind", icon: "door.left.hand.open", color: Color(red: 0.6, green: 0.4, blue: 0.7), category: .relational, lessonCount: 14, description: "Address the deep fear of being left and build secure attachment.", dailyAffirmation: "I am worthy of staying for. My presence is a gift."),

            // IDENTITY
            Affliction(name: "Identity Conflict", subtitle: "Find your true self", icon: "person.crop.circle.badge.questionmark", color: Color(red: 0.5, green: 0.7, blue: 0.6), category: .identity, lessonCount: 18, description: "Reconnect with who you truly are beneath the confusion. For those questioning identity decisions and wanting to return to their authentic self.", dailyAffirmation: "I am allowed to rediscover who I am. My truth is mine to find."),

            Affliction(name: "Low Self-Worth", subtitle: "You are enough", icon: "star.slash.fill", color: Color(red: 0.8, green: 0.5, blue: 0.3), category: .identity, lessonCount: 16, description: "Challenge the lies you believe about yourself and rebuild from truth.", dailyAffirmation: "I am valuable. My existence alone proves my worth."),

            Affliction(name: "Perfectionism", subtitle: "Good enough IS enough", icon: "checkmark.seal.fill", color: Color(red: 0.4, green: 0.6, blue: 0.7), category: .identity, lessonCount: 12, description: "Release the impossible standard and embrace imperfect progress.", dailyAffirmation: "Done is better than perfect. I release the need to be flawless."),

            Affliction(name: "Imposter Syndrome", subtitle: "You belong here", icon: "person.crop.circle.badge.exclamationmark", color: Color(red: 0.6, green: 0.5, blue: 0.8), category: .identity, lessonCount: 10, description: "Recognize your achievements and silence the voice that says you're a fraud.", dailyAffirmation: "I earned my place. I am not fooling anyone — I am capable."),

            Affliction(name: "Purpose & Direction", subtitle: "Find your why", icon: "compass.drawing", color: Color(red: 0.4, green: 0.7, blue: 0.5), category: .identity, lessonCount: 14, description: "Discover clarity when life feels aimless and you've lost your path.", dailyAffirmation: "My purpose is unfolding. I trust the process of becoming."),

            // LIFE SKILLS
            Affliction(name: "Speak with Confidence", subtitle: "Find your voice", icon: "mic.circle.fill", color: Color(red: 0.3, green: 0.7, blue: 0.8), category: .lifeSkills, lessonCount: 18, description: "Overcome stuttering, social anxiety in speech, and fear of public speaking. Learn to express yourself clearly and powerfully without hesitation.", dailyAffirmation: "My voice matters. I speak with clarity and power."),

            Affliction(name: "Trust Recovery Plan", subtitle: "Rebuild after betrayal", icon: "shield.checkered", color: Color(red: 0.5, green: 0.6, blue: 0.8), category: .lifeSkills, lessonCount: 16, description: "A structured plan to rebuild trust — in yourself and others — after it's been broken. Learn to discern who is safe while staying open to connection.", dailyAffirmation: "I can heal from betrayal. Trust is rebuilt one honest moment at a time."),

            Affliction(name: "Emotional Overload Plan", subtitle: "When it's all too much", icon: "bolt.heart.fill", color: Color(red: 0.8, green: 0.4, blue: 0.5), category: .lifeSkills, lessonCount: 14, description: "A crisis plan for when emotions hit all at once. Learn to decompress, prioritize, and process overwhelming feelings without shutting down or exploding.", dailyAffirmation: "I can feel deeply AND stay grounded. One feeling at a time."),

            Affliction(name: "AAA Support Plan", subtitle: "Addiction & Accountability", icon: "person.3.fill", color: Color(red: 0.6, green: 0.5, blue: 0.3), category: .lifeSkills, lessonCount: 21, description: "A comprehensive addiction accountability plan inspired by 12-step principles. Daily check-ins, trigger identification, sponsor communication, and relapse prevention.", dailyAffirmation: "One day at a time. I choose recovery today. Every moment counts."),

            Affliction(name: "Motivational Balance Plan", subtitle: "Stay driven without burnout", icon: "battery.75percent", color: Color(red: 0.4, green: 0.8, blue: 0.5), category: .lifeSkills, lessonCount: 12, description: "Find the balance between ambition and rest. Learn to stay motivated without grinding yourself into exhaustion. Sustainable drive, not burnout.", dailyAffirmation: "I can be ambitious AND rested. Balance is not laziness."),

            Affliction(name: "Financial Wellness", subtitle: "Master your money mindset", icon: "dollarsign.circle.fill", color: Color(red: 0.3, green: 0.7, blue: 0.4), category: .lifeSkills, lessonCount: 16, description: "Heal your relationship with money. Overcome financial anxiety, debt shame, spending triggers, and build confidence in managing your resources.", dailyAffirmation: "I am capable of financial peace. Money is a tool, not my master."),

            Affliction(name: "Career Transition", subtitle: "Navigate change with confidence", icon: "arrow.triangle.swap", color: Color(red: 0.5, green: 0.5, blue: 0.9), category: .lifeSkills, lessonCount: 14, description: "Whether you're changing careers, starting over, or feeling stuck — this plan helps you navigate uncertainty and build toward what's next.", dailyAffirmation: "My next chapter is being written. Change is my opportunity."),

            // PARENTING
            Affliction(name: "Single Mother Support", subtitle: "You're stronger than you know", icon: "figure.stand.dress", color: Color(red: 0.9, green: 0.5, blue: 0.6), category: .parenting, lessonCount: 21, description: "A comprehensive support plan for single mothers. Managing overwhelm, co-parenting boundaries, self-care when there's no time, financial planning, raising confident children alone, and finding community.", dailyAffirmation: "I am enough for my children. My love is not halved — it is doubled."),

            Affliction(name: "Single Father Support", subtitle: "Show up fully", icon: "figure.stand", color: Color(red: 0.3, green: 0.6, blue: 0.8), category: .parenting, lessonCount: 21, description: "A dedicated support plan for single fathers. Emotional availability, work-life balance, navigating custody, being both nurturing AND strong, and building a stable home alone.", dailyAffirmation: "My presence is my children's foundation. I show up fully every day."),

            Affliction(name: "Parental Support Plan", subtitle: "Become the parent you needed", icon: "figure.2.and.child.holdinghands", color: Color(red: 0.7, green: 0.5, blue: 0.4), category: .parenting, lessonCount: 18, description: "Break generational cycles. Learn to parent with intention — not just reaction. Covers emotional regulation, communication with kids, setting boundaries with love, and healing YOUR inner child while raising theirs.", dailyAffirmation: "I am breaking cycles. My children will inherit healing, not hurt."),

            Affliction(name: "Co-Parenting Peace", subtitle: "Kids first, ego second", icon: "arrow.left.arrow.right.circle.fill", color: Color(red: 0.5, green: 0.7, blue: 0.5), category: .parenting, lessonCount: 14, description: "Navigate co-parenting with a difficult ex. Learn to communicate without conflict, set boundaries, protect your children from adult drama, and find peace in shared responsibility.", dailyAffirmation: "My children's peace is more important than being right."),

            Affliction(name: "Teen Parent Guide", subtitle: "Young doesn't mean incapable", icon: "person.crop.circle.badge.plus", color: Color(red: 0.8, green: 0.6, blue: 0.3), category: .parenting, lessonCount: 16, description: "Support for young parents who are still growing themselves. Balancing personal development with parenthood, building support systems, and proving that age doesn't define capability.", dailyAffirmation: "My age doesn't limit my love. I am growing alongside my child."),
        ]
    }
}
