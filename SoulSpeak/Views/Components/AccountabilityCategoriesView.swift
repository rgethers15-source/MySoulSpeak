import SwiftUI
import SwiftData

/// Accountability Categories — User selects which areas they need help with.
/// This customizes their check-in notifications, AI responses, and support.
struct AccountabilityCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var selectedCategories: Set<AccountabilityCategory> = []
    @State private var showSaved = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.14),
                        Color(red: 0.12, green: 0.08, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Category grid
                        categoryGrid

                        // Save button
                        saveButton

                        // Privacy note
                        privacyNote

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }

                if showSaved {
                    savedOverlay
                }
            }
            .navigationTitle("Accountability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear { loadExisting() }
        }
    }


    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 0.7, green: 0.4, blue: 0.8))

            Text("What do you need\nhelp with?")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Select all that apply. This stays private and helps\nus personalize your check-ins and support.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(AccountabilityCategory.allCases, id: \.self) { category in
                categoryCard(category)
            }
        }
    }

    private func categoryCard(_ category: AccountabilityCategory) -> some View {
        let isSelected = selectedCategories.contains(category)

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedCategories.remove(category)
                } else {
                    selectedCategories.insert(category)
                }
            }
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color.opacity(0.2) : Color.white.opacity(0.04))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? category.color : .white.opacity(0.4))
                }

                Text(category.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? category.color.opacity(0.5) : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveCategories) {
            Text("Save My Categories")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedCategories.isEmpty
                              ? AnyShapeStyle(Color.white.opacity(0.1))
                              : AnyShapeStyle(LinearGradient(colors: [Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.5, green: 0.25, blue: 0.7)], startPoint: .leading, endPoint: .trailing)))
                )
        }
        .disabled(selectedCategories.isEmpty)
        .padding(.top, 8)
    }

    // MARK: - Privacy Note
    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
            Text("This information stays on your device. Never shared.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Saved Overlay
    private var savedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.5))

            Text("Saved!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("Your check-ins and AI support\nwill be customized for you.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.9)))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions
    private func loadExisting() {
        if let p = profile {
            selectedCategories = Set(p.accountabilityCategories.compactMap { AccountabilityCategory(rawValue: $0) })
        }
    }

    private func saveCategories() {
        if let p = profile {
            p.accountabilityCategories = selectedCategories.map { $0.rawValue }
        } else {
            let newProfile = UserProfile()
            newProfile.accountabilityCategories = selectedCategories.map { $0.rawValue }
            modelContext.insert(newProfile)
        }

        // Schedule category-specific notifications
        CheckInService.shared.scheduleAccountabilityCheckIns(for: selectedCategories)

        withAnimation(.spring(response: 0.4)) { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showSaved = false }
            dismiss()
        }
    }
}
