import SwiftUI

/// Defter kartı: kapalı guaj defter, üstünde son notun **bulanık** önizlemesi
/// (`docs/profile-design.md` §21.3).
///
/// Dokununca kapak sol kenarından `rotation3DEffect` ile açılır, altında krem
/// sayfa görünür; ardından çağıran defter sayfasına yakınlaşma geçişiyle gider.
/// Reduce Motion'da kapak dönmez, yalnızca geçiş olur.
///
/// - Önizleme yalnızca `preview` doluysa çizilir. Boşsa (kayıt yok ya da
///   `hidesJournal` açık) davet cümlesi ve "İlk notunu yaz" durur: gizlilik
///   ayarı açıkken bulanık hâli bile göstermek, gizli tutulan cümlenin şeklini
///   sızdırırdı.
/// - Önizleme VoiceOver'a **okunmaz**; kart tek düğmedir ve yalnızca "Defter"
///   der.
struct JournalCoverCard: View {
    let preview: String?
    /// Kapak açılıyor mu. Sahibi çağıran: geçiş bitince kapatır.
    let isOpening: Bool
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let cornerRadius: CGFloat = 28

    var body: some View {
        Button(action: onOpen) {
            // Boyutu yalnızca kapaktaki metin belirler; görseller `.background`
            // içinde ve kırpılı. `scaledToFill` bir görsel yerleşimin içinde
            // durursa kartı (ve bütün sütunu) kendi boyutuna genişletir.
            cover
                .background { page }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                .contentShape(.rect)
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Me.journalCardLabel))
        .accessibilityHint(Text(Copy.Me.journalCardOpenHint))
        .accessibilityAddTraits(.isButton)
    }

    /// Kapağın altında kalan krem sayfa. Metin taşımaz: açılan kapağın arkasında
    /// yalnızca kâğıt görünür.
    private var page: some View {
        Image(decorative: "me-journal-paper")
            .resizable()
            .scaledToFill()
            .overlay(WoodlandStyle.paper.opacity(0.35))
            .clipped()
    }

    private var cover: some View {
        // Metin sırt ve yaprak çiziminin sağında durur.
        VStack(alignment: .leading, spacing: 10) {
            if let preview {
                Text(verbatim: preview)
                    .font(Theme.Voice.user(.callout))
                    .foregroundStyle(WoodlandStyle.paper.opacity(0.9))
                    .lineLimit(3)
                    .blur(radius: 6)
                    .privacySensitive()
                    .accessibilityHidden(true)
            }
            Text(Copy.Me.journalCardInvite)
                .font(Theme.TypeFace.rowTitle)
                .foregroundStyle(WoodlandStyle.paper)
                .fixedSize(horizontal: false, vertical: true)
            if preview == nil {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .accessibilityHidden(true)
                    Text(Copy.Me.journalCardWrite)
                }
                .font(Theme.TypeFace.rowAction)
                .foregroundStyle(WoodlandStyle.apricot)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 24 : 96)
        .padding(.trailing, 22)
        .padding(.vertical, 22)
        .frame(
            maxWidth: .infinity,
            minHeight: dynamicTypeSize.isAccessibilitySize ? 0 : 168,
            alignment: .leading
        )
        .background {
            Image(decorative: "me-journal-cover")
                .resizable()
                .scaledToFill()
        }
        .clipped()
        // Dönme sol kenardan: sırt sabit, kapak kitabın ortasına doğru açılır.
        .rotation3DEffect(
            .degrees(isOpening && !reduceMotion ? -100 : 0),
            axis: (x: 0, y: 1, z: 0),
            anchor: .leading,
            perspective: 0.6
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.42), value: isOpening)
        // Kapak yarıyı geçince arka yüzü görünmesin. Her animasyon kendi
        // etkisinin hemen ardından: art arda iki `.animation` ikisi de üstündeki
        // her şeye uygulanırdı.
        .opacity(isOpening && !reduceMotion ? 0 : 1)
        .animation(reduceMotion ? nil : .easeIn(duration: 0.14).delay(0.28), value: isOpening)
    }
}
