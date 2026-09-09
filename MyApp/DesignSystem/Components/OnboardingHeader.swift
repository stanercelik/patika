import SwiftUI

/// Onboarding üst çubuğu: geri butonu + ilerleme izi.
///
/// **Kabuğun kalıcı parçasıdır** (ürün sahibi kararı, 2026-09-08). Ekranlar bu
/// çubuğu kendi içinde çizmez; `OnboardingContainerView` bir kez kurar ve adım
/// değişirken yeniden oluşturmaz. Sebep: çubuk her adımda sökülüp takıldığında
/// geri butonu gidip geliyor ve iz sıfırdan çiziliyordu — akış 31 ayrı ekran gibi
/// görünüyordu. Kalıcı çubuk + solan içerik, aynı ekranda ilerleme hissi veriyor.
///
/// **SOS burada yok.** Ürün kararı: onboarding kısa bir akış ve kriz yakalaması
/// B1'deki serbest metin sınıflandırıcısıyla yapılıyor (PRD §11.1). SOS, onboarding
/// tamamlandıktan sonra her ekranda sabit (`RootView`).
struct OnboardingHeader: View {
    /// Geri butonu **her zaman yerini korur**; false ise yalnızca görünmez ve
    /// dokunulamaz olur. Yerinden kaldırmak izin yatay konumunu kaydırıyordu.
    var showsBack: Bool
    /// 0…1 ilerleme. Nil ise iz solar — ama son değeri korur, sıfıra dönmez.
    var progress: Double?
    var onBack: () -> Void

    /// İz kalıcı olduğu için en son bilinen ilerlemeyi hatırlar: bar gizli bir
    /// adımda (A1, kriz) sıfırlanıp geri döndüğünde baştan çizilmesin.
    @State private var lastKnownProgress: Double = 0

    var body: some View {
        HStack(spacing: 14) {
            OnboardingBackButton(action: onBack)
                .opacity(showsBack ? 1 : 0)
                .disabled(!showsBack)
                .accessibilityHidden(!showsBack)

            PathProgressBar(progress: lastKnownProgress)
                .opacity(progress == nil ? 0 : 1)
                .accessibilityHidden(progress == nil)
        }
        .frame(height: 44)
        .padding(.leading, Theme.Spacing.screenMargin - OnboardingBackButton.opticalInset)
        .padding(.trailing, Theme.Spacing.screenMargin)
        .onChange(of: progress, initial: true) { _, new in
            if let new { lastKnownProgress = new }
        }
    }
}

/// Geri butonu — çıplak chevron.
///
/// Yuvarlak arka plan **yok** (ürün sahibi kararı, 2026-09-08): daire, geri gitmeyi
/// ekranın en belirgin nesnesi yapıyordu. Kalın chevron aynı işi kendi başına
/// yapıyor ve dikkati içerikte bırakıyor. Dokunma alanı yine 44×44 — görsel küçüldü,
/// hedef küçülmedi.
struct OnboardingBackButton: View {
    let action: () -> Void

    /// Chevron glifinin kendi sol boşluğu var; daire kalkınca metin kenarından
    /// içeride duruyor gibi görünüyor. Bu kadar sola çekmek optik hizayı düzeltir.
    static let opticalInset: CGFloat = 4

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color)
                .frame(width: 44, height: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.calm)
        .accessibilityLabel("Geri")
    }
}
