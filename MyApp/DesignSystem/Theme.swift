import SwiftUI

/// Tasarım sabitleri. Değerler PRD-Ek Görsel Sistem §5 ve Ton eki §2.1, §7'den gelir.
enum Theme {
    /// Kırık beyaz — saf beyaz değil, göz yormaz (Görsel Sistem §5).
    static let textPrimary = RGB(hex: 0xF2EFE9)
    static let textSecondary = RGB(hex: 0xF2EFE9).scaled(brightness: 0.72)

    /// WCAG AA. Büyük başlıklar için 3:1 kabul edilebilir.
    static let minimumContrast: Double = 4.5
    static let minimumContrastLargeText: Double = 3.0

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
        static let display: Font.Weight = .heavy
        /// Ekran içi ara başlıklar, ölçüm soruları.
        static let title: Font.Weight = .bold
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
        /// devam ederken beliriyor ve gözü aşağı çekiyordu. Ritmi yavaşlatmak bu
        /// ekranlarda maliyetsiz, çünkü CTA baştan beri basılabilir durumda:
        /// beklemek isteyen bekliyor, istemeyen geçiyor.
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

        /// F2 ve "Yolum"daki kıvrımlı rotanın bir satırlık çizim süresi.
        /// `trim` GPU-dostu bir shape animasyonu; satırlar kısa aralıklarla
        /// başlar ve toplam hareket 800 ms durum bütçesini aşmaz.
        static let journeyRouteDraw: Double = 0.44
        static let journeyNodeStagger: Double = 0.045
        static let journeyTextReveal: Double = 0.30
        static let journeyPhaseReveal: Double = 0.26
        static let journeyNodeReplace: Double = 0.22
        static let journeyPress: Double = 0.14

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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
    /// C bölümünün cümle cümle belirmesi. `index` sıradaki yerdir, 0'dan başlar.
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
