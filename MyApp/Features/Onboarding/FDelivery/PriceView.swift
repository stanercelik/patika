import RevenueCat
import RevenueCatUI
import SwiftUI

/// G2 sonrası tek patika teklifi. Ücret ve satın alma eylemi RevenueCat
/// editöründeki offering/paywall'dan gelir; bu kabuk yalnızca doğrular.
struct PriceView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        if let path = flow.generatedPath {
            PathPurchaseOfferView(pathID: path.id, days: path.steps.count) {
                flow.finishPrice()
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                Text(.paywallUnavailable)
                    .font(.body.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textPrimary.color)
                SecondaryTextButton(title: .paywallNotNow) { flow.finishPrice() }
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }
}

/// Reused from Yolum when the user comes back to buy the same path later.
struct PathPurchaseOfferView: View {
    let pathID: UUID
    let days: Int
    let onDone: () -> Void
    @Environment(AppServices.self) private var services
    @State private var viewModel: PathPaywallViewModel?
    @State private var showsPaywall = false
    @State private var purchaseReported = false

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView().tint(Theme.textPrimary.color)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onDone) {
                Image(systemName: "xmark")
                    .font(.body.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textPrimary.color)
                    .frame(width: 44, height: 44)
                    .background(WoodlandStyle.background, in: Circle())
            }
            .accessibilityLabel(Text(.paywallNotNow))
            .padding(.top, 8)
            .padding(.trailing, Theme.Spacing.screenMargin)
        }
        .task {
            if viewModel == nil {
                viewModel = PathPaywallViewModel(
                    services: services,
                    pathID: pathID,
                    days: days
                )
            }
            await viewModel?.load()
            if let viewModel, case .ready = viewModel.state {
                showsPaywall = true
            }
        }
        .sheet(isPresented: $showsPaywall, onDismiss: {
            if !purchaseReported { onDone() }
        }) {
            if let viewModel, case .ready(let offering) = viewModel.state {
                PaywallView(offering: offering)
                    .customPaywallVariables([
                        "path_days": .number(Double(viewModel.days)),
                        "remaining_sessions": .number(Double(viewModel.remainingSessions)),
                    ])
                    .onPurchaseInitiated { package, resume in
                        Task { @MainActor in
                            let shouldProceed = await viewModel.preparePurchase(
                                productID: package.storeProduct.productIdentifier
                            )
                            resume(shouldProceed: shouldProceed)
                        }
                    }
                    .onPurchaseCompleted { _, _ in
                        Task { @MainActor in
                            purchaseReported = true
                            showsPaywall = false
                            await viewModel.checkPurchase()
                        }
                    }
                    .onRestoreCompleted { _ in
                        Task { @MainActor in
                            purchaseReported = true
                            showsPaywall = false
                            await viewModel.checkPurchase()
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        HStack {
                            Spacer()
                            Button(.paywallNotNow) { showsPaywall = false }
                                .font(.body.weight(Theme.Weight.action))
                                .foregroundStyle(Theme.textPrimary.color)
                                .frame(minWidth: 80, minHeight: 44)
                                .background(WoodlandStyle.background, in: Capsule())
                                .padding(.trailing, Theme.Spacing.screenMargin)
                        }
                    }
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: PathPaywallViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("PaywallForestPath")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()
                    .accessibilityHidden(true)

                Text(.paywallHeadline)
                    .font(.largeTitle.weight(Theme.Weight.display))
                    .foregroundStyle(Theme.textPrimary.color)
                    .accessibilityAddTraits(.isHeader)
                Text(.paywallBody(viewModel.remainingSessions))
                    .font(.body.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)
                switch viewModel.state {
                case .loading:
                    ProgressView().tint(Theme.textPrimary.color)
                case .ready:
                    PrimaryButton(title: .paywallViewOffer) { showsPaywall = true }
                case .checking:
                    ProgressView().tint(Theme.textPrimary.color)
                    Text(.paywallChecking)
                        .font(.body.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textPrimary.color)
                    if viewModel.hasError {
                        Button(.paywallCheckAgain) { Task { await viewModel.checkPurchase() } }
                            .font(.body.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textPrimary.color)
                            .frame(minHeight: 44)
                    }
                case .unlocked:
                    PrimaryButton(title: .paywallContinue) { onDone() }
                case .unavailable:
                    Text(.paywallUnavailable)
                        .font(.body.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textPrimary.color)
                    Button(.paywallCheckAgain) { Task { await viewModel.load() } }
                        .font(.body.weight(Theme.Weight.action))
                        .foregroundStyle(Theme.textPrimary.color)
                        .frame(minHeight: 44)
                }
                Text(.paywallOnePayment)
                    .font(.subheadline.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                if viewModel.hasError, case .ready = viewModel.state {
                    Text(.paywallPurchaseError)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textPrimary.color)
                }
                Button(.paywallNotNow) { onDone() }
                    .font(.body.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textPrimary.color)
                    .frame(maxWidth: .infinity, minHeight: 44)
                Button(.paywallRestore) { Task { await viewModel.restore() } }
                    .font(.subheadline.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(maxWidth: .infinity, minHeight: 44)
                if viewModel.restoreUnavailable {
                    Text(.paywallRestoreUnavailable)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                }
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
