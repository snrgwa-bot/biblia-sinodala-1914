import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var selectedPlan: String = "yearly"
    @State private var isPurchasing = false

    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)

    private var hasProducts: Bool {
        !subscriptionService.availableProducts.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, accentBrown],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Asistent AI Biblic")
                            .font(.title.bold())

                        Text("Deblocheaz\u{0103} puterea inteligen\u{021B}ei artificiale pentru studiul Bibliei")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)

                    // MARK: - Feature list
                    VStack(alignment: .leading, spacing: 14) {
                        featureRow(icon: "text.magnifyingglass",
                                   title: "Explica\u{021B}ii versete",
                                   subtitle: "\u{00CE}n\u{021B}elege sensul profund al fiec\u{0103}rui verset")

                        featureRow(icon: "character.book.closed",
                                   title: "Dic\u{021B}ionar biblic",
                                   subtitle: "Defini\u{021B}ii ale cuvintelor biblice \u{00EE}n context")

                        featureRow(icon: "text.justify.left",
                                   title: "Rezumate capitole",
                                   subtitle: "Ob\u{021B}ine rezumatul rapid al oric\u{0103}rui capitol")

                        featureRow(icon: "person.3.fill",
                                   title: "Perspective personaje",
                                   subtitle: "Vezi evenimentele prin ochii personajelor biblice")

                        featureRow(icon: "chart.bar.xaxis",
                                   title: "Vizualizare avansat\u{0103}",
                                   subtitle: "Progres, adnot\u{0103}ri, hart\u{0103} \u{0219}i cronologie biblic\u{0103}")

                        featureRow(icon: "sparkles",
                                   title: "Aprofundare enciclopedie",
                                   subtitle: "Detalii AI pentru persoane, locuri \u{0219}i evenimente")
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Subscription options
                    VStack(spacing: 12) {
                        if let yearly = subscriptionService.yearlyProduct {
                            subscriptionCard(
                                product: yearly,
                                label: "Anual",
                                priceDetail: yearlyPricePerMonth(yearly),
                                badge: subscriptionService.yearlySavingsText,
                                isSelected: selectedProduct?.id == yearly.id
                            )
                        } else {
                            // Fallback card when products not loaded
                            fallbackCard(
                                label: "Anual",
                                price: "$39.99/an",
                                detail: "$3.33/lun\u{0103}",
                                badge: "Economise\u{0219}ti 33%",
                                isSelected: selectedPlan == "yearly",
                                onTap: { selectedPlan = "yearly" }
                            )
                        }

                        if let monthly = subscriptionService.monthlyProduct {
                            subscriptionCard(
                                product: monthly,
                                label: "Lunar",
                                priceDetail: monthly.displayPrice + "/lun\u{0103}",
                                badge: nil,
                                isSelected: selectedProduct?.id == monthly.id
                            )
                        } else {
                            fallbackCard(
                                label: "Lunar",
                                price: "$4.99/lun\u{0103}",
                                detail: "",
                                badge: nil,
                                isSelected: selectedPlan == "monthly",
                                onTap: { selectedPlan = "monthly" }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Subscribe button
                    if hasProducts {
                        Button {
                            guard let product = selectedProduct else { return }
                            isPurchasing = true
                            Task {
                                let success = await subscriptionService.purchase(product)
                                isPurchasing = false
                                if success { dismiss() }
                            }
                        } label: {
                            Group {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("\u{00CE}ncepe perioada gratuit\u{0103} de 3 zile")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentBrown)
                        .disabled(selectedProduct == nil || isPurchasing)
                        .padding(.horizontal, 24)
                    } else {
                        // Fallback: show button that explains products not yet available
                        Text("\u{00CE}ncepe perioada gratuit\u{0103} de 3 zile")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(accentBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                            .onTapGesture {
                                subscriptionService.purchaseError = "Abonamentele vor fi disponibile dup\u{0103} publicarea pe App Store."
                            }
                    }

                    // MARK: - Restore + Terms
                    VStack(spacing: 8) {
                        Button("Restaureaz\u{0103} achizi\u{021B}iile") {
                            Task { await subscriptionService.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text("Abonamentul se re\u{00EE}nnoie\u{0219}te automat. Po\u{021B}i anula oric\u{00E2}nd din Set\u{0103}ri.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    if let error = subscriptionService.purchaseError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("\u{00CE}nchide") { dismiss() }
                }
            }
        }
        .onAppear {
            if subscriptionService.availableProducts.isEmpty {
                Task { await subscriptionService.loadProducts() }
            }
            selectedProduct = subscriptionService.yearlyProduct
                              ?? subscriptionService.monthlyProduct
        }
        .onChange(of: subscriptionService.availableProducts) { _, _ in
            if selectedProduct == nil {
                selectedProduct = subscriptionService.yearlyProduct
                                  ?? subscriptionService.monthlyProduct
            }
        }
        .interactiveDismissDisabled(isPurchasing)
    }

    // MARK: - Feature Row

    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentBrown)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Subscription Card (real product)

    @ViewBuilder
    private func subscriptionCard(
        product: Product,
        label: String,
        priceDetail: String,
        badge: String?,
        isSelected: Bool
    ) -> some View {
        Button {
            selectedProduct = product
        } label: {
            cardContent(label: label, priceDetail: priceDetail, subDetail: "3 zile gratuit, apoi \(product.displayPrice)", badge: badge, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fallback Card (no products loaded)

    @ViewBuilder
    private func fallbackCard(
        label: String,
        price: String,
        detail: String,
        badge: String?,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            onTap()
        } label: {
            cardContent(label: label, priceDetail: detail.isEmpty ? price : detail, subDetail: "3 zile gratuit, apoi \(price)", badge: badge, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Content

    @ViewBuilder
    private func cardContent(label: String, priceDetail: String, subDetail: String, badge: String?, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                Text(priceDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subDetail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? accentBrown : .secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? accentBrown.opacity(0.08) : Color(UIColor.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isSelected ? accentBrown : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Helpers

    private func yearlyPricePerMonth(_ product: Product) -> String {
        let perMonth = product.price / Decimal(12)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        let formatted = formatter.string(from: perMonth as NSDecimalNumber) ?? "\(perMonth)"
        return "\(formatted)/lun\u{0103}"
    }
}
