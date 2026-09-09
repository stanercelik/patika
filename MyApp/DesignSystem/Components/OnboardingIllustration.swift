import SwiftUI

/// C bölümü ekranlarının tek görseli.
///
/// Görsel, metnin anlattığı fikrin hemen ardından gelir. Böylece bağımsız bir
/// dekor değil, okunan cümlenin görsel karşılığı olur.
///
/// Varlık henüz eklenmemişse bileşen **hiçbir yer kaplamaz**. Görseller ürün
/// sahibi tarafından üretilip `Assets.xcassets/Onboarding` altına atılacak
/// (prompt'lar: PRD-Ek Görsel Sistem §11); o güne kadar ekranlar eksiksiz
/// çalışır ve yerinde boşluk ya da kırık ikon durmaz.
struct OnboardingIllustration: View {
    let name: String
    var height: CGFloat = 268
    var accessibilityHeight: CGFloat = 194

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if UIImage(named: name) != nil {
            Image(decorative: name)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: resolvedHeight)
                .padding(.vertical, 4)
                // Görsel dekoratif: anlamı hep yanındaki metin taşıyor.
                .accessibilityHidden(true)
        }
    }

    /// Büyük erişilebilirlik boyutlarında metin ekranın asıl içeriği olarak
    /// kalır. Normal boyutlarda ise illüstrasyon önceki 176 pt yuvadan belirgin
    /// biçimde daha büyük görünür.
    private var resolvedHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? accessibilityHeight : height
    }
}
