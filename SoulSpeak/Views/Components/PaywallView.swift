import SwiftUI
import StoreKit

/// Premium upgrade paywall — shows when user tries to access paid features.
/// Premium features: AI Talk with Dr. Hope/Mr. Hope, Vent Room.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitService.shared

    @State private var selectedProduct: Product?
    @State private var showSuccess = false
    @State private var pulseGlow = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.06, blue: 0.2),
                    Color(red: 0.15, green: 0.08, blue: 0.25),
                    Color(red: 0.08, green: 0.05, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Hero section
                    heroSection

                    // Features list
                    featuresSection

                    // Pricing options
                    pricingSection

                    // Subscribe button
                    subscribeButton

                    // Restore
                    restoreButton

                    if let error = store.purchaseError {
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Legal
                    legalSection

                    Spacer(minLength: 30)
                }
            }

            // Success overlay
            if showSuccess {
                successOverlay
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Glowing crown icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.7, blue: 0.3).opacity(pulseGlow ? 0.3 : 0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseGlow ? 1.1 : 1.0)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.3))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }

            Text("SoulSpeak Premium")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.white)

            Text("Unlock the full healing experience")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Talk to Dr. Hope & Mr. Hope",
                subtitle: "AI-powered conversations — they listen and talk back",
                color: Color(red: 0.7, green: 0.4, blue: 0.8)
            )

            featureRow(
                icon: "flame.fill",
                title: "The Vent Room",
                subtitle: "Record, burn, and destroy — release your frustration",
                color: Color(red: 0.9, green: 0.4, blue: 0.2)
            )

            featureRow(
                icon: "waveform.and.mic",
                title: "Unlimited Voice Journals",
                subtitle: "No daily limits on recording sessions",
                color: SSColors.primary
            )

            featureRow(
                icon: "sparkles",
                title: "Priority AI Responses",
                subtitle: "Faster, deeper conversations with both characters",
                color: Color(red: 0.9, green: 0.7, blue: 0.3)
            )
        }
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Pricing
    private var pricingSection: some View {
        VStack(spacing: 12) {
            if store.products.isEmpty {
                if store.isLoading {
                    ProgressView("Loading prices…")
                        .tint(.white)
                        .foregroundColor(.white)
                } else {
                    Text("Prices are unavailable. Please try again.")
                        .foregroundColor(.white)
                    Button("Retry") {
                        Task { await store.loadProducts() }
                    }
                }
            } else {
                ForEach(store.products, id: \.id) { product in
                    let isSelected = selectedProduct?.id == product.id
                    Button(action: { selectedProduct = product }) {
                        pricingCard(
                            title: store.periodDescription(for: product),
                            price: product.displayPrice,
                            savings: product.id == StoreKitService.lifetimeProductID ? "Pay once" : nil,
                            isSelected: isSelected
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            selectedProduct = store.products.first
        }
    }

    private func pricingCard(title: String, price: String, savings: String?, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if let savings = savings {
                    Text(savings)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))
                }
            }

            Spacer()

            Text(price)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color(red: 0.7, green: 0.4, blue: 0.8) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
        )
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button(action: subscribe) {
            HStack(spacing: 10) {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 16))
                    Text("Unlock Premium")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.5, green: 0.25, blue: 0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.4), radius: 10, y: 4)
            )
        }
        .disabled(store.isLoading || store.products.isEmpty)
        .padding(.horizontal, 20)
    }

    // MARK: - Restore
    private var restoreButton: some View {
        Button(action: {
            Task { await store.restorePurchases() }
        }) {
            Text("Restore Purchases")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Legal
    private var legalSection: some View {
        VStack(spacing: 4) {
            Text("Subscriptions auto-renew unless cancelled 24 hours before the renewal date.")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Link("Terms", destination: URL(string: "https://soulspeak.app/terms")!)
                Link("Privacy", destination: URL(string: "https://soulspeak.app/privacy")!)
            }
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))

                Text("Welcome to Premium!")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                Text("Dr. Hope and Mr. Hope are ready\nfor deeper conversations.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button(action: { dismiss() }) {
                    Text("Let's Go")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(SSColors.gradientPrimary))
                }
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Actions
    private func subscribe() {
        guard let product = selectedProduct ?? store.products.first else { return }

        Task {
            let success = await store.purchase(product)
            if success {
                withAnimation { showSuccess = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    dismiss()
                }
            }
        }
    }
}
