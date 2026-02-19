import Foundation
import StoreKit
import UIKit

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    // MARK: - Published State

    @Published var isSubscribed: Bool = false
    @Published var availableProducts: [Product] = []
    @Published var purchaseError: String?
    @Published var isLoading: Bool = false

    // MARK: - Product IDs

    static let monthlyProductID = "com.nexubible.BibliaRomana.ai.monthly"
    static let yearlyProductID = "com.nexubible.BibliaRomana.ai.yearly"
    static let allProductIDs: Set<String> = [monthlyProductID, yearlyProductID]

    // MARK: - Persistence

    private let subscriptionStatusKey = "ai_subscription_active"

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init() {
        isSubscribed = UserDefaults.standard.bool(forKey: subscriptionStatusKey)

        #if DEBUG
        if UserDefaults.standard.bool(forKey: devOverrideKey) {
            isSubscribed = true
        }
        #endif

        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            #if DEBUG
            if !UserDefaults.standard.bool(forKey: devOverrideKey) {
                await checkCurrentEntitlements()
            }
            #else
            await checkCurrentEntitlements()
            #endif
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Listen for Transactions

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.checkCurrentEntitlements()
                }
            }
        }
    }

    // MARK: - Load Products

    @Published var productsLoaded: Bool = false

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Self.allProductIDs)
            availableProducts = products.sorted { $0.price < $1.price }
            productsLoaded = true
            if products.isEmpty {
                purchaseError = "Nu s-au g\u{0103}sit produse. Rula\u{021B}i din Xcode (Cmd+R) pentru testare StoreKit."
            }
        } catch {
            productsLoaded = true
            purchaseError = "Eroare la \u{00EE}nc\u{0103}rcarea produselor: \(error.localizedDescription)"
        }
    }

    // MARK: - Check Entitlements

    func checkCurrentEntitlements() async {
        var hasActive = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if Self.allProductIDs.contains(transaction.productID),
                   transaction.revocationDate == nil {
                    hasActive = true
                }
            }
        }

        isSubscribed = hasActive
        UserDefaults.standard.set(hasActive, forKey: subscriptionStatusKey)
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkCurrentEntitlements()
                    return true
                } else {
                    purchaseError = "Tranzac\u{021B}ia nu a putut fi verificat\u{0103}."
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Achizi\u{021B}ia este \u{00EE}n a\u{0219}teptare."
                return false
            @unknown default:
                purchaseError = "Eroare necunoscut\u{0103}."
                return false
            }
        } catch {
            purchaseError = "Eroare la achizi\u{021B}ie: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        try? await AppStore.sync()
        await checkCurrentEntitlements()

        if !isSubscribed {
            purchaseError = "Nu s-a g\u{0103}sit niciun abonament activ."
        }
    }

    // MARK: - Manage Subscription

    func manageSubscription() async {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        try? await AppStore.showManageSubscriptions(in: windowScene)
    }

    // MARK: - Helpers

    var monthlyProduct: Product? {
        availableProducts.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        availableProducts.first { $0.id == Self.yearlyProductID }
    }

    var yearlySavingsText: String? {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return nil }
        let yearlyEquivalent = monthly.price * Decimal(12)
        let savings = yearlyEquivalent - yearly.price
        let percentage = NSDecimalNumber(decimal: savings / yearlyEquivalent * Decimal(100)).intValue
        return "Economise\u{0219}ti \(percentage)%"
    }

    // MARK: - Dev Override (remove before App Store submission)

    #if DEBUG
    private let devOverrideKey = "dev_subscription_override"

    var isDevOverrideEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: devOverrideKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: devOverrideKey)
            isSubscribed = newValue
            UserDefaults.standard.set(newValue, forKey: subscriptionStatusKey)
            objectWillChange.send()
        }
    }
    #endif
}
