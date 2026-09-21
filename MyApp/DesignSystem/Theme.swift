import SwiftUI

/// Tasarım sabitleri. Değerler PRD-Ek Görsel Sistem §5 ve Ton eki §2.1, §7'den gelir.
enum Theme {
    /// Kırık beyaz — saf beyaz değil, göz yormaz (Görsel Sistem §5).
    static let textPrimary = RGB(hex: 0xF2EFE9)
    static let textSecondary = RGB(hex: 0xF2EFE9).scaled(brightness: 0.72)

    /// WCAG AA. Büyük başlıklar için 3:1 kabul edilebilir.
    static let minimumContrast: Double = 4.5
    static let minimumContrastLargeText: Double = 3.0

    enum Control {
        static let cornerRadius: CGFloat = 20
    }

    enum Spacing {
        static let screenMargin: CGFloat = 24
        static let stack: CGFloat = 16
        static let tight: CGFloat = 8
    }

    /// Tipografi ağırlıkları — **tek kaynak**.
    ///
    /// Ürünün genel tavrı bilinçli olarak sistem varsayılanından bir kademe kalındır
    /// (ürün sahibi kararı, 2026-09-08). Gerekçe: tek mürekkepli, gradyan üstünde
    /// duran bir arayüzde ince metin hem kontrast hem karakter kaybediyor; kalın
    /// harf net konuşan bir ses tonunun görsel karşılığı.
    ///
    /// Kademe geri alınacaksa **yalnızca burası** değişir — hiçbir yerde satır içi
    /// `.weight(...)` yazılmaz.
    enum Weight {
        /// `DisplayText` — iri başlıklar.
        static let display: Font.Weight = .bold
        /// Ekran içi ara başlıklar, ölçüm soruları.
        static let title: Font.Weight = .semibold
        /// Gövde metni. Sistem varsayılanı `.regular`; bir kademe yukarıda.
        static let body: Font.Weight = .medium
        /// Buton ve dokunulabilir her şey.
        static let action: Font.Weight = .bold
        /// Seçili olmayan kart etiketi gibi ikincil vurgu.
        static let emphasis: Font.Weight = .semibold
    }

    /// Çizgi kalınlıkları. İz ve kenarlıklar da bir kademe kalın.
    enum Line {
        /// `PathProgressBar` izi.
        static let progressTrack: CGFloat = 5
        /// Seçili kart kenarlığı.
        static let border: CGFloat = 2
        /// "Yolum" sekmesindeki tek parça iz. `PathProgressBar`ın izinden ince:
        /// o bir gösterge, bu bir zemin çizgisi.
        static let trail: CGFloat = 2
        /// Düğüm ile gerçek adım metni arasındaki yönsüz kılavuz.
        static let journeyConnector: CGFloat = 1
    }

    /// Mesh üstünde okunur içerik yüzeyi — "Ben" sekmesinin kartları
    /// (`docs/profile-design.md` §9.2).
    ///
    /// Liquid Glass değil: iOS 26 yönergesi camı gezinme ve kontrol katmanına
    /// ayırıyor. Sekme çubuğu ve sheet'ler sistem camını kullanıyor; içerik kartı
    /// sade bir koyu yüzey.
    enum Surface {
        static let cornerRadius: CGFloat = 24
        static let padding: CGFloat = 20
        static let fillOpacity: Double = 0.22
        static let strokeOpacity: Double = 0.08
        /// Increase Contrast.
        static let fillOpacityHighContrast: Double = 0.34
        static let strokeOpacityHighContrast: Double = 0.20
        /// Reduce Transparency'de zemin zaten düz koyu renk.
        static let fillOpacityOpaqueBackground: Double = 0.12
    }

    /// Kimin konuştuğu fontan okunur (ürün sahibi onayı, 2026-09-12): kullanıcının
    /// kendi cümlesi serif (New York), ürünün sesi SF Pro. Sistem fontu olduğu için
    /// Dynamic Type ve Bold Text ile kendiliğinden uyumlu, ek varlık getirmez.
    enum Voice {
        static func user(_ style: Font.TextStyle = .body) -> Font {
            .system(style, design: .serif, weight: Weight.body)
        }
    }

    /// Tipografi rolleri — **tek kaynak**, `Weight` ile aynı mantıkta.
    ///
    /// Ağırlık nasıl rolden geliyorsa punto da rolden gelir: çağrı yerinde
    /// `.font(.caption)` yazılmaz. Gerekçe (ürün sahibi kararı, 2026-09-17): ham
    /// sistem stilleri SF Pro döndürüyor, `product(_:_:)` ise yuvarlak aileyi.
    /// İkisi aynı ekranda karışınca ürünün tek bir yazı sesi olmuyor — "Yolum"
    /// ekranında başlık Pro, gövde Rounded'dı ve ekran iki ayrı üründen
    /// derlenmiş gibi okunuyordu.
    ///
    /// Aile değişecekse yalnızca `product(_:_:)` değişir.
    enum TypeFace {
        static func product(_ style: Font.TextStyle, _ weight: Font.Weight) -> Font {
            .system(style, design: .rounded, weight: weight)
        }

        /// Ekranın kim olduğunu söyleyen küçük üst satır ("Yolum").
        /// `tracking` çağrı yerinde 1.2 — 2.0'da bu puntoda harfler dağılıyordu.
        static var eyebrow: Font { product(.caption2, Weight.emphasis) }
        /// Ekran başlığı. `largeTitle` değil: başlık ekranın sahibi değil kapısı,
        /// ve iri punto üst alanı gereksiz büyütüyordu.
        static var screenTitle: Font { product(.title2, Weight.display) }
        /// Başlık altındaki tek açıklama satırı.
        static var screenNote: Font { product(.footnote, Weight.body) }
        /// Duraktaki adımın adı.
        static var cardTitle: Font { product(.callout, Weight.title) }
        /// Sıradaki durak bir kademe iri — ekranda göz önce oraya gitsin.
        static var cardTitleProminent: Font { product(.title3, Weight.title) }
        /// "3. adım", "Ölçüm günü" gibi durak üstü işaretler.
        static var cardMeta: Font { product(.caption, Weight.emphasis) }
        /// Açılan ayrıntıdaki gövde.
        static var detailBody: Font { product(.subheadline, Weight.body) }
        /// Durak düğümünün içindeki gün sayısı ve simge.
        static var nodeMark: Font { product(.headline, Weight.action) }
        /// Kompakt duraklarda aynı işaret — daire 46 pt'ye indiğinde `headline`
        /// kenarlara değiyordu.
        static var nodeMarkCompact: Font { product(.subheadline, Weight.action) }
        /// Kilit, chevron gibi metnin yanında duran küçük durum simgeleri.
        static var lockMark: Font { product(.caption2, Weight.emphasis) }

        // MARK: Kompakt satır ("Ben", "Keşfet")

        /// Krem kapaktaki ad — sayfanın en iri yazısı (`profile-design.md` §20).
        static var coverTitle: Font { product(.largeTitle, Weight.display) }
        /// Zemin üstündeki bölüm başlığı.
        static var sectionTitle: Font { product(.title3, Weight.title) }
        /// Kompakt kâğıt satırın etiketi.
        static var rowTitle: Font { product(.body, Weight.emphasis) }
        /// Satırın sağındaki değer.
        static var rowValue: Font { product(.body, Weight.body) }
        /// Değerin kaynağını söyleyen alt satır ("…dediğin için").
        static var rowCaption: Font { product(.footnote, Weight.body) }
        /// Satır başındaki SF Symbol.
        static var rowSymbol: Font { product(.title3, Weight.title) }
        /// Bölüm başlığındaki "Tümü" gibi ikincil eylemler.
        static var rowAction: Font { product(.subheadline, Weight.action) }
        /// Buton.
        static var action: Font { product(.callout, Weight.action) }
    }

    /// Tüm animasyonlar 800 ms altı (Ton eki §7). Uzun animasyon = bekletme.
    enum Motion {
        /// Ekran geçişleri: cross-fade, slide yok (Ton eki §2.1).
        static let screenTransition: Double = 0.25
        /// Adım dolma animasyonu — konfeti yok.
        static let stepFill: Double = 0.40
        /// Ölçüm barları: sayı hemen görünmez, önce hareket.
        static let measurementBar: Double = 0.80
        /// A2 palet geçişi. Ani değişim irkiltir (Görsel Sistem §3.3).
        static let paletteTransition: Double = 1.20
        /// Rozet belirme.
        static let badgeReveal: Double = 0.60

        /// Onboarding adım geçişi **sıralıdır**: giden ekran solar, sonra gelen
        /// ekran belirir. Eşzamanlı cross-fade'de iki farklı yükseklikteki içerik
        /// üst üste binip kirli görünüyordu.
        static let stepFadeOut: Double = 0.16
        static let stepFadeIn: Double = 0.34
        /// İlerleme izi kabuğun kalıcı parçası — adımdan bağımsız, kendi hızında
        /// akar. Geçişten yavaş olması "yol kat ediliyor" hissini taşıyan şey.
        static let progressTravel: Double = 0.55

        /// C bölümünde cümleler tek tek belirir (ürün sahibi kararı, 2026-09-08).
        /// Gerekçe: bu ekranlarda okumasını istediğimiz bir metin var; hepsini
        /// aynı anda basmak "duvar" gibi görünüyor ve göz nereden başlayacağını
        /// bilemiyor. Sırayla belirmek okuma sırasını dayatmadan öneriyor.
        ///
        /// Ekran geçişi bitsin, sonra ilk cümle gelsin.
        static let revealLeadIn: Double = 0.40
        /// İki cümle **başlangıcı** arası. Fade 0.7 sn sürdüğü için sonraki
        /// cümle, bir önceki tamamen oturduktan ~0.8 sn sonra başlar. C bölümü
        /// soru değil anlatı olduğu için bu sessizlik metne nefes verir.
        ///
        /// 1.0'dan 1.5'e çıkarıldı (ürün sahibi kararı, 2026-09-08): bir saniye,
        /// önceki cümleyi okuyup bitirmeye yetmiyordu — sonraki cümle okuma
        /// devam ederken beliriyor ve gözü aşağı çekiyordu.
        ///
        /// **2026-09-21: C bölümü artık bunu kullanmıyor.** Ürün sahibi kararı
        /// geri aldı: cümle cümle bekleme uygulamanın yavaş olduğu hissini
        /// veriyordu. Kâğıt ekranlar `woodlandReveal` (0,045 sn adım, en fazla 5
        /// adım) kullanır (`statementReveal`). Bu değer yalnızca zemin
        /// malzemesinde kalan tek tüketici için duruyor: `PathSessionView`
        /// (oturumun ortası, bilerek dokunulmadı; D0 kâğıda alındı). O da geçerse
        /// `revealStagger` ve `sequentialReveal` silinmeli; ikisi de silinene kadar
        /// bu değeri geri yükseltmek C'yi etkilemez.
        static let revealStagger: Double = 1.50
        /// Her cümlenin kendi solması. Kısa olursa "belirdi" okunmaz, uzun
        /// olursa takılmış gibi durur.
        static let revealFade: Double = 0.70

        /// F2'nin kendiliğinden aşağı inip geri çıkması (ürün sahibi kararı,
        /// 2026-09-09). Harita ekrana sığmıyor ve alt satırların varlığı yalnızca
        /// kaydıran kullanıcıya görünüyordu; ekran kendi kendine bir kez aşağı
        /// inip geri çıkınca "burada daha var" bilgisi kaydırma gerektirmeden
        /// veriliyor.
        ///
        /// **800 ms kuralının bilinçli istisnası.** O kural durum geçişleri için:
        /// bir dokunuşun karşılığı 800 ms'den uzun sürerse arayüz ağır hissedilir.
        /// Buradaki hareket bir geçiş değil, içeriğin gösterilmesi — ve hızlısı
        /// okunmuyor, savrulma gibi duruyordu. Kullanıcı ekrana dokunduğu anda
        /// iptal ediliyor ve Reduce Motion'da hiç çalışmıyor.
        static let roadmapTourLeadIn: Double = 1.10
        static let roadmapTourDown: Double = 1.50
        static let roadmapTourHold: Double = 0.55
        static let roadmapTourUp: Double = 1.20

        /// "Yolum"da bir adımın açılıp kapanması.
        ///
        /// Yay, süre değil: açılan kartın yüksekliği içeriğe göre değişiyor ve
        /// sabit süreli bir eğri kısa kartta tembel, uzun kartta aceleci
        /// duruyordu. `dampingFraction` 0.86 — sekme yok, ama duruş yumuşak.
        /// Toplam oturma süresi ~0.42 sn, 800 ms bütçesinin içinde.
        static let pathExpand: Animation = .spring(response: 0.42, dampingFraction: 0.86)

        /// Başlığın kaydırmada gidip gelmesi. `dampingFraction` 0.90'dan 0.82'ye
        /// indirildi (ürün sahibi kararı, 2026-09-17): 0.90 yaylanmayı tamamen
        /// yutuyor ve hareket "kesildi" gibi duruyordu; 0.82 girip çıkışa ağırlık
        /// veriyor ama başlığı zıplatmıyor.
        static let headerReveal: Animation = .spring(response: 0.46, dampingFraction: 0.82)

        /// Tabelanın açılıp kapanması — `pathExpand`ten belirgin şekilde canlı.
        ///
        /// `dampingFraction` 0.72: etiket düğümden aşağı sarkarken bir kez hafifçe
        /// yaylanıyor, sonra oturuyor. Sekme değil, ağırlığı olan bir nesnenin
        /// durması. Oturma süresi ~0.70 sn, 800 ms bütçesinin içinde.
        static let bouncy: Animation = .spring(response: 0.48, dampingFraction: 0.72)

        /// Yön değiştirmeyen geçişler: başlığın gidip gelmesi, opaklık, kaydırma.
        /// Başı ve sonu yumuşak — sabit hızlı bir geçiş mekanik duruyordu.
        static let glide: Animation = .easeInOut(duration: 0.34)

        /// F2 ve "Yolum"daki kıvrımlı rotanın bir satırlık çizim süresi.
        /// `trim` GPU-dostu bir shape animasyonu; satırlar kısa aralıklarla
        /// başlar ve toplam hareket 800 ms durum bütçesini aşmaz.
        static let journeyRouteDraw: Double = 0.44
        static let journeyNodeStagger: Double = 0.045
        static let journeyTextReveal: Double = 0.30
        static let journeyPhaseReveal: Double = 0.26
        static let journeyNodeReplace: Double = 0.22
        static let journeyPress: Double = 0.14

        /// Yeni mührün çizilmesi — rota ve uç düğüm birlikte ilerler.
        static let sealDraw: Double = 0.70
        /// "Ne değişti" satırları arası gecikme: noktalar başlangıç işaretinden
        /// sırayla kayar (her biri `measurementBar` sürer).
        static let changeRowStagger: Double = 0.12

        /// Liste hâlindeki öğeler için çok daha kısa aralık. C'nin 1.5 saniyesi
        /// okunacak cümleler içindi; yedi satırlık bir yol haritasında aynı ritim
        /// son satırı 14. saniyede gösterirdi. Burada beliriş bir okuma temposu
        /// değil, izin yukarıdan aşağı çizilmesi.
        static let listRevealStagger: Double = 0.11

        /// Sırada `index` numaralı öğenin belirmeye başlama anı. Sıraya dahil
        /// olmayan ama sırayı bekleyen öğeler (C4 grafiği) de bunu kullanıyor.
        static func revealDelay(_ index: Int, stagger: Double? = nil) -> Double {
            revealLeadIn + Double(index) * (stagger ?? revealStagger)
        }

        /// C4 süreç grafiği iki ayrı fikir anlattığı için çizgiler sırayla gelir:
        /// önce diğer uygulamaların dalgalanması, kısa bir nefes, sonra Patika.
        static let expectationOtherAppsDraw: Double = 1.15
        static let expectationBetweenLines: Double = 0.22
        static let expectationPatikaDraw: Double = 1.55

        /// Arka plan mesh'inin sabit durum kare hızı. Nefes döngüsü 10 saniye
        /// olduğu için kare başına değişim çok küçük; 30 fps ile 60 fps arasında
        /// görünür fark yok ama pil farkı var (Görsel Sistem §6.6).
        static let backgroundFPS: Double = 30
        /// Palet/ruh hâli geçişi süresince. 1.2 saniyede dokuz rengin birden
        /// taşındığı tek an, zamansal basamağın görüldüğü de tek yer.
        static let backgroundBoostFPS: Double = 60

        static var crossFade: Animation { .easeInOut(duration: screenTransition) }
        static var palette: Animation { .easeInOut(duration: paletteTransition) }
        static var progress: Animation { .smooth(duration: progressTravel) }
        static let press: Animation = .spring(response: 0.32, dampingFraction: 0.78)
    }

    /// Haptik tek seviyedir (Ton eki §7): başka stil kullanılmaz.
    /// Ses efektleri varsayılan olarak KAPALI — beklenmedik "ding" tam olarak
    /// istemediğimiz tepkiyi üretir.
    @MainActor
    /// - Parameter intensity: 0…1. **Stil değil şiddet** ayarlanır — basılı tutma
    ///   jestindeki hızlanan nabız (bkz. `HoldToStartButton`) tek kademe kuralını
    ///   bozmadan böyle kuruluyor.
    static func softHaptic(intensity: CGFloat = 1.0) {
        UIImpactFeedbackGenerator(style: .soft)
            .impactOccurred(intensity: min(max(intensity, 0), 1))
    }
}

/// Buton basımı: 0.98 scale + yumuşak haptic (Ton eki §2.1).
struct CalmButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.86 : 1.0)
            .animation(reduceMotion ? .easeInOut(duration: 0.18) : Theme.Motion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CalmButtonStyle {
    static var calm: CalmButtonStyle { CalmButtonStyle() }
}

/// Sıraya dizilmiş bir öğenin gecikmeli belirmesi.
///
/// Ekran ilk göründüğünde tetiklenir ve bir daha çalışmaz: kullanıcı geri gelip
/// aynı ekranı tekrar açtığında metin yeniden tek tek belirir, ama ekran içindeki
/// bir değişiklik (Dynamic Type, döndürme) animasyonu baştan başlatmaz.
private struct SequentialReveal: ViewModifier {
    let index: Int
    let stagger: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            // Reduce Motion'da kayma yok, yalnızca solma (Ton eki §7).
            .offset(y: isVisible || reduceMotion ? 0 : 8)
            .task {
                guard !isVisible else { return }
                try? await Task.sleep(
                    for: .seconds(Theme.Motion.revealDelay(index, stagger: stagger))
                )
                withAnimation(.easeOut(duration: Theme.Motion.revealFade)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Cümle cümle belirme, okuma temposunda (1,5 sn adım). **C bölümü artık
    /// kullanmaz** (2026-09-21, bkz. `revealStagger`); C ekranları
    /// `statementReveal` ile malzemeyi izler. `index` sıradaki yerdir, 0'dan başlar.
    func sequentialReveal(_ index: Int) -> some View {
        modifier(SequentialReveal(index: index, stagger: nil))
    }

    /// Liste öğeleri için hızlı sıra — F2'nin yol haritası gibi. Aynı beliriş,
    /// okuma temposu yerine çizilme temposu.
    func listReveal(_ index: Int) -> some View {
        modifier(SequentialReveal(index: index, stagger: Theme.Motion.listRevealStagger))
    }
}

extension AnyTransition {
    /// Onboarding içerik geçişi.
    ///
    /// **Yatay kayma yok** (Ton eki §2.1): "yeni sayfa açıldı" hissi akışı 31 ayrı
    /// ekran gibi gösteriyor. Bunun yerine giden içerik solar, sonra gelen içerik
    /// birkaç punto aşağıdan yukarı süzülerek belirir — aynı ekranda içeriğin
    /// değiştiği okunur. Üst çubuk (geri + iz) geçişe hiç katılmaz; kabukta durur.
    ///
    /// Toplam süre 500 ms, 800 ms bütçesinin içinde.
    static func onboardingStep(reduceMotion: Bool) -> AnyTransition {
        let appear: AnyTransition = reduceMotion
            ? .opacity
            : .opacity.combined(with: .offset(y: 14))

        return .asymmetric(
            insertion: appear.animation(
                .easeOut(duration: Theme.Motion.stepFadeIn)
                    .delay(Theme.Motion.stepFadeOut)
            ),
            removal: .opacity.animation(.easeIn(duration: Theme.Motion.stepFadeOut))
        )
    }
}
