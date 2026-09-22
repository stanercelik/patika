import SwiftUI

/// C bölümünün ortak iskeleti: soru sormayan, anlatan ekranlar.
///
/// Soru iskeletiyle (`OnboardingQuestionLayout`) aynı kaydırma + alt bölge yapısını
/// kullanır ki B6'dan C1'e geçerken CTA aynı yükseklikte kalsın. Fark yalnızca
/// içerikte: burada cevap alanı yok, paragraf var.
///
/// Alt bölgede tek bir CTA var ve ayrı bir "geç" bağlantısı yok — C ekranlarında
/// CTA zaten hızlı yol, ikinci bir çıkış eklemek "burada okunacak bir şey yok"
/// demek olurdu.
struct OnboardingStatementLayout<Content: View>: View {
    private let headline: LocalizedStringResource
    private let content: Content
    private let ctaTitle: LocalizedStringResource
    private let action: () -> Void

    @Environment(\.onboardingSurface) private var surface

    init(
        headline: LocalizedStringResource,
        ctaTitle: LocalizedStringResource = Copy.Button.next,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.headline = headline
        self.ctaTitle = ctaTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        // Footer `safeAreaInset` ile veriliyor — bkz. `OnboardingQuestionLayout` (2026-09-22
        // klavye/taşma düzeltmesi, docs/onboarding-redesign.md Faz 5). C ekranlarında metin
        // alanı yok ama aynı yapı korunuyor: B6'dan C1'e geçerken CTA aynı yükseklikte kalmalı.
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DisplayText(headline, size: 30)
                    .statementReveal(0)
                content
            }
            .onboardingSurfaceCard(surface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            OnboardingQuestionFooter(
                primaryTitle: ctaTitle,
                primaryAction: action
            )
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 12)
            .background {
                LinearGradient(
                    colors: [.clear, WoodlandStyle.background.opacity(0.85), WoodlandStyle.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .padding(.top, -24)
            }
        }
    }
}

/// C ekranlarının paragrafı. `BodyText`ten farkı: içine vurgu alabilmesi için
/// `AttributedString` kabul etmesi ve birincil mürekkeple yazılması — bu
/// ekranlarda paragraf ikincil bir açıklama değil, ekranın kendisi.
struct StatementParagraph: View {
    private let text: AttributedString
    @Environment(\.patikaInk) private var ink

    init(_ text: AttributedString) {
        self.text = text
    }

    init(_ text: LocalizedStringResource) {
        self.text = AttributedString(localized: text)
    }

    var body: some View {
        Text(text)
            .font(.body.weight(Theme.Weight.body))
            .foregroundStyle(ink.primary.opacity(0.92))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }
}
