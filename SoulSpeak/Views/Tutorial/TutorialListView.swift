import SwiftUI

/// TutorialListView — Available from Settings. Users can rewatch any tutorial.
/// Shows all app sections with a "Watch Tutorial" button for each.
struct TutorialListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingTutorial: TutorialType? = nil

    private let tutorials: [(type: TutorialType, icon: String, color: Color)] = [
        (.journal, "mic.fill", Color(red: 0.8, green: 0.4, blue: 0.9)),
        (.talk, "bubble.left.and.bubble.right.fill", Color(red: 0.3, green: 0.6, blue: 1.0)),
        (.vent, "flame.fill", Color(red: 1.0, green: 0.4, blue: 0.15)),
        (.centered, "leaf.circle.fill", Color(red: 0.3, green: 0.85, blue: 0.5)),
        (.mirror, "person.crop.circle", Color(red: 0.85, green: 0.75, blue: 1.0)),
        (.mood, "face.smiling.fill", Color(red: 1.0, green: 0.75, blue: 0.2)),
        (.accountability, "calendar.badge.clock", Color(red: 0.3, green: 0.7, blue: 0.9)),
        (.prescriptions, "pill.fill", Color(red: 0.4, green: 0.8, blue: 0.6)),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.1)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Learn how to use each feature")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        // Tutorial cards
                        ForEach(tutorials, id: \.type.title) { item in
                            tutorialRow(type: item.type, icon: item.icon, color: item.color)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Tutorials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .fullScreenCover(item: $showingTutorial) { type in
                TutorialView(tutorial: type, onComplete: {
                    showingTutorial = nil
                })
            }
        }
    }

    private func tutorialRow(type: TutorialType, icon: String, color: Color) -> some View {
        Button(action: { showingTutorial = type }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(type.steps.count) steps")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Watch")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(color.opacity(0.12)))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

// Make TutorialType identifiable for fullScreenCover
extension TutorialType: Identifiable {
    var id: String { title }
}
