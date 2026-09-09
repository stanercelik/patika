import Foundation

/// Oturumun tek bir yönergesi.
///
/// Süre saniyeyle değil **nefes döngüsüyle** ölçülür (`BreathCycle.period`, 10 sn).
/// Gerekçe: ekrandaki arka plan zaten o döngüyle soluyor ve kullanıcı farkında
/// olmadan nefesini ona uyduruyor (Görsel Sistem eki §4). Yönergeyi saniyeye
/// bağlamak, metnin döngünün ortasında değişmesine ve nefesin bölünmesine yol
/// açıyordu.
struct SessionCue: Sendable, Identifiable {
    let id: String
    let text: LocalizedStringResource
    /// Bu yönergenin kaç nefes döngüsü boyunca ekranda kalacağı.
    let breaths: Int

    var duration: TimeInterval { Double(breaths) * BreathCycle.period }
}

/// Onaylanmış teknik bloğu.
///
/// **Kimlikler sunucudaki `approvedBlockIds` ile birebir aynıdır.** LLM serbest
/// içerik üretmiyor, bu listeden seçiyor (PRD §9.1); istemci de aynı listeden
/// çiziyor. Sunucu tanımadığı bir kimlik gönderemez — şemada `enum` — ama
/// istemci yine de eksik kimliği sessizce atlar: eski bir uygulama sürümü yeni
/// bir bloğa denk gelirse oturum çökmemeli, kısalmalı.
struct SessionBlock: Sendable, Identifiable {
    let id: String
    let title: LocalizedStringResource
    let cues: [SessionCue]
}

/// İstemcideki blok kütüphanesi.
///
/// ## Neden istemcide metin var
///
/// Bloklar **sabit tekniklerdir**: "dörde kadar say"ın kişiselleştirilmiş
/// versiyonu yok (PRD-Ek Path Üretimi §4). Kişiselleştirme çerçevede — açılış,
/// geçiş ve kapanış — ve o metinler sunucudan `slotCopy` ile geliyor. Tekniği de
/// sunucudan indirmek, her oturumda değişmeyen bir metni ağdan çekmek olurdu ve
/// çevrimdışı oturumu imkânsız kılardı.
///
/// ## Ton
///
/// Metinler Sakin kademede (Ton eki §3): emir yok, garanti yok, "başaracaksın"
/// yok. "Yapabiliyorsan", "istersen" gibi kaçış payları bilinçli — gözünü kapatmak
/// istemeyen biri talimatı çiğnemiş hissetmemeli.
enum BlockLibrary {
    static func block(id: String) -> SessionBlock? { blocks[id] }

    static let blocks: [String: SessionBlock] = [
        breathAwareness.id: breathAwareness,
        bodyGrounding.id: bodyGrounding,
        reflectionNotice.id: reflectionNotice,
    ]

    static let breathAwareness = SessionBlock(
        id: "breath.awareness.v1",
        title: "Nefesi fark etmek",
        cues: [
            .init(
                id: "breath.settle",
                text: "Oturduğun yerde biraz yerleş. Gözlerini kapatmak istersen kapat, istemezsen bir noktaya bak.",
                breaths: 2
            ),
            .init(
                id: "breath.notice",
                text: "Nefesini değiştirmeye çalışma. Sadece nereden geçtiğini fark et — burnundan mı, göğsünden mi.",
                breaths: 3
            ),
            .init(
                id: "breath.follow",
                text: "Şimdi ekrandaki hareketi takip et. Genişlerken al, daralırken bırak.",
                breaths: 4
            ),
            .init(
                id: "breath.longer",
                text: "Verirken biraz daha uzat. Acele yok; nefes kendi hızını bulur.",
                breaths: 4
            ),
        ]
    )

    static let bodyGrounding = SessionBlock(
        id: "body.grounding.v1",
        title: "Bedene dönmek",
        cues: [
            .init(
                id: "body.contact",
                text: "Ayaklarının zeminle, sırtının arkasındaki yüzeyle temas ettiği yeri fark et.",
                breaths: 3
            ),
            .init(
                id: "body.scan",
                text: "Omuzlarına gel. Kalkıksa bırak, bırakmıyorsa zorlama — fark etmek de yeterli.",
                breaths: 3
            ),
            .init(
                id: "body.jaw",
                text: "Çeneni ve alnını kontrol et. Sıkılıysa gevşesin.",
                breaths: 3
            ),
            .init(
                id: "body.whole",
                text: "Bir an için bedenini bir bütün olarak hisset. Bir yeri düzeltmen gerekmiyor.",
                breaths: 3
            ),
        ]
    )

    static let reflectionNotice = SessionBlock(
        id: "reflection.notice.v1",
        title: "Fark ettiğini adlandırmak",
        cues: [
            .init(
                id: "reflect.name",
                text: "Şu an içeride ne varsa ona bir ad ver. Gerginlik, yorgunluk, huzursuzluk — hangisiyse.",
                breaths: 3
            ),
            .init(
                id: "reflect.allow",
                text: "Adını koyduğun şeyi değiştirmeye çalışma. Bugünlük fark etmiş olmak yeterli.",
                breaths: 3
            ),
            .init(
                id: "reflect.return",
                text: "Dikkatin dağıldıysa sorun değil — dağılması normal. Nefese geri dön.",
                breaths: 3
            ),
        ]
    )

    /// Sunucudan gelen serbest metin yuvaları (PRD-Ek Path Üretimi §3).
    /// Yalnızca bu dört ad tanınır; sunucu şeması da aynı dördünü kabul ediyor.
    enum Slot: String, CaseIterable {
        case opening = "step_opening"
        case techniqueBridge = "technique_bridge"
        case midBridge = "mid_bridge"
        case closing = "step_closing"
    }
}
