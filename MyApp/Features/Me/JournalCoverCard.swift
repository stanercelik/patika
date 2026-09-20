import SwiftUI

/// Defter kartı: kapalı guaj defter, üstünde son notun **bulanık** önizlemesi
/// (`docs/profile-design.md` §21.3).
///
/// Dokununca defter sayfasına yakınlaşma geçişi başlar; **kapak o sırada, hedef
/// sayfada açılır** (`JournalCoverOverlay`): zoom, kaynak kartın anlık görüntüsüyle
/// çalışıyor ve kartın kendi içindeki bir dönüş hiç görünmüyordu. Kapak kâğıdın
/// üstünde durunca kâğıt büyürken açılıyor ve ikisi aynı anda oynuyor.
///
/// - Önizleme yalnızca `preview` doluysa çizilir. Boşsa (kayıt yok ya da
///   `hidesJournal` açık) davet cümlesi ve "İlk notunu yaz" durur: gizlilik
///   ayarı açıkken bulanık hâli bile göstermek, gizli tutulan cümlenin şeklini
///   sızdırırdı.
/// - Önizleme VoiceOver'a **okunmaz**; kart tek düğmedir ve yalnızca "Defter"
///   der.
struct JournalCoverCard: View {
    let preview: String?
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let cornerRadius: CGFloat = 28

    var body: some View {
        Button(action: onOpen) {
            // Boyutu yalnızca kapaktaki metin belirler; görseller `.background`
            // içinde ve kırpılı. `scaledToFill` bir görsel yerleşimin içinde
            // durursa kartı (ve bütün sütunu) kendi boyutuna genişletir.
            JournalCoverFace(preview: preview, minHeight: dynamicTypeSize.isAccessibilitySize ? 0 : 168)
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                .contentShape(.rect)
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Me.journalCardLabel))
        .accessibilityHint(Text(Copy.Me.journalCardOpenHint))
        .accessibilityAddTraits(.isButton)
    }
}

/// Kapağın yüzü: guaj defter görseli + metin. Kartta da, defter sayfasının üstünde
/// açılan kapakta da aynı.
struct JournalCoverFace: View {
    let preview: String?
    var minHeight: CGFloat = 0
    /// Verilirse yüz bu kutuyu doldurur (sayfanın üstündeki kapak); nil ise
    /// metnin ölçüsüne göre boyutlanır (kart).
    var fillsContainer = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
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
            maxHeight: fillsContainer ? .infinity : nil,
            alignment: .leading
        )
        .frame(minHeight: minHeight)
        // Sola hizalı: uzun kapakta (sayfanın üstünde) sırt ve yaprak çizimi
        // ortadan kırpılmasın.
        .background(alignment: .leading) {
            // AX'te de düz yüzey: metin büyüyünce krem sırt çiziminin üstüne biniyor
            // ve okunmuyordu; erişilebilir boyutlarda dekoratif görsel saklanır.
            if PatikaArt.exists("me-journal-cover"), !dynamicTypeSize.isAccessibilitySize {
                Image(decorative: "me-journal-cover")
                    .resizable()
                    .scaledToFill()
            } else {
                // Görsel yoksa adaçayı düz kart.
                WoodlandStyle.surface
            }
        }
        .clipped()
    }
}

/// Defter sayfasının kâğıdının üstünde duran kapak: sayfa açıldığı anda sol
/// kenarından `rotation3DEffect` ile açılır (~420 ms) ve altındaki kâğıdı gösterir.
/// Yakınlaşma geçişiyle **aynı anda** oynar. Reduce Motion'da hiç çizilmez.
struct JournalCoverOverlay: View {
    let preview: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen = false

    var body: some View {
        if !reduceMotion {
            JournalCoverFace(preview: preview, fillsContainer: true)
                .rotation3DEffect(
                    .degrees(isOpen ? -100 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.6
                )
                .animation(.easeInOut(duration: 0.42), value: isOpen)
                // Kapak yarıyı geçince arka yüzü görünmesin. Her animasyon kendi
                // etkisinin hemen ardından: art arda iki `.animation` ikisi de
                // üstündeki her şeye uygulanırdı.
                .opacity(isOpen ? 0 : 1)
                .animation(.easeIn(duration: 0.14).delay(0.28), value: isOpen)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .task {
                    // Geçişin ilk karesinde kapalı görünsün, hemen ardından açılsın.
                    try? await Task.sleep(for: .milliseconds(40))
                    isOpen = true
                }
        }
    }
}
