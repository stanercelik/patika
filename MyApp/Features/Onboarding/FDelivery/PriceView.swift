import RevenueCat
import RevenueCatUI
import SwiftUI

/// Taahhüt sonrası tek patika teklifi (G2 → taahhüt → burası). Tasarım ve metinler:
/// docs/paywall-stratejisi.md.
///
/// Teklif taahhüt basılı tutulduğu anda yüklenmeye başlar
/// (`OnboardingFlowViewModel.prepareOffer`) ve eşik cümlesi ekrandayken biter. Bu
/// adıma gelindiğinde kaplama animasyonsuz açılır ve içeriği doğrudan RevenueCat
/// paywall'ıdır; arada uygulamanın kendi yükleniyor ekranı yok.
struct PriceView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        Group {
            if flow.generatedPath == nil {
                // Patika yoksa teklif de yok: kullanıcı boş ekranda kalmasın.
                VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                    BodyText(.paywallUnavailable)
                    SecondaryTextButton(title: .paywallNotNow) { flow.finishPrice() }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
            } else {
                Color.clear
            }
        }
            .onAppear { flow.prepareOffer() }
            .fullScreenCover(item: presentedOffer) { offer in
                PathPurchaseOfferView(viewModel: offer) { flow.finishPrice() }
            }
            .transaction { $0.disablesAnimations = true }
    }

    /// Yükleme bitince (hazır ya da hatalı) kaplama açılır.
    private var presentedOffer: Binding<PathPaywallViewModel?> {
        Binding(
            get: { flow.purchaseOffer.flatMap { $0.isLoading ? nil : $0 } },
            set: { if $0 == nil { flow.finishPrice() } }
        )
    }
}

/// Tam ekran kaplamanın içeriği. Teklif hazırsa **doğrudan RevenueCat paywall'ı**.
/// Uygulamanın kendi yüzeyi (sahne + plaka) yalnız ödeme doğrulanırken, patika
/// açıldığında ya da teklif yüklenemediğinde görünür.
///
/// Çağıranlar (`PriceView`, Yolum, Ben) ViewModel'i kurup `load()` eder ve kaplamayı
/// ancak yükleme bitince açar; bu görünüm teklifi kendisi beklemez.
struct PathPurchaseOfferView: View {
    let viewModel: PathPaywallViewModel
    let onDone: () -> Void
    @State private var purchaseReported = false
    @State private var showsSupport = false

    /// Paywall'daki destek düğmesinin deep link'i. RevenueCat bağlantıyı SwiftUI
    /// `openURL` ortamıyla açıyor; burada yakalanır, sisteme URL şeması gerekmez.
    private static let supportURL = URL(string: "patika://support")!

    var body: some View {
        Group {
            switch viewModel.state {
            case .ready(let offering):
                paywall(offering: offering)
            case .loading, .checking, .unlocked, .unavailable:
                shell
            }
        }
        .sheet(isPresented: $showsSupport) {
            CrisisView()
                .presentationBackground(WoodlandStyle.background)
        }
    }

    private func paywall(offering: Offering) -> some View {
        PaywallView(offering: offering)
            .customPaywallVariables(
                viewModel.paywallVariables(for: offering).mapValues { value in
                    switch value {
                    case .number(let number): .number(number)
                    case .text(let text): .string(text)
                    }
                }
            )
            .onAppear { viewModel.paywallShown() }
            .onPurchaseInitiated { package, resume in
                Task { @MainActor in
                    let shouldProceed = await viewModel.preparePurchase(
                        productID: package.storeProduct.productIdentifier
                    )
                    resume(shouldProceed: shouldProceed)
                }
            }
            // Eşzamanlı: RevenueCat kapanma isteğini satın alma geri çağrılarından
            // sonra gönderiyor; bayrak ondan önce kurulmuş olmalı.
            .onPurchaseCompleted { _, _ in
                purchaseReported = true
                Task { @MainActor in await viewModel.checkPurchase() }
            }
            .onRestoreCompleted { _ in
                purchaseReported = true
                Task { @MainActor in await viewModel.checkPurchase() }
            }
            .onRequestedDismissal {
                // Satın almadan sonra da gelir; o zaman ekran doğrulamaya geçer.
                guard !purchaseReported else { return }
                viewModel.paywallClosed()
                onDone()
            }
            .environment(\.openURL, OpenURLAction { url in
                guard url == Self.supportURL else { return .systemAction }
                showsSupport = true
                return .handled
            })
            .alert(
                Text(.paywallPurchaseError),
                isPresented: Binding(
                    get: { viewModel.hasError },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button(.paywallCheckAgain, role: .cancel) { viewModel.clearError() }
            }
    }

    // MARK: - Uygulamanın kendi yüzeyi

    private var shell: some View {
        ZStack {
            OnboardingSceneLayer(artwork: .prepare)
            if viewModel.isLoading {
                ProgressView().tint(Theme.textPrimary.color)
            } else {
                plate
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onDone) {
                Image(systemName: "xmark")
                    .font(.body.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textPrimary.color)
                    .frame(width: 44, height: 44)
                    .background(WoodlandStyle.background.opacity(0.6), in: Circle())
            }
            .accessibilityLabel(Text(.paywallNotNow))
            .padding(.top, 8)
            .padding(.trailing, Theme.Spacing.screenMargin)
        }
    }

    private var plate: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 140)
                SceneContentPlate {
                    VStack(alignment: .leading, spacing: 14) {
                        DisplayText(.paywallHeadline, size: 30)
                            .accessibilityAddTraits(.isHeader)
                        BodyText(.paywallBody(viewModel.remainingSessions))
                        stateContent
                        Text(.paywallOnePayment)
                            .font(Theme.TypeFace.screenNote)
                            .foregroundStyle(Theme.textSecondary.color)
                            .fixedSize(horizontal: false, vertical: true)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 24) { secondaryActions }
                            VStack(spacing: 0) { secondaryActions }
                        }
                        .frame(maxWidth: .infinity)
                        if viewModel.restoreUnavailable {
                            Text(.paywallRestoreUnavailable)
                                .font(.footnote.weight(Theme.Weight.body))
                                .foregroundStyle(Theme.textSecondary.color)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.bottom)
    }

    @ViewBuilder
    private var secondaryActions: some View {
        SecondaryTextButton(title: .paywallNotNow) { onDone() }
            .fixedSize()
        SecondaryTextButton(title: .paywallRestore) {
            Task { await viewModel.restore() }
        }
        .fixedSize()
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .loading, .ready:
            EmptyView()
        case .checking:
            ProgressView().tint(Theme.textPrimary.color)
            BodyText(.paywallChecking)
            if viewModel.hasError {
                PrimaryButton(title: .paywallCheckAgain) {
                    Task { await viewModel.checkPurchase() }
                }
            }
        case .unlocked:
            PrimaryButton(title: .paywallContinue) { onDone() }
        case .unavailable:
            BodyText(.paywallUnavailable)
            PrimaryButton(title: .paywallCheckAgain) {
                Task { await viewModel.load() }
            }
        }
    }
}
