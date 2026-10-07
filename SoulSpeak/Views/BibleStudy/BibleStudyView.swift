import SwiftUI
import MapKit

/// BibleStudyView — Community Ethiopian Bible Study with interactive features.
/// Based on the Ethiopian Bible (81 books — the oldest and most complete canon).
///
/// Features:
/// - Full book navigation (81 books organized by testament)
/// - Chapter/verse reading view
/// - Interactive historical maps (where events took place)
/// - Timeline of biblical events with historical context
/// - Community study notes
/// - Dr. Hope's spiritual commentary
/// - Search across all books
struct BibleStudyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: BibleTab = .books
    @State private var selectedTestament: Testament = .oldTestament
    @State private var selectedBook: BibleBook? = nil
    @State private var searchText = ""
    @State private var showDrHopeCommentary = false

    enum BibleTab: String, CaseIterable {
        case books = "Books"
        case maps = "Maps"
        case timeline = "Timeline"
        case study = "Study"
    }

    enum Testament: String, CaseIterable {
        case oldTestament = "Old Testament"
        case newTestament = "New Testament"
        case deuterocanon = "Deuterocanon"
        case ethiopianCanon = "Ethiopian Canon"
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                bibleHeader

                // Tab selector
                tabSelector

                // Content
                ScrollView(showsIndicators: false) {
                    switch selectedTab {
                    case .books:
                        booksContent
                    case .maps:
                        mapsContent
                    case .timeline:
                        timelineContent
                    case .study:
                        studyContent
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedBook) { book in
            BibleReaderView(book: book)
        }
    }

    // MARK: - Header
    private var bibleHeader: some View {
        HStack(spacing: 14) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Bible Study")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Ethiopian Canon • 81 Books")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Search
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(BibleTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.4))

                        Rectangle()
                            .fill(selectedTab == tab ? Color(red: 0.85, green: 0.65, blue: 0.2) : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Books Content
    private var booksContent: some View {
        VStack(spacing: 16) {
            // Testament picker
            Picker("Testament", selection: $selectedTestament) {
                ForEach(Testament.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // Book list
            LazyVStack(spacing: 8) {
                ForEach(booksForTestament(selectedTestament)) { book in
                    bookRow(book)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .padding(.top, 12)
    }

    private func bookRow(_ book: BibleBook) -> some View {
        Button(action: { selectedBook = book }) {
            HStack(spacing: 14) {
                // Book number
                Text("\(book.order)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                    .frame(width: 28)

                // Book info
                VStack(alignment: .leading, spacing: 3) {
                    Text(book.name)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Text("\(book.chapters) chapters")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))

                        if let period = book.timePeriod {
                            Text("• \(period)")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.7))
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
            )
        }
    }

    // MARK: - Maps Content
    private var mapsContent: some View {
        VStack(spacing: 16) {
            // Interactive map showing biblical locations
            Map {
                // Key biblical locations
                ForEach(biblicalLocations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        VStack(spacing: 2) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                            Text(location.name)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .padding(.horizontal, 16)

            // Location list
            VStack(alignment: .leading, spacing: 10) {
                Text("Biblical Locations")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)

                ForEach(biblicalLocations) { location in
                    locationRow(location)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.top, 12)
    }

    private func locationRow(_ location: BiblicalLocation) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))

            VStack(alignment: .leading, spacing: 3) {
                Text(location.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(location.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                if let event = location.keyEvent {
                    Text("Key Event: \(event)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.8))
                        .italic()
                }
            }

            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        .padding(.horizontal, 16)
    }

    // MARK: - Timeline Content
    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Biblical Timeline")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Text("From Creation to the Early Church")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Timeline events
            ForEach(Array(timelineEvents.enumerated()), id: \.offset) { index, event in
                timelineRow(event, isLast: index == timelineEvents.count - 1)
            }

            Spacer(minLength: 40)
        }
    }

    private func timelineRow(_ event: TimelineEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline line + dot
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.85, green: 0.65, blue: 0.2))
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }

            // Event content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.period)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                    .textCase(.uppercase)

                Text(event.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                Text(event.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(3)

                if let historicalContext = event.historicalContext {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 9))
                        Text(historicalContext)
                            .font(.system(size: 10))
                            .italic()
                    }
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 2)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Study Content
    private var studyContent: some View {
        VStack(spacing: 16) {
            // Daily verse
            VStack(spacing: 12) {
                Text("Today's Verse")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1)

                Text(dailyVerse.text)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .italic()

                Text("— \(dailyVerse.reference)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)

            // Study topics
            VStack(alignment: .leading, spacing: 12) {
                Text("Study Topics")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                ForEach(studyTopics, id: \.title) { topic in
                    studyTopicRow(topic)
                }
            }
            .padding(.horizontal, 16)

            // Ask Dr. Hope about scripture
            Button(action: { showDrHopeCommentary = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 18))
                    Text("Ask Dr. Hope About Scripture")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(red: 0.7, green: 0.4, blue: 0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.1))
                )
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 40)
        }
        .padding(.top, 12)
    }

    private func studyTopicRow(_ topic: StudyTopic) -> some View {
        HStack(spacing: 12) {
            Image(systemName: topic.icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(topic.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }

    // MARK: - Data

    private func booksForTestament(_ testament: Testament) -> [BibleBook] {
        allBooks.filter { $0.testament == testament }
    }

    private var dailyVerse: (text: String, reference: String) {
        let verses = [
            ("For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", "Jeremiah 29:11"),
            ("The Lord is my shepherd; I shall not want. He makes me lie down in green pastures.", "Psalm 23:1-2"),
            ("I can do all things through Christ who strengthens me.", "Philippians 4:13"),
            ("Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.", "Joshua 1:9"),
            ("Trust in the Lord with all your heart and lean not on your own understanding.", "Proverbs 3:5"),
            ("The Lord is close to the brokenhearted and saves those who are crushed in spirit.", "Psalm 34:18"),
            ("And we know that in all things God works for the good of those who love him.", "Romans 8:28"),
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return verses[day % verses.count]
    }

    private var studyTopics: [StudyTopic] {
        [
            StudyTopic(title: "The Book of Enoch", subtitle: "Ethiopian canon exclusive — angels, prophecy, judgment", icon: "scroll.fill"),
            StudyTopic(title: "Psalms of David", subtitle: "Songs of praise, lament, and worship", icon: "music.note"),
            StudyTopic(title: "Proverbs & Wisdom", subtitle: "Practical wisdom for daily life", icon: "lightbulb.fill"),
            StudyTopic(title: "The Gospels", subtitle: "Life and teachings of Jesus Christ", icon: "heart.fill"),
            StudyTopic(title: "Acts of the Apostles", subtitle: "The early church and its mission", icon: "person.3.fill"),
            StudyTopic(title: "Revelation & Prophecy", subtitle: "End times, visions, and hope", icon: "eye.fill"),
        ]
    }

    private var biblicalLocations: [BiblicalLocation] {
        [
            BiblicalLocation(name: "Jerusalem", coordinate: CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137), description: "Holy city — Temple Mount, crucifixion, resurrection", keyEvent: "Jesus's death and resurrection"),
            BiblicalLocation(name: "Bethlehem", coordinate: CLLocationCoordinate2D(latitude: 31.7054, longitude: 35.2024), description: "Birthplace of Jesus and King David", keyEvent: "Birth of Christ"),
            BiblicalLocation(name: "Nazareth", coordinate: CLLocationCoordinate2D(latitude: 32.6996, longitude: 35.3035), description: "Childhood home of Jesus", keyEvent: "Annunciation to Mary"),
            BiblicalLocation(name: "Egypt", coordinate: CLLocationCoordinate2D(latitude: 29.9792, longitude: 31.1342), description: "Slavery, exodus, flight of the holy family", keyEvent: "The Exodus under Moses"),
            BiblicalLocation(name: "Mt. Sinai", coordinate: CLLocationCoordinate2D(latitude: 28.5394, longitude: 33.9751), description: "Where Moses received the Ten Commandments", keyEvent: "God gives the Law"),
            BiblicalLocation(name: "Babylon", coordinate: CLLocationCoordinate2D(latitude: 32.5425, longitude: 44.4210), description: "Exile of Israel, Daniel in the lion's den", keyEvent: "Babylonian captivity"),
            BiblicalLocation(name: "Ethiopia (Aksum)", coordinate: CLLocationCoordinate2D(latitude: 14.1211, longitude: 38.7468), description: "Queen of Sheba, Ark of the Covenant tradition, early Christianity", keyEvent: "Ark of the Covenant brought to Ethiopia"),
            BiblicalLocation(name: "Jordan River", coordinate: CLLocationCoordinate2D(latitude: 31.8370, longitude: 35.5504), description: "Baptism of Jesus, crossing into the Promised Land", keyEvent: "Baptism of Jesus by John"),
            BiblicalLocation(name: "Sea of Galilee", coordinate: CLLocationCoordinate2D(latitude: 32.8231, longitude: 35.5831), description: "Jesus walked on water, calmed the storm, called disciples", keyEvent: "Jesus walks on water"),
            BiblicalLocation(name: "Rome", coordinate: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), description: "Paul's letters, early church persecution, martyrdom", keyEvent: "Paul's imprisonment and letters"),
        ]
    }

    private var timelineEvents: [TimelineEvent] {
        [
            TimelineEvent(period: "~4000 BC", title: "Creation & The Fall", description: "God creates the world, Adam and Eve in the Garden of Eden. The serpent tempts, sin enters the world.", historicalContext: "Ancient Mesopotamian civilization emerging"),
            TimelineEvent(period: "~2400 BC", title: "The Great Flood", description: "Noah builds the ark. God cleanses the earth. The rainbow covenant is established.", historicalContext: "Egyptian Old Kingdom period"),
            TimelineEvent(period: "~2000 BC", title: "Abraham's Calling", description: "God calls Abraham out of Ur. The covenant of faith begins. Isaac is born.", historicalContext: "Bronze Age, rise of city-states"),
            TimelineEvent(period: "~1500 BC", title: "The Exodus", description: "Moses leads Israel out of Egyptian slavery. Ten plagues. Parting of the Red Sea. Ten Commandments given at Sinai.", historicalContext: "Egyptian New Kingdom, age of pharaohs"),
            TimelineEvent(period: "~1000 BC", title: "King David & Solomon", description: "David slays Goliath, becomes king. Solomon builds the First Temple. Golden age of Israel.", historicalContext: "Iron Age begins worldwide"),
            TimelineEvent(period: "~586 BC", title: "Babylonian Exile", description: "Jerusalem destroyed. Temple burned. Israel taken captive to Babylon. Daniel, Ezekiel prophesy.", historicalContext: "Rise of the Persian Empire"),
            TimelineEvent(period: "~5 BC", title: "Birth of Jesus", description: "The Messiah is born in Bethlehem. Angels appear to shepherds. Wise men follow the star.", historicalContext: "Roman Empire under Augustus"),
            TimelineEvent(period: "~30 AD", title: "Crucifixion & Resurrection", description: "Jesus is crucified in Jerusalem. Three days later, rises from the dead. Appears to over 500 witnesses.", historicalContext: "Roman Empire under Tiberius"),
            TimelineEvent(period: "~33 AD", title: "Pentecost & Early Church", description: "The Holy Spirit descends. 3,000 converted in one day. The church is born and spreads across the Roman world.", historicalContext: "Roman roads enable rapid spread of gospel"),
            TimelineEvent(period: "~50-90 AD", title: "Letters & Revelation", description: "Paul writes letters to churches. John receives the Revelation on Patmos. The New Testament takes shape.", historicalContext: "Destruction of the Second Temple (70 AD)"),
            TimelineEvent(period: "~4th Century", title: "Ethiopian Canon Established", description: "The Ethiopian Orthodox Church preserves the broadest biblical canon — 81 books including Enoch, Jubilees, and others lost to Western churches.", historicalContext: "Christianity becomes official religion of Aksum"),
        ]
    }

    private var allBooks: [BibleBook] {
        // Ethiopian Bible — 81 books (46 OT + 27 NT + 8 Deuterocanonical/Ethiopian)
        var books: [BibleBook] = []
        var order = 1

        // Old Testament (39 standard + 7 additional)
        let otBooks: [(String, Int, String?)] = [
            ("Genesis", 50, "~1450 BC"), ("Exodus", 40, "~1450 BC"), ("Leviticus", 27, "~1450 BC"),
            ("Numbers", 36, "~1450 BC"), ("Deuteronomy", 34, "~1450 BC"), ("Joshua", 24, "~1400 BC"),
            ("Judges", 21, "~1050 BC"), ("Ruth", 4, "~1000 BC"), ("1 Samuel", 31, "~930 BC"),
            ("2 Samuel", 24, "~930 BC"), ("1 Kings", 22, "~560 BC"), ("2 Kings", 25, "~560 BC"),
            ("1 Chronicles", 29, "~450 BC"), ("2 Chronicles", 36, "~450 BC"), ("Ezra", 10, "~450 BC"),
            ("Nehemiah", 13, "~445 BC"), ("Esther", 10, "~470 BC"), ("Job", 42, "~2000 BC"),
            ("Psalms", 150, "~1000 BC"), ("Proverbs", 31, "~950 BC"), ("Ecclesiastes", 12, "~935 BC"),
            ("Song of Solomon", 8, "~960 BC"), ("Isaiah", 66, "~700 BC"), ("Jeremiah", 52, "~626 BC"),
            ("Lamentations", 5, "~586 BC"), ("Ezekiel", 48, "~592 BC"), ("Daniel", 12, "~536 BC"),
            ("Hosea", 14, "~755 BC"), ("Joel", 3, "~835 BC"), ("Amos", 9, "~760 BC"),
            ("Obadiah", 1, "~586 BC"), ("Jonah", 4, "~760 BC"), ("Micah", 7, "~700 BC"),
            ("Nahum", 3, "~663 BC"), ("Habakkuk", 3, "~609 BC"), ("Zephaniah", 3, "~635 BC"),
            ("Haggai", 2, "~520 BC"), ("Zechariah", 14, "~520 BC"), ("Malachi", 4, "~430 BC"),
        ]
        for (name, ch, period) in otBooks {
            books.append(BibleBook(order: order, name: name, chapters: ch, testament: .oldTestament, timePeriod: period))
            order += 1
        }

        // New Testament (27 books)
        let ntBooks: [(String, Int, String?)] = [
            ("Matthew", 28, "~60 AD"), ("Mark", 16, "~55 AD"), ("Luke", 24, "~60 AD"),
            ("John", 21, "~90 AD"), ("Acts", 28, "~63 AD"), ("Romans", 16, "~57 AD"),
            ("1 Corinthians", 16, "~55 AD"), ("2 Corinthians", 13, "~56 AD"), ("Galatians", 6, "~49 AD"),
            ("Ephesians", 6, "~60 AD"), ("Philippians", 4, "~61 AD"), ("Colossians", 4, "~60 AD"),
            ("1 Thessalonians", 5, "~51 AD"), ("2 Thessalonians", 3, "~51 AD"), ("1 Timothy", 6, "~64 AD"),
            ("2 Timothy", 4, "~67 AD"), ("Titus", 3, "~64 AD"), ("Philemon", 1, "~60 AD"),
            ("Hebrews", 13, "~68 AD"), ("James", 5, "~49 AD"), ("1 Peter", 5, "~64 AD"),
            ("2 Peter", 3, "~67 AD"), ("1 John", 5, "~90 AD"), ("2 John", 1, "~90 AD"),
            ("3 John", 1, "~90 AD"), ("Jude", 1, "~65 AD"), ("Revelation", 22, "~95 AD"),
        ]
        for (name, ch, period) in ntBooks {
            books.append(BibleBook(order: order, name: name, chapters: ch, testament: .newTestament, timePeriod: period))
            order += 1
        }

        // Deuterocanonical (included in Ethiopian canon)
        let dcBooks: [(String, Int, String?)] = [
            ("Tobit", 14, "~200 BC"), ("Judith", 16, "~150 BC"), ("Wisdom of Solomon", 19, "~100 BC"),
            ("Sirach (Ecclesiasticus)", 51, "~180 BC"), ("Baruch", 6, "~580 BC"),
            ("1 Maccabees", 16, "~100 BC"), ("2 Maccabees", 15, "~124 BC"),
        ]
        for (name, ch, period) in dcBooks {
            books.append(BibleBook(order: order, name: name, chapters: ch, testament: .deuterocanon, timePeriod: period))
            order += 1
        }

        // Ethiopian Canon exclusive books
        let ethBooks: [(String, Int, String?)] = [
            ("1 Enoch (Ethiopic)", 108, "~300 BC"), ("Jubilees", 50, "~150 BC"),
            ("1 Meqabyan", 36, "~5th C"), ("2 Meqabyan", 20, "~5th C"), ("3 Meqabyan", 17, "~5th C"),
            ("Paralipomena of Baruch", 9, "~200 AD"), ("Josippon", 96, "~10th C"),
            ("Broader Canon Epistles", 8, "~4th C"),
        ]
        for (name, ch, period) in ethBooks {
            books.append(BibleBook(order: order, name: name, chapters: ch, testament: .ethiopianCanon, timePeriod: period))
            order += 1
        }

        return books
    }
}

// MARK: - Models
struct BibleBook: Identifiable {
    let id = UUID()
    let order: Int
    let name: String
    let chapters: Int
    let testament: BibleStudyView.Testament
    let timePeriod: String?
}

struct BiblicalLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String
    let keyEvent: String?
}

struct TimelineEvent {
    let period: String
    let title: String
    let description: String
    let historicalContext: String?
}

struct StudyTopic {
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Bible Reader View (Chapter/Verse display)
struct BibleReaderView: View {
    let book: BibleBook
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChapter = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.04, blue: 0.08)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Chapter selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(1...book.chapters, id: \.self) { ch in
                                Button(action: { selectedChapter = ch }) {
                                    Text("\(ch)")
                                        .font(.system(size: 12, weight: selectedChapter == ch ? .bold : .regular))
                                        .foregroundColor(selectedChapter == ch ? .white : .white.opacity(0.4))
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(selectedChapter == ch ? Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.3) : Color.white.opacity(0.05))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Chapter content placeholder
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(book.name) — Chapter \(selectedChapter)")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.white)

                            if let period = book.timePeriod {
                                Text("Written: \(period)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.7))
                            }

                            Text("Full chapter text will be loaded from the Ethiopian Bible database. This section supports offline reading, verse highlighting, and Dr. Hope's spiritual commentary on each passage.")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(6)
                                .padding(.top, 12)

                            // Sample verses to show format
                            ForEach(1...5, id: \.self) { verse in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(verse)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                                        .frame(width: 20)
                                    Text(sampleVerse(book: book.name, chapter: selectedChapter, verse: verse))
                                        .font(.system(size: 15, design: .serif))
                                        .foregroundColor(.white.opacity(0.85))
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    private func sampleVerse(book: String, chapter: Int, verse: Int) -> String {
        // Placeholder verses — full content would come from a database
        let samples = [
            "In the beginning God created the heavens and the earth.",
            "And the earth was without form, and void; and darkness was upon the face of the deep.",
            "And God said, Let there be light: and there was light.",
            "And God saw the light, that it was good: and God divided the light from the darkness.",
            "And God called the light Day, and the darkness he called Night.",
        ]
        return samples[(verse - 1) % samples.count]
    }
}
