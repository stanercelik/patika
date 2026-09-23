import SwiftUI

enum OnboardingHeightClass: Sendable {
    case comfortable
    case compact
    case scrollRequired

    static func resolve(availableHeight: CGFloat, accessibility: Bool) -> Self {
        if accessibility || availableHeight < Theme.OnboardingLayout.compactMinimumHeight {
            return .scrollRequired
        }
        if availableHeight < Theme.OnboardingLayout.comfortableMinimumHeight {
            return .compact
        }
        return .comfortable
    }
}

extension EnvironmentValues {
    @Entry var onboardingHeightClass: OnboardingHeightClass = .comfortable
}

/// Onboarding soru ekranlarının ortak iskeleti (B, D, E bölümleri).
///
/// Üst çubuk burada **yok** — o kabuğa ait ve adım değişirken yerinde kalıyor.
/// Bu iskelet yalnızca solup beliren kısmı çizer: soru, açıklama, cevap alanı ve
/// alt aksiyonlar.
///
/// Soru başlığı `DisplayText`ten bir punto küçük: soru ekranında en büyük nesne
/// cevap alanı olmalı, başlık değil.
struct OnboardingQuestionLayout<Content: View, Footer: View>: View {
    private let headline: LocalizedStringResource
    private let hint: LocalizedStringResource?
    private let usesScenePlate: Bool
    private let content: Content
    private let footer: Footer

    /// Adımın malzemesi kabuktan gelir; varsayılan `.ground` olduğu için bunu hiç
    /// kurmayan çağıranlar (`PathSessionView`) değişmez.
    @Environment(\.onboardingSurface) private var surface
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        headline: LocalizedStringResource,
        hint: LocalizedStringResource? = nil,
        usesScenePlate: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.headline = headline
        self.hint = hint
        self.usesScenePlate = usesScenePlate
        self.content = content()
        self.footer = footer()
    }

    /// Soru ile cevap arasındaki nefes payı.
    ///
    /// Bir ara bu boşluk esnek yapılıp cevap alanı ekranın altına itilmişti;
    /// geri alındı (ürün sahibi kararı, 2026-09-08): cevap alanı sorudan
    /// kopuyor, aralarındaki ilişkiyi kaybedip ekranda bağımsız iki blok gibi
    /// duruyordu. Sabit ama eskisinden geniş bir aralık, ikisini bir arada
    /// tutarken cevabı da birkaç punto aşağı indiriyor.
    private var questionToAnswerGap: CGFloat { 24 }

    var body: some View {
        // Varsayılan punto sığar; ScrollView yalnızca büyük Dynamic Type
        // boyutlarında devreye girer — AX5'te hiçbir ekran kırılmaz (Ton eki §7).
        //
        // Normal boyutlarda alt bölge `safeAreaInset` ile sabit kalır; klavye ve footer
        // aynı güvenli bölge mekanizmasıyla toplanır. AX boyutlarında dev bir sabit
        // buton içeriği örtmesin diye footer belgenin sonuna akar ve kullanıcı ona kaydırır.
        GeometryReader { proxy in
            let heightClass = OnboardingHeightClass.resolve(
                availableHeight: proxy.size.height,
                accessibility: dynamicTypeSize.isAccessibilitySize
            )
            // Keyboard height must not change the identity of the focused input.
            let usesFlowingFooter = dynamicTypeSize.isAccessibilitySize

            Group {
                if usesFlowingFooter {
                    ScrollView {
                        VStack(spacing: 0) {
                            questionBlock(heightClass: heightClass)
                            footer
                                .padding(.top, 12)
                                .padding(.horizontal, Theme.Spacing.screenMargin)
                                .padding(.bottom, 12)
                        }
                    }
                } else {
                    ScrollView {
                        questionBlock(heightClass: heightClass)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        footer
                            .padding(.top, 12)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                            .padding(.bottom, 12)
                            .background(Color.clear)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .environment(\.onboardingHeightClass, heightClass)
        }
    }

    private func questionBlock(heightClass: OnboardingHeightClass) -> some View {
        Group {
            if usesScenePlate {
                SceneContentPlate { questionContent(heightClass: heightClass) }
            } else {
                questionContent(heightClass: heightClass)
                    .onboardingSurfaceCard(surface)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, heightClass == .comfortable ? 14 : 8)
        .padding(.bottom, 16)
    }

    private func questionContent(heightClass: OnboardingHeightClass) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DisplayText(headline, size: 30)

            if let hint {
                BodyText(hint)
            }

            content
                .padding(.top, heightClass == .compact ? 14 : questionToAnswerGap)
        }
    }
}

/// Soru ekranı altı: birincil CTA + altında suçsuzlaştırıcı bir çıkış.
///
/// Çıkışın görünür ama ikincil olması "No Escape Room" kuralının uygulaması
/// (PRD-Ek Onboarding §10): kullanıcı kapana kısılmış hissetmez, ama kolay yol
/// da atlamak değildir.
struct OnboardingQuestionFooter: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var primaryTitle: LocalizedStringResource
    var primaryDisabledTitle: LocalizedStringResource?
    var isPrimaryEnabled: Bool = true
    var primaryAction: () -> Void
    var skipTitle: LocalizedStringResource?
    var skipAction: (() -> Void)?

    /// İkincil satırın yeri **her ekranda** ayrılır, o ekranda çıkış olmasa bile.
    /// Ayrılmazsa birincil buton B2'den B4'e geçerken bir satır boyu yukarı
    /// kayıyor; kalıcı kabuğun altını oyan tam olarak bu tür küçük zıplamalar.
    @ScaledMetric(relativeTo: .subheadline) private var escapeRowHeight: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            PrimaryButton(
                title: primaryTitle,
                disabledTitle: primaryDisabledTitle,
                isEnabled: isPrimaryEnabled,
                action: primaryAction
            )

            Group {
                if let skipTitle, let skipAction {
                    SecondaryTextButton(title: skipTitle, action: skipAction)
                } else {
                    // Boş `if` dalı `EmptyView` üretiyor ve `EmptyView` kendisine
                    // verilen yüksekliği yok sayıyor — satır çöküyordu. `Color.clear`
                    // esnek olduğu için çerçeveyi kabul ediyor.
                    Color.clear
                }
            }
            .frame(height: dynamicTypeSize.isAccessibilitySize && skipTitle == nil ? 0 : escapeRowHeight)
        }
    }
}
