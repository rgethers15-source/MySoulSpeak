import Foundation
import StoreKit

/// StoreKit 2 service for managing premium subscriptions and purchases.
/// Premium features: AI Conversation with Dr. Hope/Mr. Hope, Vent Room.
@MainActor
class StoreKitService: ObservableObject {
    #if DEBUG
    @Published var isPremium: Bool = true  // Always unlocked for testing
    #else
    @Published var isPremium: Bool = false
    #endif
    @Published var products: [Product] = []
    @Published var purchaseError: String?
    @Published var isLoading: Bool = false

    // Product identifiers — configure these in App Store Connect
    static let monthlyProductID = "com.mysoulspeak.premium.monthly"
    static let yearlyProductID = "com.mysoulspeak.premium.yearly"
    static let lifetimeProductID = "com.mysoulspeak.premium.lifetime"

    static let allProductIDs: Set<String> = [
        monthlyProductID,
        yearlyProductID,
        lifetimeProductID
    ]

    private var updateListenerTask: Task<Void, Error>?

    static let shared = StoreKitService()

    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Check existing entitlements
        Task {
            await checkPremiumStatus()
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Load available products from App Store.
    func loadProducts() async {
        isLoading = true
        do {
            let storeProducts = try await Product.products(for: StoreKitService.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("[SoulSpeak] Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    /// Purchase a product.
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkPremiumStatus()
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                purchaseError = "Purchase is pending approval."
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
            print("[SoulSpeak] Purchase error: \(error)")
            isLoading = false
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases.
    func restorePurchases() async {
        isLoading = true
        try? await AppStore.sync()
        await checkPremiumStatus()
        isLoading = false
    }

    // MARK: - Check Premium Status

    /// Check if user has active premium entitlement.
    func checkPremiumStatus() async {
        #if DEBUG
        // In debug/testing mode, always keep premium unlocked
        isPremium = true
        return
        #else
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if StoreKitService.allProductIDs.contains(transaction.productID) {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = false
        #endif
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (renewals, revocations, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.checkPremiumStatus()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case unverified
    }

    // MARK: - Helpers

    /// Get formatted price for a product.
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    /// Get subscription period description.
    func periodDescription(for product: Product) -> String {
        guard let subscription = product.subscription else {
            return "Lifetime"
        }
        switch subscription.subscriptionPeriod.unit {
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "Monthly" : "\(subscription.subscriptionPeriod.value) Months"
        case .year:
            return "Yearly"
        case .week:
            return "Weekly"
        case .day:
            return "Daily"
        @unknown default:
            return ""
        }
    }
}
