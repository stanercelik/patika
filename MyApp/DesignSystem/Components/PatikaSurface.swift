import SwiftUI

/// Patika'nın ortak yüzey dili — "Yolum"un tabelasından türetildi.
///
/// ## Üç katman, karışmazlar
///
/// 1. **Zemin** — guaj manzara ("Yolum") ya da nefes alan mesh ("Ben").
///    Okunmaz, dokunulmaz; yalnızca yer duygusu taşır.
/// 2. **Kâğıt** — içeriğin üstünde durduğu yüzey. Koyu mürekkep yazı, yumuşak
///    gölge. Haritanın üstündeki tabela ile aynı malzeme.
/// 3. **Cam** — yalnızca gezinme: yüzen başlık, sekme çubuğu, sheet
///    (`WoodlandGlassSurface`).
///
/// ## Neden kâğıt
///
/// Ürün sahibi kararı (2026-09-17): "Ben" koyu kartlardan kâğıda geçti, çünkü
/// üç sekme üç ayrı malzemeden yapılmış gibi duruyordu.
///
/// > `docs/profile-design.md` §9.2 **bu kararla güncellenmelidir.** O bölüm
/// > içerik kartlarını koyu ve gölgesiz tarif ediyor; gerekçesi "cam gezinme
/// > katmanının dili" ve "koyu zeminde gölge görünmez, yalnızca kirletir"di.
/// > İlk gerekçe duruyor — kâğıt cam değil ve cam hâlâ yalnızca gezinmede.
/// > İkincisi düştü: gölge artık koyu zeminde değil, açık kâğıdın altında ve
/// > kâğıdı zeminden ayıran şeyin kendisi.
enum PatikaSurfaceMetrics {
    /// Açık duran, öne çıkan yüzey.
    static let radius: CGFloat = 24
    /// Kompakt satır.
    static let compactRadius: CGFloat = 18
    static let padding: CGFloat = 18
    static let compactPadding: CGFloat = 14
    /// HIG dokunma hedefi iki satırlı satırda da korunur.
    static let rowMinHeight: CGFloat = 52
    /// Bölümler arası.
    static let sectionSpacing: CGFloat = 28
    /// Bölüm başlığı ile içeriği arası.
    static let labelSpacing: CGFloat = 10
}

/// Yüzeyin mürekkebi.
///
/// Aynı bileşen hem koyu zeminde hem kâğıtta çalışsın diye renk **dışarıdan**
/// veriliyor. Varsayılan `.light`: mevcut ekranlar (JournalView, PathDetailView)
/// hiç değişmeden çalışmaya devam eder. Kâğıda geçen yüzey `.ink` ister.
///
/// Bileşenin içine iki renk gömmek yerine tek bir tip geçirmenin sebebi, üç ayrı
/// bileşende (`BaselineTrack`, `RouteSeal`, `UserQuote`) üç ayrı bayrak
/// üretmemek: mürekkep yüzeyin özelliği, bileşenin değil.
enum PatikaInk: Sendable {
    /// Koyu zemin — kırık beyaz mürekkep.
    case light
    /// Kâğıt yüzey — koyu adaçayı mürekkep.
    case ink

    var primary: Color {
        switch self {
        case .light: Theme.textPrimary.color
        case .ink: WoodlandStyle.ink
        }
    }

    var secondary: Color {
        switch self {
        case .light: Theme.textSecondary.color
        case .ink: WoodlandStyle.secondaryInk
        }
    }
}

/// Kâğıt yüzey. "Yolum"daki tabelayla birebir aynı malzeme.
struct PaperSurface: ViewModifier {
    var radius: CGFloat = PatikaSurfaceMetrics.radius
    /// Öne çıkan yüzey daha yüksekte durur; kompakt satır zemine yakın.
    var isProminent = true

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .background(
                WoodlandStyle.paper,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay {
                // Increase Contrast: kâğıdın kenarı zeminden kesin ayrılsın.
                if contrast == .increased {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(WoodlandStyle.ink.opacity(0.45), lineWidth: Theme.Line.border)
                }
            }
            .shadow(
                color: WoodlandStyle.ink.opacity(shadowOpacity),
                radius: isProminent ? 12 : 7,
                y: isProminent ? 5 : 3
            )
    }

    /// Reduce Transparency'de zemin düz renge döner; orada gölge bilgi taşımaz.
    private var shadowOpacity: Double {
        if reduceTransparency { return 0 }
        return isProminent ? 0.14 : 0.10
    }
}

extension View {
    func paperSurface(
        radius: CGFloat = PatikaSurfaceMetrics.radius,
        isProminent: Bool = true
    ) -> some View {
        modifier(PaperSurface(radius: radius, isProminent: isProminent))
    }
}

/// Zeminin üstünde duran bölüm başlığı — kâğıdın **dışında**, açık mürekkeple.
///
/// Büyük harfli üst etiket yok (`profile-design.md` §9.3): Türkçede büyük harf
/// dönüşümü yerel ayar ister (i → İ) ve sakin bir ekranda bağırır.
struct PatikaSectionLabel: View {
    private let title: Text
    private let actionTitle: LocalizedStringResource?
    private let action: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(title: LocalizedStringResource, actionTitle: LocalizedStringResource? = nil, action: (() -> Void)? = nil) {
        self.title = Text(title)
        self.actionTitle = actionTitle
        self.action = action
    }

    /// Çevrilmiş metni zaten `String` olarak taşıyan yüzeyler için (Keşfet).
    init(verbatim title: String, actionTitle: LocalizedStringResource? = nil, action: (() -> Void)? = nil) {
        self.title = Text(verbatim: title)
        self.actionTitle = actionTitle
        self.action = action
    }

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
    }

    var body: some View {
        layout {
            title
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(Theme.TypeFace.lockMark)
                            .accessibilityHidden(true)
                    }
                    .font(Theme.TypeFace.rowAction)
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.calm)
            }
        }
    }
}

/// Kompakt kâğıt satır — "tek açık, kalanı kompakt" ritminin kompakt yarısı.
///
/// "Ben" sekmesinde sekiz bölümün yedisi bu satır; yalnızca "Ne değişti" açık
/// duruyor. Hepsini kart yapmak sayfayı eşit ağırlıkta sekiz kutuya bölüyordu ve
/// hangisinin önemli olduğu okunmuyordu (ürün sahibi geri bildirimi, 2026-09-17).
struct PatikaRow: View {
    let title: LocalizedStringResource
    var symbol: String?
    var value: String?
    var caption: String?
    var showsChevron = true
    var action: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.calm)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        HStack(spacing: 14) {
            if let symbol {
                Image(systemName: symbol)
                    .font(Theme.TypeFace.rowSymbol)
                    .foregroundStyle(WoodlandStyle.ink)
                    .frame(width: 26)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                // Dar ekranda etiket ve değer yan yana sığmaz; AX'te alt alta.
                if dynamicTypeSize.isAccessibilitySize {
                    titleText
                    if let value { valueText(value) }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        titleText
                        Spacer(minLength: 8)
                        if let value { valueText(value) }
                    }
                }
                if let caption {
                    Text(verbatim: caption)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(Theme.TypeFace.lockMark)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, PatikaSurfaceMetrics.compactPadding + 2)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: PatikaSurfaceMetrics.rowMinHeight, alignment: .leading)
        .contentShape(.rect)
        .paperSurface(radius: PatikaSurfaceMetrics.compactRadius, isProminent: false)
    }

    private var titleText: some View {
        Text(title)
            .font(Theme.TypeFace.rowTitle)
            .foregroundStyle(WoodlandStyle.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func valueText(_ value: String) -> some View {
        Text(verbatim: value)
            .font(Theme.TypeFace.rowValue)
            .foregroundStyle(WoodlandStyle.secondaryInk)
            .multilineTextAlignment(.leading)
    }
}

/// Kâğıt içi satır ayırıcı — koyu zemindeki açık çizginin kâğıttaki karşılığı.
struct PaperRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(WoodlandStyle.secondaryInk.opacity(0.16))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

#Preview("Patika yüzeyleri") {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        ScrollView {
            VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
                    PatikaSectionLabel(title: "Ne değişti")
                    VStack(alignment: .leading, spacing: 12) {
                        Text(verbatim: "Kaçınman azalıyor. Duygunun şiddeti başladığın yerde.")
                            .font(Theme.TypeFace.cardTitleProminent)
                            .foregroundStyle(WoodlandStyle.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: "Başlangıcın · 7. adımda ölçüldü")
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(WoodlandStyle.secondaryInk)
                    }
                    .padding(PatikaSurfaceMetrics.padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paperSurface()
                }

                VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
                    PatikaSectionLabel(title: "Sana göre ayarlananlar")
                    PatikaRow(
                        title: "Hatırlatma",
                        value: "22:30",
                        caption: "\"Yatağa girince\" dediğin için",
                        action: {}
                    )
                    PatikaRow(title: "Adım uzunluğu", value: "10 dakika", showsChevron: false)
                    PatikaRow(title: "Destek al", symbol: "hand.raised", caption: "Konuşabileceğin biri, şimdi", action: {})
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
    }
    .preferredColorScheme(.dark)
}
