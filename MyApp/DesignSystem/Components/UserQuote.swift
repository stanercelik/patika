import SwiftUI

/// Kullanıcının kendi cümlesi.
///
/// ## İki ses
///
/// Kullanıcının cümlesi **serif** (New York), ürünün sesi SF Pro
/// (`Theme.Voice`). Göz kimin konuştuğunu fontan anlar; kullanıcı kendi
/// cümlesini hangi ekranda görürse görsün aynı yüzü tanır.
///
/// ## Cümle kutsaldır
///
/// Düzeltilmez, özetlenmez, yorumlanmaz. Soldaki çizgi tırnak işaretinin yerine:
/// tırnak metne bir "söz" ağırlığı yükler. Kısaltma gerekiyorsa çağıran taraf
/// cümle sınırında keser (`MeViewModel.excerpt`), kelime ortasından değil.
struct UserQuote: View {
    let text: String
    let caption: String
    var detail: String?
    /// Yüzeyin mürekkebi. Kâğıtta `.ink`; koyu zeminde varsayılan `.light`.
    var ink: PatikaInk = .light

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: text)
                .font(Theme.Voice.user())
                .fontDesign(.serif)
                .foregroundStyle(ink.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(verbatim: caption)
                .font(.footnote.weight(Theme.Weight.body))
                .foregroundStyle(ink.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let detail {
                Text(verbatim: detail)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(ink.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            Capsule()
                .fill(ink.primary.opacity(0.35))
                .frame(width: Theme.Line.border)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}
