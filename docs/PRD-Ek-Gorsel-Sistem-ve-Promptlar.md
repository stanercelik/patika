# PRD Eki — Görsel Sistem, Animasyon Mimarisi ve Prompt Seti

**Ana doküman:** PRD.md · **İlgili ekler:** PRD-Ek-Onboarding.md, PRD-Ek-Ton-ve-Nudge.md
**Durum:** Taslak v0.1 · **Tarih:** 4 Eylül 2026

---

## 1. Karar: video değil, shader

Sorunuz "MiniMax H3 image-to-video mi, reference-to-video mu?" idi. Cevap: **uygulama içinde hiçbiri.**

### Neden video uygulama içine girmiyor

| Kriter | Video (H3 vb.) | Shader (kod) |
|---|---|---|
| **Seçime göre renk değişimi** | ❌ İmkânsız — her kombinasyon için ayrı video gerekir. 10 kategori, 2 seçim → 55 kombinasyon → 55 video | ✅ Uniform değişkeni, anında |
| **Dosya boyutu** | 2–6 MB/video × 55 = ~150–300 MB | ~4 KB shader kodu |
| **Kusursuz döngü** | ❌ Dikiş görünür | ✅ Matematiksel olarak sonsuz |
| **Nefes senkronu** | ❌ Sabit hız | ✅ Gerçek zamanlı `breathValue(at:)` |
| **Pil / ısınma** | Sürekli video decode | GPU fragment shader, çok daha ucuz |
| **Reduced motion** | Ayrı statik varlık gerekir | Tek satır: `speed = 0` |
| **Çözünürlük** | Sabit | Cihaz çözünürlüğünde native |

Rakamlar da bunu destekliyor: <cite index="11-2">H3 4–15 saniyelik klipler üretiyor ve API fiyatı saniye başına 0,13 dolar</cite>. 55 kombinasyon × 10 sn = ~715 dolar, ve sonuç yine statik olurdu. Shader tek seferlik geliştirme.

Ek bir uyarı: <cite index="11-4">H3'ün açık ağırlıkları bölge kısıtlı — MiniMax'in topluluk lisansı ABD, AB, Birleşik Krallık ve Güney Kore'yi dışarıda bırakıyor</cite>. AB'de faaliyet gösteriyorsanız self-host seçeneği kapalı, sadece API kalıyor.

### Video nerede kullanılacak

Uygulama içinde değil, **pazarlamada**:
- App Store / Play önizleme videosu (15–30 sn)
- Meta ve TikTok reklam kreatifleri
- Landing page hero

Bunlar için H3 uygun ve prompt'ları Bölüm 8'de.

---

## 2. Teknoloji yığını

> **Platform: iOS-only, SwiftUI native, iOS 18+.** (PRD Bölüm 13.1) Aşağıdaki her şey native API'lerle çözülüyor — üçüncü parti render kütüphanesi yok.

### 2.1 Arka plan gradyanları → **SwiftUI MeshGradient + Metal shader**

Aradığımız her şey işletim sisteminde hazır.

**MeshGradient** iOS 18, macOS 15, visionOS 2 ile geldi. Rastgele bir renkli kontrol noktası ızgarasını yumuşak, çok renkli bir gradyana harmanlayan bir shape style; iOS 18 duvar kağıtlarındaki o boyanmış, yumuşak parlamalı arka planları üretiyor. GPU üzerinde Metal ile çalışıyor ve kontrol noktalarını değiştirdiğinizde örtük olarak animasyon yapıyor. Örnekler yalnızca SwiftUI kullanıyor — Metal dosyası, shader kütüphanesi veya özel çizim katmanı gerekmiyor.

Bu bizim için tam isabet: **"seçime göre renk değiştiren gradyan" özelliği, renk dizisini `withAnimation` içinde değiştirmekten ibaret.** İnterpolasyonu sistem yapıyor.

**Grain ve metin karartması** için üstüne bir Metal `colorEffect` shader'ı bindiriyoruz. `colorEffect` piksel pozisyonunu verdiği için grain ve güvenli bölge tek geçişte hallediliyor.

**Katman yapısı:**

```
ZStack
 └─ MeshGradient          ← renkler + hareket (sistem)
     └─ .colorEffect()    ← grain + metin scrim'i (Metal, ~15 satır)
         └─ içerik        ← metin, butonlar
```

### 2.2 Yol ve rozet animasyonları → **Rive iOS runtime**

A1'deki yol çizim animasyonu ve rozetler için. Rive dosyaları çalışma zamanı için tasarlanmış hafif ikili formatta ve genelde eşdeğer Lottie dosyalarından 10–15 kat küçük — 240 KB'lık bir Lottie animasyonu Rive'da 16 KB olabiliyor. GPU render iOS'ta Metal kullanıyor ve bellek kısıtlı cihazlarda bile akıcı çalışıyor.

2026 durumu şöyle özetleniyor: tasarımcı üretimi animasyonlar için Lottie, etkileşimli durum makineli animasyonlar için Rive. Bizde A1 bir durum makinesi gerektiriyor (yol çiziliyor → adımlar doluyor → barlar beliriyor → döngü), o yüzden **Rive**.

> **Alternatif:** A1 animasyonu SwiftUI'ın kendi `Path` + `trim(from:to:)` API'siyle de yazılabilir — sıfır bağımlılık, ~80 satır kod. Tasarımcınız yoksa bu yol daha hızlı. Rive'ı ancak animasyonları tasarımcı yapacaksa alın.

### 2.3 Nefes küresi → aynı MeshGradient

Oturum ekranındaki nefes küresi ayrı bir varlık değil. Tek merkezli bir mesh konfigürasyonu + `RadialGradient` maskesi. Ek dosya yok.

### 2.4 Android geldiğinde (Faz 4)

Görsel dil kaybolmaz. Jetpack Compose'da `RuntimeShader` + AGSL ile aynı matematiği kurabilirsiniz; Paper Shaders'ın Compose portu mesh-gradient ve grain-gradient dahil 29 shader içeriyor ve Android 13 / API 33+ hedefliyor. Yani port edilecek şey shader mantığı, tasarım kararları değil.

### 2.5 Varlık boyutu

| Katman | Araç | Boyut |
|---|---|---|
| Arka plan gradyanları (tüm ekranlar) | MeshGradient + Metal | **0 KB** (sistem) + ~1 KB shader |
| Palet tanımları | Swift struct / JSON | ~3 KB |
| A1 yol animasyonu | Rive veya SwiftUI Path | ~20 KB / 0 KB |
| Rozet animasyonları | Rive | ~30 KB |
| Nefes küresi | Aynı MeshGradient | 0 KB |
| İlerleme barları | SwiftUI native | 0 KB |
| SOS ses blokları (çevrimdışı) | AAC | ~2 MB |
| **Toplam görsel varlık** | | **< 60 KB** |

## 3. Renk sistemi

### 3.1 Temel ilke

Referans görsellerinizdeki turuncu/kırmızı palet güzel ama **bizim kitlemiz için tehlikeli**. Kaygılı bir kullanıcıya yüksek doygunluklu sıcak kırmızı göstermek fizyolojik olarak uyarıcı. O yüzden:

- **Ton (hue)** sorun tipine göre değişir
- **Doygunluk ve parlaklık sabit bir sakin bantta kalır** (S: 25–45%, L: 12–38%)
- Hiçbir palette saf kırmızı yok

### 3.2 Kategori paletleri

Her palet 4 renk noktası + arka plan. A2'de seçilen kategoriye göre atanır.

| A2 seçimi | Anahtar | Renk noktaları | Arka plan |
|---|---|---|---|
| 😰 Kaygı | `anxiety` | `#1F4A47` `#2D6A5E` `#3E8C79` `#7FB8A4` | `#0B1A19` |
| 🌙 Uykusuzluk | `sleep` | `#1B1F4B` `#2E2A6B` `#4A3F8C` `#7B6BB5` | `#07081A` |
| 🔥 Tükenmişlik | `burnout` | `#4A3520` `#7A5836` `#A8794A` `#D4A97A` | `#141009` |
| 🎯 Odaklanamama | `focus` | `#153A4A` `#1F5A6B` `#2E7D8C` `#6BAFBD` | `#08161C` |
| 💢 Öfke | `anger` | `#14403A` `#1E5C4E` `#2C7A64` `#6BAE96` | `#071815` |
| 🫥 Öz-eleştiri | `selfcrit` | `#432A3D` `#6B4159` `#95637D` `#C296AC` | `#160E14` |
| 👥 Sosyal kaygı | `social` | `#2A3352` `#414D75` `#5F6E9B` `#9BA6C7` | `#0D1020` |
| 📚 Sınav / performans | `exam` | `#1E3A4F` `#2C5570` `#3E7A96` `#7CAEC4` | `#0A1621` |
| 💔 Ayrılık / kayıp | `grief` | `#3B2A38` `#5E4152` `#8A6274` `#B894A0` | `#130D12` |
| ❓ Belirsiz | `unnamed` | `#28302E` `#3E4A46` `#5A6B64` `#8FA098` | `#0E1211` |

> **Öfke için not:** Kırmızı kullanmıyoruz. Öfke için karşıt renk (yeşil-teal) seçtik — bu bir estetik tercih değil, ürün kararı. Öfkeli kullanıcıya kırmızı göstermek durumu pekiştirir.

### 3.3 Kombinasyon mantığı

Kullanıcı **2 kategori** seçebiliyor (A2). Karışım kuralı:

```
birincil   = ilk seçim       → renk noktaları 1 ve 3
ikincil    = ikinci seçim    → renk noktaları 2 ve 4
arka plan  = iki arka planın daha koyusu
```

Böylece 55 olası kombinasyonun her biri farklı ama hiçbiri kontrolsüz görünmüyor. Örnek: `sleep + anxiety` → indigo ve teal'in iç içe geçtiği gece paleti.

**Geçiş:** Kullanıcı seçimi değiştirdiğinde renkler **1200 ms'de** yumuşak interpolasyonla değişir (ani değişim irkiltir).

### 3.4 Ruh hâli ekseni — sarı ↔ lacivert

B6'da seçilen kademe paleti **iki uç arasında bir eksende** kaydırır: en ağır uçta
lacivert, en sakin uçta sıcak sarı. Kullanıcı ekranın kendisine cevap verdiğini
görüyor. Eksen keyfi değil — mavi–sarı ruh hâli için en okunaklı görsel karşıtlık
ve ikisi de kırmızıdan uzak (karar #8'deki gerekçenin aynısı).

| Kademe | Ton | Karışım | Tavan | Parlaklık | Hız | Grain |
|---|---|---|---|---|---|---|
| Çok ağır | `#0A1648` lacivert | %88 | ×0.82 | ×0.72 | ×0.68 | +0.006 |
| Ağır | `#0A1648` | %52 | ×0.92 | ×0.86 | ×0.82 | +0.003 |
| Ortalarda | — | %0 | ×1.00 | ×1.00 | ×1.00 | — |
| İyi | `#F0C43A` sarı | %52 | ×1.12 | ×1.10 | ×1.10 | −0.002 |
| Sakin | `#F0C43A` | %88 | ×1.22 | ×1.18 | ×1.18 | −0.004 |

**Sarı neden tavanı açıyor:** koyu bir rengi sarıyla karıştırıp eski luminansa
kilitlemek onu kahveye çevirir — sarı, düşük parlaklıkta sarı olarak okunmaz.
Sakin uçta tavan bilinçli olarak açılır; ağır uçta düşer. Metin scrim'in üstünde
durduğu için en parlak noktanın biraz ışıması okunabilirliği bozmuyor.

**Yön neden böyle:** ağır kademede ekran kısılıyor ve yavaşlıyor. Kötü hissedene
ekranı parlatıp hızlandırmak "neşelen" demenin görsel karşılığı olurdu ve Ton eki
§3'te yasak; kısık ve yavaş ekran ise sakinleştirici — gece lambası mantığı.

**Değişmez kural — ton serbest, luminans değil.** Karışım koyu bir rengi sarıya
çekerken kaçınılmaz olarak açar; bu da metin kontrastını düşürür. O yüzden her
renk noktası karıştırıldıktan **sonra** hedef luminansa geri taşınıyor
(`RGB.withLuminance`, gamma açılmış uzayda) ve hedef, paletin mevcut en parlak
noktasını aşamıyor. Arka plan hiçbir kademede açılmıyor. Sonuç: renk istediği
kadar değişse de metnin okunabilirliği bugünkü en kötü hâlinden aşağı inemiyor.
55 palet × 5 kademe = 275 kombinasyon için sayısal olarak doğrulandı.

**Takas:** uçlarda kategori paleti neredeyse kayboluyor (karar #18). Geri alınacaksa
`MoodLevel.paletteModulation` içindeki uç `tintAmount` değerleri düşürülür, başka
hiçbir yer değişmez.

### 3.5 Zaman bazlı ayarlama

21:00 sonrası tüm paletlerin parlaklığı %15 düşer ve mavi kanal %8 kısılır (PRD-Ek 2.1 gece modu kararı).

Sıra önemli: **kategori → ruh hâli → gece.** Gece ayarı en sonda, çünkü mutlak bir
tavan koyuyor; ruh hâli tonlaması onun altında çalışıyor.

---

## 4. Nefes hareketi

Bu, PRD-Ek Bölüm 2.1'de "en değerli whimsy" dediğimiz öğe. Görsel süsleme değil, **fonksiyonel** — kullanıcı farkında olmadan nefesini animasyona uyduruyor.

```
Döngü: 10 saniye
  0.0 → 4.0 sn   Genişleme (nefes al)     easeInOutSine
  4.0 → 4.5 sn   Tutuş
  4.5 → 10.0 sn  Daralma (nefes ver)      easeInOutSine
```

**Koda giren değer:** `breathValue(at:) -> Double` ∈ [0, 1] — mesh merkez noktasını ve `colorEffect` parlaklığını besler.

**Etkilediği parametreler:**

| Parametre | Aralık | Not |
|---|---|---|
| Mesh merkez noktası (y) | ±0.04 | Çok hafif — fark edilmemeli, hissedilmeli |
| Genel parlaklık | ±%3 | `colorEffect` içinde |
| Merkez nokta sürüklenmesi | ±0.06 | Şekil yavaşça "soluk alıyor" |
| Grain yoğunluğu | Sabit | Grain nefes almaz, titrer |

**Ekran bazında genlik:**

| Ekran grubu | Genlik | Gerekçe |
|---|---|---|
| A1, A2, B, C | %60 | Arka plan, dikkat çekmemeli |
| D (ölçüm) | %35 | Odaklanma gerekiyor |
| F1 (üretim) | %80 | Bekleme anını yumuşatır |
| **G1 (oturum)** | **%100** | Kullanıcı gerçekten nefesini buna uyduruyor |
| Kriz ekranı | **%0** | Hareket yok (PRD-Ek 1) |

---

## 5. Okunabilirlik — metin güvenli bölgesi

Referans görsellerdeki en büyük risk bu: güzel gradyanın üstünde metin okunmuyor.

**Çözüm:** `colorEffect` shader'ının içine bir *güvenli bölge karartıcı* gömüyoruz. Metnin bulunduğu dikey banda doğru gradyan otomatik karartılıyor.

```swift
safeY        // metin bloğunun dikey merkezi (0..1)
safeStrength // karartma gücü (0.35–0.55)
```

> SwiftUI'ın `.background(.regularMaterial)` çözümünü **kullanmıyoruz** — material blur, gradyanın rengini yıkayıp ürünün görsel kimliğini siliyor. Shader içi scrim rengi korur, sadece parlaklığı düşürür.

**Kurallar:**
- Metin bloğunun arkasındaki bölge her zaman **en az 4.5:1 kontrast** (WCAG AA)
- Büyük başlıklar için 3:1 kabul edilebilir
- Karartma yumuşak geçişli (`smoothstep`), keskin bant görünmemeli
- Metin rengi her zaman `#F2EFE9` (kırık beyaz) — saf beyaz değil, göz yormaz

**Otomatik doğrulama:** XCTest içinde her palet × her ekran kombinasyonu için kontrast testi. `ImageRenderer` ile arka planı offscreen render edip güvenli bölgedeki ortalama luminansı ölçün, metin rengiyle kontrast oranını hesaplayın. Eşiğin altına düşen kombinasyon build'i kırar. 55 kombinasyonu elle kontrol etmek mümkün değil.

**Dynamic Type etkisi:** Metin büyüdükçe blok yükseklir ve `safeY` bandı yetmeyebilir. Metin bloğunun gerçek yüksekliğini `onGeometryChange` ile ölçüp `safeStrength`'i orantılı artırın.

---

## 5.1 Tipografi tavrı — bir kademe kalın

*Ürün sahibi kararı, 2026-09-08.*

Uygulamanın **genel tavrı sistem varsayılanından bir kademe kalındır.** Bu bir estetik tercih değil, gradyan üstünde metin göstermenin doğrudan sonucu: ince harf hem kontrast kaybediyor (§5'teki 4.5:1 eşiği ince punto ile zorlanıyor) hem karakter kaybediyor. Kalın harf, "Sakin · Dürüst · Yanında" sesinin görsel karşılığı — sakin olmak sessiz olmak değil, net konuşmaktır.

| Rol | Ağırlık | Kullanım |
|---|---|---|
| `display` | `.heavy` | İri başlıklar (`DisplayText`) |
| `title` | `.bold` | Ekran içi ara başlıklar, ölçüm soruları |
| `body` | `.medium` | Gövde metni — sistem varsayılanı `.regular`, bir kademe yukarıda |
| `action` | `.bold` | Buton ve dokunulabilir her şey |
| `emphasis` | `.semibold` | Seçili olmayan kart etiketi gibi ikincil vurgu |

Çizgiler de aynı kademede: ilerleme izi 3 → **5 pt**, seçili kart kenarlığı 1.5 → **2 pt**.

**Uygulama kuralı:** Bu değerler `Theme.Weight` ve `Theme.Line` altında **tek kaynakta** durur. Hiçbir yerde satır içi `.weight(.semibold)` yazılmaz — tavır geri alınacaksa tek dosya değişir. Yeni bir ekran yazarken ağırlık seçmiyorsunuz, rol seçiyorsunuz.

**Kalınlaşmanın yan etkisi:** Ağırlık arttığında harfler birbirine yaklaşır. `DisplayText`'in kerning'i −0.5'ten −0.3'e gevşetildi; aksi hâlde 38 pt'ta harfler yapışıyor.

> Kontrast testi (§5) bu kademeyle yeniden kalibre edilmeli: kalın harf ince harften daha okunur, yani bazı palet kombinasyonları eşiği artık geçebilir. Testi gevşetmek için gerekçe değil — sadece eşiğin kalın puntoyla ölçülmesi gerekiyor.

---

## 6. Uygulama kodu

### 6.1 Palet modeli

```swift
struct Palette: Equatable {
    let key: String
    let spots: [Color]        // 4 renk noktası
    let background: Color
    let speed: Double         // 0.18 – 0.40
    let grain: Float          // 0.030 – 0.045

    static let all: [String: Palette] = [ /* Bölüm 8.1'deki JSON'dan */ ]

    /// A2'de iki kategori seçildiyse harmanla
    static func blend(_ a: Palette, _ b: Palette?) -> Palette {
        guard let b else { return a }
        return Palette(
            key: "\(a.key)+\(b.key)",
            spots: [a.spots[0], b.spots[1], a.spots[2], b.spots[3]],
            background: a.background.luminance < b.background.luminance
                        ? a.background : b.background,
            speed: (a.speed + b.speed) / 2,
            grain: (a.grain + b.grain) / 2
        )
    }
}
```

### 6.2 Ana arka plan görünümü

```swift
struct BreathingMeshBackground: View {
    let palette: Palette
    var safeY: Float = 0.5             // metin bandının dikey merkezi
    var breathAmplitude: Double = 0.6  // ekran grubuna göre (Bölüm 4)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            palette.background.ignoresSafeArea()
        } else {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let t = reduceMotion ? 0
                          : timeline.date.timeIntervalSince1970 * palette.speed
                    let breath = breathValue(at: t)

                    MeshGradient(
                        width: 3, height: 3,
                        points: meshPoints(t: t, breath: breath),
                        colors: meshColors(),
                        background: palette.background,
                        smoothsColors: true,
                        colorSpace: .perceptual
                    )
                    .colorEffect(
                        ShaderLibrary.grainAndScrim(
                            .float2(geo.size),
                            .float(Float(t)),
                            .float(palette.grain),
                            .float(safeY),
                            .float(0.45)
                        )
                    )
                    .ignoresSafeArea()
                }
            }
            .drawingGroup()   // tek Metal geçişinde birleştir
        }
    }

    // MARK: - Nefes: 4 sn al · 0.5 sn tut · 5.5 sn ver
    private func breathValue(at t: TimeInterval) -> Double {
        guard !reduceMotion else { return 0.5 }
        let p = t.truncatingRemainder(dividingBy: 10.0)
        func ease(_ x: Double) -> Double { -(cos(.pi * x) - 1) / 2 }
        let raw: Double
        if p < 4.0        { raw = ease(p / 4.0) }
        else if p < 4.5   { raw = 1.0 }
        else              { raw = 1.0 - ease((p - 4.5) / 5.5) }
        return raw * breathAmplitude
    }

    // MARK: - Mesh noktaları
    // KRİTİK: dış sınır noktaları kenarlara SABİT kalır (Bölüm 6.5)
    private func meshPoints(t: TimeInterval, breath: Double) -> [SIMD2<Float>] {
        let b = Float(breath)
        let drift = Float(sin(t * 0.7)) * 0.06
        let drift2 = Float(cos(t * 0.5)) * 0.05
        return [
            [0.0, 0.0], [0.5 + drift * 0.3, 0.0], [1.0, 0.0],
            [0.0, 0.5], [0.5 + drift, 0.45 + drift2 + b * 0.04], [1.0, 0.5],
            [0.0, 1.0], [0.5 - drift * 0.4, 1.0], [1.0, 1.0]
        ]
    }

    private func meshColors() -> [Color] {
        let s = palette.spots
        let bg = palette.background
        return [bg, s[0], bg,
                s[1], s[2], s[3],
                bg, s[1], bg]
    }
}
```

### 6.3 Metal shader — grain + metin scrim'i

`Shaders.metal`:

```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 grainAndScrim(float2 pos, half4 color,
                                      float2 size, float time,
                                      float grain, float safeY,
                                      float safeStrength)
{
    // metin güvenli bölgesi — metnin olduğu banda doğru karart
    float y = pos.y / size.y;
    float safe = smoothstep(0.38, 0.0, abs(y - safeY));
    half3 c = color.rgb * half(1.0 - safe * safeStrength);

    // grain — referans görsellerdeki analog doku
    float n = fract(sin(dot(pos + fract(time) * 100.0,
                            float2(127.1, 311.7))) * 43758.5453);
    c += half((n - 0.5) * grain);

    return half4(c, color.a);
}
```

### 6.4 Palet geçişi (A2'nin yıldız özelliği)

Ayrı bir animasyon koduna gerek yok — MeshGradient kontrol noktaları değiştiğinde örtük animasyon yapıyor. Renkler için:

```swift
@State private var palette = Palette.all["unnamed"]!

func onSelectionChanged(_ picks: [String]) {
    let next = Palette.blend(
        Palette.all[picks[0]]!,
        picks.count > 1 ? Palette.all[picks[1]] : nil
    )
    withAnimation(.easeInOut(duration: 1.2)) {
        palette = next
    }
}
```

Bu kadar. 55 kombinasyonun tamamı bu üç satırla çalışıyor.

### 6.5 Üç kritik tuzak

Dokümanlarda net yazmayan ama üretimde başınızı ağrıtacak konular:

**1. Dış sınır noktaları sabitlenmeli.** Dış sınırdaki noktalar genellikle birim karenin kenarlarına sabit kalmalı (x veya y 0.0 ya da 1.0'a eşit). Bir kenar noktasını içeri çekerseniz gradyanın bittiği ve alttaki görünümün göründüğü belirgin bir kesim oluşuyor. Yani **yalnızca merkez noktayı** hareket ettirin — yukarıdaki `meshPoints` buna uyuyor.

**2. Renk uzayı.** Renkler gradyanın renk uzayında yorumlanıyor; saf renkler arasında çamurlu gri geçişler görüyorsanız `colorSpace: .perceptual` geçin. Ayrıca `smoothsColors: true` yama dikişlerini gizleyen kübik interpolasyonu kullanıyor — iOS 26'da varsayılan ama iOS 18'de opt-in olduğu için **açıkça yazın**.

**3. Koyu mod sabitlemesi.** Renk interpolasyonu her dinamik renk çözümlendikten sonra gerçekleşiyor, bu yüzden açık modda dengeli görünen bir gradyan koyu modda beklenmedik ara tonlar üretebiliyor. Bizde tüm paletler zaten koyu → uygulamayı `.preferredColorScheme(.dark)` ile sabitleyin ve `Color` yerine sabit RGB değerleri kullanın.

### 6.6 Performans ve fallback

| Durum | Davranış | Uygulama |
|---|---|---|
| Normal | 60 fps | `TimelineView(.animation)` |
| Arka plan ekranlar | 30 fps | `minimumInterval: 1/30` |
| Düşük güç modu | Hareket durur | `ProcessInfo.processInfo.isLowPowerModeEnabled` |
| Reduce Motion | Statik gradyan + grain | `accessibilityReduceMotion` |
| Reduce Transparency | Düz koyu renk | `accessibilityReduceTransparency` |
| Ekran arka planda | Render durur | `scenePhase != .active` |
| Termal baskı | Kademeli yavaşlama | `ProcessInfo.thermalState` |

**Bütçe:** Arka plan kare başına **2 ms**'yi geçmemeli. Instruments'ta Metal System Trace ile ölçün. Aşarsa mesh 3×3'ten 2×2'ye düşürülür.

> **iOS 18 altı fallback gerekmiyor** — minimum hedef zaten iOS 18. Yine de `if #available` sarmalayıcısı ve `LinearGradient` yedeği koymak ucuz sigorta.

## 7. Ekran ekran görsel spesifikasyon

| Ekran | Palet | `safeY` | Nefes | Ek görsel |
|---|---|---|---|---|
| **A1** | `unnamed` (nötr) | 0.50 | %60 | **Rive:** yol çizimi + adım dolumu + bar animasyonu, 4 sn döngü |
| **A2** | Seçime göre **canlı değişir** | 0.18 (başlık üstte) | %60 | Yok — gradyan yıldız |
| **B1** | A2 paleti | 0.22 | %50 | Metin alanı odaklanınca gradyan %10 sakinleşir |
| **B2–B4** | A2 paleti | 0.25 | %50 | — |
| **B5** | A2 paleti | 0.25 | %50 | — |
| **B6** | A2 paleti | 0.40 | %60 | Hava ikonu ölçeği; palet seçilen kademeye göre **anında** sarı↔lacivert ekseninde kayar (§3.4) |
| **C1** | Ruh hâli tonunda A2 paleti | 0.30 | %40 | Durum + süre aynalamasından sonra karmaşadan düzene geçen lif + `illustration-c1-mirror` |
| **C2** | A2 paleti | 0.30 | %40 | İki cümle arasında ortak akışa katılan lif + `illustration-c2-common` |
| **C3** | A2 paleti | 0.30 | %30 | ✗/✓ listesi sırayla + **`PathComparisonChart`** (§12) |
| **C4** | A2 paleti | 0.30 | %40 | **`ExpectationCurveChart`**: diğer uygulamalar → Patika, 8. günden sonra ivmelenme |
| **D0** | A2 paleti, koyu | 0.40 | %35 | — |
| **D1–D8** | A2 paleti, **en koyu varyant** | 0.20 | %35 | İlerleme çubuğu; gradyan neredeyse sabit |
| **E1–E3** | A2 paleti | 0.28 | %50 | — |
| **F1** | A2 paleti | 0.50 | %80 | Kontrol listesi satırları sırayla doluyor |
| **F2** ⭐ | A2 paleti, **en canlı varyant** | 0.15 | %70 | Faz kartları alttan yukarı sırayla giriyor (stagger 120 ms) |
| **F3** | A2 paleti | 0.12 | %60 | **Rive:** yol haritası, kilitli adımlar %35 opaklık |
| **F4** | Nötr, koyu | 0.35 | %40 | Fiyat ekranı — sakin, güven veren |
| **G1** | A2 paleti | 0.85 (metin altta) | **%100** | **Nefes küresi** — aynı shader, tek merkezi nokta |
| **G2** | A2 paleti | 0.45 | %60 | Adım halkası dolar (Rive) |
| **H1** | Nötr | 0.30 | %50 | — |
| **H2** | Nötr | 0.30 | %40 | Sahte bildirim kartı (statik) |

---

## 8. PROMPT SETİ

> **Nasıl kullanılır:** Bölüm 8.1'deki shader parametreleri doğrudan koda girer — "prompt" değil, konfigürasyon. Bölüm 8.2'deki görsel prompt'ları mood board, App Store ekran görüntüsü arka planı ve tasarım referansı üretmek için. Bölüm 8.3'teki video prompt'ları **sadece pazarlama** için.

### 8.1 Shader parametre preset'leri (uygulama içi — asıl "prompt" bunlar)

```json
{
  "anxiety": {
    "colors": ["#1F4A47", "#2D6A5E", "#3E8C79", "#7FB8A4"],
    "colorBack": "#0B1A19",
    "softness": 0.72, "intensity": 0.38, "noise": 0.035,
    "speed": 0.35, "warp": 0.50
  },
  "sleep": {
    "colors": ["#1B1F4B", "#2E2A6B", "#4A3F8C", "#7B6BB5"],
    "colorBack": "#07081A",
    "softness": 0.85, "intensity": 0.30, "noise": 0.030,
    "speed": 0.22, "warp": 0.58
  },
  "burnout": {
    "colors": ["#4A3520", "#7A5836", "#A8794A", "#D4A97A"],
    "colorBack": "#141009",
    "softness": 0.68, "intensity": 0.42, "noise": 0.045,
    "speed": 0.30, "warp": 0.46
  },
  "focus": {
    "colors": ["#153A4A", "#1F5A6B", "#2E7D8C", "#6BAFBD"],
    "colorBack": "#08161C",
    "softness": 0.60, "intensity": 0.45, "noise": 0.032,
    "speed": 0.40, "warp": 0.42
  },
  "anger": {
    "colors": ["#14403A", "#1E5C4E", "#2C7A64", "#6BAE96"],
    "colorBack": "#071815",
    "softness": 0.80, "intensity": 0.34, "noise": 0.038,
    "speed": 0.25, "warp": 0.54
  },
  "selfcrit": {
    "colors": ["#432A3D", "#6B4159", "#95637D", "#C296AC"],
    "colorBack": "#160E14",
    "softness": 0.78, "intensity": 0.36, "noise": 0.040,
    "speed": 0.28, "warp": 0.52
  },
  "social": {
    "colors": ["#2A3352", "#414D75", "#5F6E9B", "#9BA6C7"],
    "colorBack": "#0D1020",
    "softness": 0.74, "intensity": 0.36, "noise": 0.034,
    "speed": 0.30, "warp": 0.48
  },
  "exam": {
    "colors": ["#1E3A4F", "#2C5570", "#3E7A96", "#7CAEC4"],
    "colorBack": "#0A1621",
    "softness": 0.66, "intensity": 0.42, "noise": 0.036,
    "speed": 0.36, "warp": 0.45
  },
  "grief": {
    "colors": ["#3B2A38", "#5E4152", "#8A6274", "#B894A0"],
    "colorBack": "#130D12",
    "softness": 0.88, "intensity": 0.28, "noise": 0.042,
    "speed": 0.18, "warp": 0.60
  },
  "unnamed": {
    "colors": ["#28302E", "#3E4A46", "#5A6B64", "#8FA098"],
    "colorBack": "#0E1211",
    "softness": 0.75, "intensity": 0.32, "noise": 0.038,
    "speed": 0.26, "warp": 0.50
  }
}
```

### 8.2 Görsel üretim prompt'ları

**Kullanım alanı:** Mood board, tasarım referansı, App Store ekran görüntüsü arka planı, landing page statik görselleri. **Uygulama içine gömülmez.**

**Model önerisi:** Midjourney veya Flux (grain kontrolü daha iyi). Nano Banana / Seedream de çalışır.

**Ortak sonek (her prompt'a ekle):**
```
grainy film noise texture, heavy gaussian blur, soft organic blob shapes,
no text, no logo, no objects, no people, abstract only, vertical 9:16,
dark base with luminous soft light pools, analog risograph grain,
low saturation, calm, matte finish
```

---

**A1 — Karşılama (nötr)**
```
Abstract grainy gradient background, deep charcoal green base fading into
soft sage and muted moss light pools, one gentle diagonal light path
crossing the frame from lower left to upper right, heavy blur,
film grain, meditative and quiet, vertical 9:16
```

**A2/B — Kaygı (`anxiety`)**
```
Abstract grainy gradient, deep petrol teal base with soft emerald and
pale seafoam light blooms in upper third, dark vignette at top for text,
heavy gaussian blur, organic cloud-like blobs, analog grain, calming,
vertical 9:16
```

**A2/B — Uykusuzluk (`sleep`)**
```
Abstract grainy gradient, near-black indigo base with deep violet and
soft periwinkle light pools drifting toward lower half, night atmosphere,
very heavy blur, fine film grain, deep and quiet, vertical 9:16
```

**A2/B — Tükenmişlik (`burnout`)**
```
Abstract grainy gradient, dark umber base with muted amber and warm sand
light blooms, restorative not fiery, low saturation warm tones,
heavy blur, coarse analog grain, vertical 9:16
```

**A2/B — Öfke (`anger`)**
```
Abstract grainy gradient, deep forest teal base with soft jade and pale
mint light pools, cooling and grounding, no red no orange anywhere,
heavy gaussian blur, film grain, vertical 9:16
```

**A2/B — Öz-eleştiri (`selfcrit`)**
```
Abstract grainy gradient, deep plum base with dusty mauve and soft rose
light blooms, tender and warm, muted desaturated palette, heavy blur,
soft analog grain, vertical 9:16
```

**A2/B — Ayrılık / kayıp (`grief`)**
```
Abstract grainy gradient, very dark aubergine base with dusty rose and
faded mauve light pools, extremely soft and slow, maximum blur,
heavy grain, melancholic but not heavy, vertical 9:16
```

**A2/B — Sınav / performans (`exam`)**
```
Abstract grainy gradient, deep slate blue base with steel blue and pale
sky light blooms, clear and focused, moderate blur, fine grain,
vertical 9:16
```

**C1 — Aynalama ekranı (koyu, metin ağırlıklı)**
```
Abstract grainy gradient, very dark base occupying center band for text
legibility, soft muted light blooms confined to top and bottom corners
only, strong center darkening, heavy blur, film grain, vertical 9:16
```

**F2 — Plan ekranı (en canlı varyant)**
```
Abstract grainy gradient, rich layered light pools with more luminance
than surrounding screens, sense of arrival and clarity, dark upper band
for headline, soft blur with visible depth, analog grain, vertical 9:16
```

**G1 — Oturum ekranı (nefes)**
```
Abstract grainy gradient, single soft luminous orb centered slightly
above middle, radiating gently into dark surroundings, extremely
minimal, maximum blur, fine grain, dark base, meditative, vertical 9:16
```

**F4 — Fiyat ekranı (nötr, güven)**
```
Abstract grainy gradient, neutral deep slate base with very subtle warm
grey light pools at edges, restrained and trustworthy, minimal color,
heavy blur, fine grain, vertical 9:16
```

### 8.3 Video prompt'ları (yalnızca pazarlama)

<cite index="13-1">H3 metin-videodan görüntü-videoya, çoklu-çekim anlatıya ve talimat tabanlı düzenlemeye kadar destekliyor ve 5–15 saniye arası klipler üretiyor.</cite> <cite index="12-1">Omni-reference girdi olarak 9 görsel, 3 video ve 3 ses klibini tek üretimde kabul ediyor.</cite>

**Yöntem önerisi:** Önce 8.2'deki prompt'larla statik kare üret, sonra **image-to-video** ile hareketlendir. Saf text-to-video'da renk kontrolü kaybediyorsunuz.

---

**V1 — App Store önizleme, açılış (image-to-video)**

*Girdi görsel:* A1 prompt çıktısı
```
Extremely slow organic drift of soft light pools across the frame,
gentle breathing expansion and contraction on a 10 second cycle,
grain texture stays static while color shifts, no camera movement,
no cuts, seamless and hypnotic, 10 seconds
```
Negatif: `fast motion, camera pan, zoom, flicker, sharp edges, text, people`

---

**V2 — Reklam kreatifi, palet geçişi (image-to-video, first & last frame)**

<cite index="6-1">H3'ün image-to-video modu ilk ve son kare kontrolü sunuyor</cite> — bu, palet geçişini göstermek için ideal.

*İlk kare:* `unnamed` paleti · *Son kare:* `sleep` paleti
```
Smooth continuous morph from muted grey-green gradient into deep indigo
night gradient, light pools slowly migrating and shifting hue,
grain texture constant throughout, no hard transition, 8 seconds
```

---

**V3 — Nefes küresi, oturum ekranı (image-to-video)**

*Girdi görsel:* G1 prompt çıktısı
```
Single luminous orb expanding slowly over 4 seconds then contracting
over 6 seconds, one complete cycle, surrounding darkness stays still,
soft glow pulsing gently, film grain constant, seamless loop, 10 seconds
```

---

**V4 — Landing page hero (text-to-video)**
```
Abstract grainy gradient in deep teal and sage, soft light pools drifting
in slow organic motion, heavy gaussian blur, analog film grain overlay,
meditative atmosphere, no objects no people no text, seamless loop,
horizontal 21:9, 12 seconds
```

---

**Video maliyet notu:** <cite index="7-1">Open Platform API'de 2K video saniye başına 0,13 dolar.</cite> Dört kreatif × 10 sn ≈ 5,20 dolar. Varyasyonlarla birlikte 50–100 dolarlık bir bütçe pazarlama kreatifleri için yeterli.

### 8.4 Rive animasyon brief'leri

Bunlar prompt değil, tasarımcı brief'i.

**R1 — A1 yol animasyonu**
```
Süre: 4 sn döngü · Boyut hedefi: < 20 KB
0.0–1.2 sn  İnce bir yol çizgisi alttan yukarı çiziliyor (path trim)
1.2–2.4 sn  Yol üzerinde 5 nokta sırayla doluyor (stagger 200ms)
2.4–3.2 sn  Sağda iki dikey bar beliriyor
3.2–4.0 sn  İkinci bar kısalıyor, ilki sabit — "fark" metaforu
4.0 sn      Fade, başa dön
Renk: tek renk (#F2EFE9), opaklık varyasyonu ile derinlik
```

**R2 — Adım halkası (G2, günlük oturum sonu)**
```
State machine: idle → filling → complete
filling: halka 0→360°, 400 ms, easeOutCubic
complete: 200 ms hafif parlama, sonra idle'da kalır
Konfeti YOK, parçacık YOK (PRD-Ek Bölüm 3.6)
```

**R3 — Rozet (path sonu)**
```
State machine: hidden → reveal → resting
reveal: 600 ms scale 0.8→1.0 + opacity 0→1 + tek yumuşak parlama
resting: çok hafif nefes (scale ±1%), 6 sn döngü
Rozetin ortasında path'in öncesi/sonrası yüzdesi için metin slotu
```

---

## 9. Uygulama sırası

| # | İş | Efor | Bağımlılık |
|---|---|---|---|
| 1 | `BreathingMeshBackground` — tek palette çalışan MeshGradient | S | — |
| 2 | `grainAndScrim` Metal shader + `colorEffect` bağlama | S | 1 |
| 3 | 10 paleti `Palette.all` içine al, `blend()` yaz | S | 1 |
| 4 | `breathValue(at:)` + ekran bazlı genlik | S | 1 |
| 5 | A2 canlı palet geçişi (`withAnimation` 1.2 sn) | S | 3 |
| 6 | Metin güvenli bölge + XCTest kontrast doğrulaması | M | 2 |
| 7 | Reduce Motion / Transparency / düşük güç davranışları | S | 1 |
| 8 | Termal ve fps bütçesi ölçümü (Instruments) | S | 1–7 |
| 9 | A1 yol animasyonu (Rive veya SwiftUI Path) | M | — |
| 10 | Adım halkası + rozet (Rive) | M | — |
| 11 | Pazarlama videoları (H3) | S | 8.2 görselleri |

**Kritik yol:** 1 → 2 → 5. Bu üçü bittiğinde A2'nin "seçime göre renk değiştiren gradyan" özelliği çalışır — akışın en gösterişli anı.

---

## 10. Karar günlüğü

| # | Karar | Alternatif | Gerekçe |
|---|---|---|---|
| 1 | Uygulama içi görseller kod ile | H3 / Kling video | 55 kombinasyon, dinamik renk, ~60 KB vs ~200 MB |
| 2 | **SwiftUI MeshGradient (sistem API)** | RN Skia / Paper Shaders | Sıfır bağımlılık, Metal ile GPU, örtük animasyon |
| 3 | Grain + scrim tek `colorEffect` shader'ında | Ayrı overlay katmanı | Tek geçiş, ekstra kompozisyon maliyeti yok |
| 4 | Minimum iOS 18 | iOS 17 desteği | MeshGradient iOS 18+; pazarın ~%95'i üstünde |
| 5 | `.preferredColorScheme(.dark)` sabit | Açık/koyu mod | Renk interpolasyonu açık modda öngörülemeyen ara tonlar üretiyor |
| 6 | Yalnızca merkez mesh noktası hareket eder | Tüm noktalar | Kenar noktası içeri çekilince görünür kesim oluşuyor |
| 7 | `smoothsColors: true` + `.perceptual` açıkça yazılır | Varsayılanlara güvenmek | iOS 18'de opt-in, iOS 26'da varsayılan — sürüm farkı |
| 8 | Öfke paleti yeşil-teal | Kırmızı | Öfkeli kullanıcıya kırmızı göstermek durumu pekiştirir |
| 9 | Doygunluk/parlaklık sabit bantta | Referans görsellerdeki canlı turuncu | Yüksek doygunluk sıcak tonlar kaygılı kitlede uyarıcı |
| 10 | Nefes 4 sn al / 6 sn ver | Simetrik 5/5 | Uzun nefes verme parasempatik sistemi aktive eder |
| 11 | CI'da otomatik kontrast testi | Elle kontrol | 55 kombinasyon elle denetlenemez |
| 12 | Rive opsiyonel, SwiftUI Path alternatifi var | Rive zorunlu | Tasarımcı yoksa 80 satır Swift yeterli |
| 13 | Video yalnızca pazarlamada | Hiç kullanmamak | App Store önizleme ve reklamda video hâlâ en etkili format |
| 14 | **Tipografi bir kademe kalın** (§5.1) | Sistem varsayılanı | Gradyan üstünde ince harf kontrast ve karakter kaybediyor; ağırlık `Theme.Weight` altında tek kaynakta |
| 15 | **İlerleme izinin ucunda düğüm yok** | Ucunda hareket eden nokta | Düğüm gözün takip ettiği bir nesne yaratıyordu — izin kendisi yerine noktanın konumu okunuyordu |
| 16 | **Onboarding üst çubuğu kalıcı** | Her ekranın kendi çubuğunu çizmesi | Çubuk her adımda sökülüp takıldığında geri butonu gidip geliyor ve iz sıfırdan doluyor; akış tek yol değil 31 ayrı ekran gibi görünüyordu |
| 17 | **Adım geçişi sıralı fade** (çık → gir) | Eşzamanlı cross-fade | İki farklı yükseklikteki içerik üst üste binip kirli görünüyordu |

| 18 | **Ruh hâli paleti sarı↔lacivert ekseninde kaydırır**, kategori kimliği uçlarda geri çekilir | Yalnızca parlaklık/hız değişimi | Ürün sahibi rengin ruh hâlini söylemesini istedi; kategori kimliği A2'de kuruluyor ve C boyunca ruh hâli tonunda devam ediyor |
| 19 | **Ton karışımından sonra luminans geri yükleniyor**; sakin uçta tavan açılıyor | Karışımı olduğu gibi bırakmak / tavanı her kademede kilitlemek | Sarıya çekmek rengi açıyor; tavanı hiç açmamak ise sarıyı kahveye çeviriyordu. Ağır uçta tavan düşer, sakin uçta açılır |
| 20 | **C bölümünde cümleler 1 sn başlangıç aralığıyla tek tek beliriyor** (başlık dahil) | Hepsi birlikte / çok hızlı sıra | Aynı anda basılan 3–4 cümle "duvar" gibi görünüyor; bir saniyelik ritim her cümleye kısa bir okuma payı bırakıyor |
| 21 | **C3 grafiğinde eksen sayısı yok + "sonuç vaadi değil" notu** | Sayılı, ölçekli grafik | Sayılı bir eğri C2'de sayı uydurmama kuralını (Onboarding eki §4.2) bir ekran sonra delerdi; grafik yapıyı anlatıyor, sonucu değil |
| 22 | **Grafik iki fazda çiziliyor** (kütüphane → yol) ve kaydırma görünürlüğüyle tetikleniyor | İkisi birlikte / ekran açılışında zamanlayıcı | Birlikte çizilince "iki çizgi" okunuyor; sırayla çizilince karşılaştırma kendiliğinden anlatılıyor. Yazio onboarding'indeki ritim ([ekran](https://mobbin.com/screens/dbecd219-25ce-4522-b287-92e36d659a4a)) |
| 23 | **Görsel yuvası varlık yokken hiç yer kaplamıyor** | Yer tutucu görsel | Görseller sonradan tek tek eklenecek; yer tutucu, eksik görselli her ekranı bozuk gösterirdi |
| 24 | **C1/C2 raster görselleri 282/292 pt sahnede gösterilir** | Küçük ve metinden kopuk görsel | Büyük sahne görseli dekor olmaktan çıkarır; erişilebilir Dynamic Type'ta 194 pt'ye iner ve metin önceliğini korur |
| 25 | **C1 görseli durum + süre aynalamasından sonra gelir** | İlk cümleden hemen sonra göstermek | Kullanıcı önce kendi durumunu ve ne kadar sürdüğünü birlikte okur; görsel bu iki parçayı bağlar, kalan kişisel cümleler ardından gelir |
| 26 | **C4 raster yerine iki fazlı native süreç grafiği kullanır** | Soyut ufuk illüstrasyonu | Önce dalgalanıp aşağıda biten diğer uygulamalar, sonra 8. güne kadar sakin ve ardından ivmelenen Patika doğrudan okunur. Sayısal Y ekseni yoktur; grafik sonuç vaadi değildir |
| 27 | **F2 ve onboarding sonrası Yolum ortak kıvrımlı `JourneyMapRow` kullanır** | Düz liste / raster harita | Gerçek kişisel adımlar aynı rotada görünür; sıradaki adım belirgin, gelecek başlıklar kilitli ama okunabilir kalır. Native Shape çizimi raster varlık istemez ve 60 Hz hareket bütçesini korur |
| 28 | **Kişisel İz faz ritmi deterministik, tamamlanma geri bildirimi sunucu kaynaklıdır** | Rastgele kıvrım / süre dolunca yerel kutlama | Faz eşikleri gerçek `PathPlan` günlerinden türetilir; aynı path her açılışta aynı izi verir. Düğüm ancak yenilenen kayıtta `completed_at` görüldüğünde onaya dönüşür; böylece harita hem kişisel hem dürüst kalır |
| 29 | **Onboarding sonrası Yolum tek parça rota ve faza bağlı heykelsi boşluk görselleri kullanır** | Kesikli gelecek rota / her fazda çizgi aralığı / rastgele stok görsel | Günlük ekranda yolun devamlılığı önceliklidir: gelecek iz soluk ama düzdür, faz etiketi kenara alınır. Üç kırık beyaz şerit görseli yalnızca gerçek `PathPhase` üzerinden seçilir; kişiselleştirme korunurken hassas metin görselleştirilmez |

---

## 11. C BÖLÜMÜ GÖRSELLERİ — PROMPT SETİ

> **Nasıl kullanılır:** Her prompt ChatGPT'nin görsel üretimine (GPT Image / DALL·E)
> olduğu gibi yapıştırılır. Üretilen dosya `assets/illustrations/` altına kaydedilir,
> sonra Xcode'da `Assets.xcassets → Onboarding` altındaki hazır yuvaya sürüklenir.
> Yuvalar açık, kod tarafı hazır. Kurulum adımları:
> [`assets/illustrations/README.md`](../assets/illustrations/README.md).

### 11.1 Ortak kurallar — hepsinde geçerli

Bu görseller **kendi arka planını getirmeyecek** ve **kendi rengini getirmeyecek.**
Gerekçe: arka plan gradyanı kullanıcının kategorisine (10 palet) ve ruh hâline
(5 kademe) göre değişiyor. Sabit renkli bir görsel bu 275 kombinasyonun bir
kısmıyla mutlaka çakışır. O yüzden tek mürekkep: kırık beyaz ve grileri.

**Görsel dil — Bevel, Yazio değil.** İki referans Mobbin'den bakıldı:

- [Bevel onboarding](https://mobbin.com/flows/0b6f9210-c215-4b32-872d-3fb66ab3ed28):
  başlığın yanında tek, yarı saydam, neredeyse tek renkli obje. Sahne yok, karakter
  yok, 3D yiyecek yok. [Seçim kartı](https://mobbin.com/screens/5ce63083-4a42-46fa-ace9-4ca3aa6f13d5),
  [odak kartı](https://mobbin.com/screens/a5169edf-768f-440f-a785-d257651e4d6b).
  **Bizim dilimiz bu.** Görsel başlığın *altında* duruyor, çünkü bu ekranlarda
  okunmasını istediğimiz şey metin; görsel kapanış nefesi.
- [Yazio onboarding](https://mobbin.com/flows/003557b1-194e-477c-b307-5e051fa87371):
  karşılaştırma grafiği ve "Continue" ritmi referansımız
  ([grafik ekranı](https://mobbin.com/screens/dbecd219-25ce-4522-b287-92e36d659a4a),
  [projeksiyon](https://mobbin.com/screens/9bb99bb2-df6d-43c1-85c8-36f90c93c51c)).
  Mascot, yiyecek ikonları, kırmızı/yeşil karşıtlığı **alınmıyor** — ruh sağlığı
  ürününde gülümseyen bir figür "senin gibi olmayan biri" mesafesi kurar (Ton eki §3).

| Kural | Değer |
|---|---|
| Arka plan | **Şeffaf PNG.** Prompt'ta açıkça isteniyor; çıktıda hala zemin varsa Photoshop/Preview'da sil |
| Renk | Yalnızca kırık beyaz `#F2EFE9` ve soğuk grileri. Renkli aksan, sarı, lacivert, teal **yok** — palet zaten arka planda |
| Malzeme | Buzlu cam / frosted glass, mat, yumuşak iç gölge. Parlak plastik, neon, metalik yok |
| Çizgi | Kalın, yumuşak uçlu. Uygulamanın tipografi tavrıyla aynı: bir kademe kalın (§5.1) |
| Kompozisyon | **Tek bütünlüklü metafor.** Birden fazla parça varsa aynı akışın parçası olmalı; sahne, zemin, çerçeve ve drop shadow yok |
| İçerik | İnsan yüzü yok, insan figürü yok, metin yok, ikon yok, logo yok, watermark yok |
| Boyut | 1024×1024 üret, sonra içeriğin etrafındaki boşluğu kırp |
| Ton | Sakin, durgun. Neşeli, enerjik, "motivasyonel", kutlama yok |

**ChatGPT'de nasıl üret:** GPT Image (ChatGPT'nin görsel üretimi). Her prompt'u
**ayrı bir sohbette**, olduğu gibi yapıştır. Model bazen şeffaf arka planı yok
sayıp koyu bir kare basıyor — o zaman aynı prompt'un sonuna şunu ekle:

> The background MUST be a checkerboard-transparent PNG. If you cannot do true
> transparency, use a flat #111111 background I can key out. Do not invent a scene.

**İnsan figürü neden yok:** Ton eki §3'ün aynı gerekçesi. Kullanıcı kendini kötü
hissediyor; ona gülümseyen bir figür göstermek "senin gibi olmayan biri" mesajı
veriyor. Soyut form kimseyi temsil etmediği için kimseyi dışlamıyor.

### 11.2 C1 — Anlaşılma (`illustration-c1-mirror`)

**Ekranın işi:** Kullanıcının anlattığını ona geri söylemek. "Seni duydum."
**Görselin işi:** Dağınık anlatının değiştirilmeden alınıp anlaşılır bir yapıya
dönüştüğünü göstermek. Literal ayna kullanılmaz; kullanıcı aynayı değil, kendisinin
anlaşılmasını okumalı.

```
A single loose, gently tangled continuous thread enters from the lower
left, passes through a soft translucent open loop at the center, and leaves
as three calm, parallel flowing strands toward the upper right. The same
thread must remain visibly continuous before and after the loop: confusion
is being heard and organized, not erased or magically solved.

Style: premium editorial onboarding illustration. Thick rounded forms,
matte paper-fiber texture with frosted-glass edges, quiet tactile depth.
Monochrome only — off-white (#F2EFE9) and cool translucent grays.

Background: genuinely transparent PNG with alpha channel. No scene, floor,
frame, border, vignette or gradient background.

Composition: balanced asymmetrical diagonal; subject fills roughly 78% of
the square canvas with minimal dead space and remains legible at 240pt tall.

Do not include: literal mirror, reflection, pebble, abstract blob, audio
waveform, text, letters, numbers, people, faces, hands, eyes, speech bubble,
recognizable icon, logo, watermark, sparkles, rays or stars.
```

### 11.3 C2 — Yalnız değilsin (`illustration-c2-common`)

**Ekranın işi:** Yaygınlık. Sayı vermeden "bu çok görülen bir şey" demek.
**Görselin işi:** Tek bir deneyimin daha geniş bir ortak akışın doğal parçası
olduğunu göstermek. Çokluk var ama kalabalık, kıyas veya sayılabilir grup yok.

> **Dikkat:** Burada sayı sayılabilecek bir görsel olmamalı. Kullanıcı formları
> sayıp "demek 12 kişi" diye okumasın — C2'nin tüm kuralı sayı vermemek
> (Onboarding eki §4.2). Bu yüzden formlar bilerek belirsiz sayıda ve kısmen
> soluk.

```
One soft narrow strand enters from the lower foreground and gently joins a
broad woven flow made from many overlapping translucent strands. At the
joining point the single strand remains visible but is naturally held by
the larger weave — neither isolated nor swallowed. The field fades at both
edges so its strands cannot be counted.

Style: premium editorial onboarding illustration matching C1. Thick
rounded ribbons, matte paper-fiber texture with frosted translucent
overlaps, quiet tactile depth. Monochrome only — off-white (#F2EFE9) and
cool translucent grays.

Background: genuinely transparent PNG with alpha channel. No scene, floor,
frame, border, vignette or gradient background.

Composition: a wide gentle horizontal arc; the joining strand begins near
the lower center. Subject fills roughly 76% of the square canvas and remains
clear at 230pt tall.

Do not include: audio waveform, equalizer, tally marks, fence, barcode,
countable objects, crowd, people, faces, hands, text, letters, numbers,
recognizable icon, logo, watermark, heart, sparkles or rays.
```

### 11.4 C4 — Dürüst beklenti (native süreç grafiği)

C4 için raster görsel üretilmez. `ExpectationCurveChart` ekranın mevcut kırık
beyaz mürekkebini doğrudan kullanır ve iki çizgiyi görünürlük tetiklendiğinde
sırayla çizer:

- `Diğer uygulamalar`: kesik, düşük opaklıkta, birkaç kez yumuşakça yükselip
  alçalır ve başladığı seviyeden aşağıda biter.
- `Patika`: düz, daha kalın ve parlak; ilk 8 gün küçük adımlarla ilerler,
  ardından giderek hızlanan bir eğriyle yükselir.
- İki çizgi de `easeInOut` kullanır; önce diğer uygulamalar tamamlanır, kısa bir
  nefesin ardından Patika başlar. Döngü ve sürekli hareket yoktur.
- Y ekseni, yüzde veya sonuç sayısı yoktur. `Başlangıç`, `7–8. gün` ve `21. gün`
  yalnızca süreç zamanını işaretler. “Sonuç vaadi değil” notu kaldırılmaz.
- Reduce Motion açıkken grafik tamamlanmış hâliyle gösterilir. VoiceOver iki
  çizginin şeklini ve grafiğin sonuç vaadi olmadığını tek bir anlamlı öğe olarak okur.

### 11.5 F2 — Yolun hazır (`illustration-f2-path-ready`)

**Ekranın işi:** Beş dakikalık soru-cevabın karşılığını ilk kez göstermek. Kart,
harita ve "Yola çık" butonu bu ekranda; görsel onların üstünde duruyor.

**Görselin işi:** Dağınık bir girdinin **kurulmuş, sırası belli bir yola**
dönüştüğünü göstermek. C1'in görseliyle aynı iplik dilini konuşur ama orada iplik
daha yeni anlaşılıyordu; burada yol kurulmuş ve önde uzanıyor.

**Dikkat:** Bu ekranda görselin altında uzun bir liste var. Görsel **yatay ve
sakin** olmalı — dikey, yükselen, "zafer" hissi veren bir kompozisyon, listeye
inmeden önce ekranı kapatır. Ayrıca yükselen bir eğri sonuç vaadi gibi okunur;
C3'te eğriyi tam bu yüzden kaldırdık (§12).

```
A single continuous ribbon-like path lying calmly across the frame from
lower left to upper right, gently undulating, resolved and settled — not
climbing, not triumphant. Along the ribbon, a few evenly spaced soft
translucent rings rest on its surface like markers on a trail. The ribbon
is clearly one unbroken form: it has a beginning and an end, and the end
is visible within the frame.

Style: premium editorial onboarding illustration. Thick rounded forms,
matte paper-fiber texture with frosted-glass edges, quiet tactile depth.
Monochrome only — off-white (#F2EFE9) and cool translucent grays.

Composition: horizontal, wide, calm. Generous empty space above and below
the ribbon. No upward-climbing chart shape, no arrow, no summit, no
celebration.

Background: genuinely transparent PNG with alpha channel. No scene, floor,
horizon, frame, shadow or ground plane. No text, no numbers, no icons, no
human figures, no logos, no watermark.
```

Model şeffaf arka planı yok sayarsa §11.1'deki ek cümleyi prompt'un sonuna ekle.

**Yerleşim:** Başlığın altında, path kartının üstünde; 208 pt yüksekliğinde,
üstünde 20 pt altında 22 pt boşlukla. Varlık eklenmezse `OnboardingIllustration`
hiç yer kaplamaz ve kart doğrudan başlığın altına gelir — ekran görselsiz de
eksiksiz çalışır.

### 11.6 C3, C4 ve F1'de raster görsel yok

C3 iki sütunlu bir karşılaştırma (§12), C4 kodla çizilen bir grafik (§13), F1 ise
kodla çizilen bir iz (§14). Üçünde de raster görsel yok: bir yandan animasyonlu
bir şey çizilirken bir yandan sabit bir illüstrasyon durması iki ayrı görsel odak
yaratır ve çizim kaçırılır. Eski `illustration-c4-horizon` varlığı kullanımdan
kaldırılmıştır.

### 11.7 Üretim sonrası kontrol listesi

- [ ] Arka plan gerçekten şeffaf mı? (PNG'yi koyu **ve** açık bir zeminde aç)
- [ ] Görselde renk kalmış mı? (Renkli tek piksel bile 275 palet kombinasyonunun bir kısmıyla çakışır)
- [ ] İçinde harf, rakam, ikon, insan silueti var mı?
- [ ] C2 görselindeki lifler sayılabiliyor mu? (Sayılabiliyorsa yeniden üret)
- [ ] F2 görseli yatay mı, yükselen bir eğri gibi mi duruyor? (Yükseliyorsa yeniden üret — sonuç vaadi gibi okunur)
- [ ] Uygulamada üç ruh hâli kademesinde denendi mi? (Çok ağır / Ortalarda / Sakin)

---

## 12. C3 KARŞILAŞTIRMA — GRAFİK DEĞİL, İKİ SÜTUN

> **Bu bölüm 2026-09-08'de yeniden yazıldı.** Önceki hâli `PathComparisonChart`
> adlı animasyonlu bir eğri karşılaştırmasını tarif ediyordu; o bileşen silindi.

### 12.1 Neden eğri kaldırıldı

İki yaklaşımın farkını **zaman ekseninde** çizmek, istemeden bir *sonuç* eğrisi
gibi okunuyordu: yükselen bir çizgi, ne kadar dikkatli etiketlenirse etiketlensin,
"sen de böyle yükseleceksin" diye anlaşılıyor. Altına eklenen "bu bir sonuç vaadi
değil" notu da ekranın en uzun cümlesi hâline gelmişti — bir görselin yanına
kendisini reddeden bir dipnot koymak, görselin yanlış olduğunun itirafıdır.

Yerine `ComparisonColumns`: solda **Kütüphane**, sağda **Patika**, satır satır
eşleşen kısa ifadeler. Aynı farkı tek bakışta, hiçbir sayı ima etmeden gösteriyor;
dipnota ihtiyaç kalmıyor çünkü sayısız bir sütun karşılaştırması sonuç vaat edemez.

### 12.2 Tek mürekkep

Kırmızı/yeşil karşıtlığı yok (§5). Ayrım üç sinyalle birden yapılır:

| Sinyal | Kütüphane | Patika |
|---|---|---|
| Sütun başlığındaki işaret | `xmark` | `checkmark` |
| Metin parlaklığı | %55–58 | %95–100 |
| Metin ağırlığı | `Theme.Weight.body` | `Theme.Weight.emphasis` |

Renk körlüğünde de, gri tonlamalı ekran görüntüsünde de okunur. İki sütun arasında
ince bir ayırıcı çizgi var; sağ sütuna dolgu verilmiyor çünkü `Grid` sütun
genişliğini dışarı vermiyor ve dolgu ancak tahminle çizilebilirdi.

### 12.3 Hizalama ve erişilebilirlik

Satırlar `Grid` ile kurulur: aynı indeksteki iki ifade aynı satırda durur ve biri
iki satıra sarsa da karşılığı onunla aynı yükseklikte kalır.

**Beliriş:** bir satırın iki yanı **aynı** `listReveal` indeksini alır — karşılaştırma
çiftin birlikte görülmesiyle kuruluyor, teker teker belirirse okuma sırası bozulur.

**Erişilebilir Dynamic Type:** iki sütun ekranın yarısına sıkışıp tek kelimelik
satırlar bile üç satıra sardığı için, `dynamicTypeSize.isAccessibilitySize`
durumunda yerleşim alt alta iki bloğa döner. Aynı bilgi, kırılmayan yerleşim.

---

## 13. C4 SÜREÇ GRAFİĞİ

`ExpectationCurveChart` — kodla çizilen, animasyonlu. Raster görsel kullanılmaz:
bir yandan çizilen bir grafik, bir yandan sabit bir illüstrasyon aynı ekranda iki
görsel odak yaratır ve çizim kaçırılır.

### 13.1 Kompakt tutulur

Grafik **132 pt** yüksekliğinde ve çevresinde yalnızca iki metin katmanı var:
gösterge satırı (kesik = diğer uygulamalar, düz = Patika) ve iki uç etiketi
("Başlangıç" / "21. gün").

Önceki hâli 252 pt'ydi ve dört metin katmanı taşıyordu; ortadaki "7–8. gün"
etiketi ile alttaki "sonuç vaadi değil" notu **kaldırıldı** (2026-09-08). Gerekçe:
ekranda zaten üç cümlelik bir metin var ve grafiğin çevresindeki yazılar onlarla
yarışıyordu. Dönüm noktasını kesik dikey çizgi gösteriyor, sözünü de üstteki
cümle söylüyor ("Değişim genelde 7–10. günde fark edilmeye başlıyor").

**Dikey eksende sayı yok ve olmayacak.** Çizgiler ölçüm sonucu değil, iki
yaklaşımın zaman içindeki ritmi. Yatay eksende de yalnızca iki uç yazılı.

### 13.2 Animasyon

| Aşama | Süre | Ne olur |
|---|---|---|
| Diğer uygulamalar | 1.15 sn | Kesikli eğri soldan sağa dalgalanarak çizilir, başladığı yerin altında biter |
| Nefes | 0.22 sn | İki çizgi arasında kısa duruş |
| Patika | 1.55 sn | Kesiksiz eğri; ilk sekiz gün küçük adımlar, sonra ivmelenerek yükselir |

**Tetikleyici kaydırma görünürlüğü, zamanlayıcı değil.** Grafik cümlelerin altında
duruyor ve küçük ekranda ilk açılışta görünmüyor olabilir; zamanlayıcı animasyonu
kullanıcı görmeden oynatırdı. `onScrollVisibilityChange` ile %30 görünür olduğunda
başlıyor. Gecikme `Theme.Motion.revealDelay(_:)`den gelir — cümle sırasıyla
yarışmasın diye.

**Reduce Motion:** animasyon yok, grafik doğrudan tamamlanmış hâlde çizilir.

**VoiceOver:** grafik tek bir öğe; eğrileri tarif eden bir etiket okunuyor
(`Copy.Onboarding.expectationChartAccessibilityLabel`).

---

## 14. F BÖLÜMÜ — İZ DİLİ

F1 (üretim), F2 (yol haritası) ve onboarding sonrası "Yolum" aynı rota
metaforunu kullanır. F1 kısa bekleyiş için kompakt `TrailRow` olarak kalır; F2 ve
"Yolum" gerçek kişisel içeriği taşıyan ortak `JourneyMapRow` ile sağa-sola
kıvrılır. Düğüm bir kolondayken metin karşı kolonda kalır. Erişilebilir Dynamic
Type'ta kıvrım düz sol raya dönüşür ve metin tam genişliği kullanır.

Gelecek adımların başlığı saklanmaz: kullanıcı yolun yönünü görür, fakat kesikli
iz ve kilit simgesi bu adımların henüz açılamayacağını birlikte anlatır. "Yolum"
başlıkları ve teknikleri yalnızca gerçek `ActivePath`/`PathStepRecord` verisinden
gelir; harita rastgele veya dekoratif adım metni üretmez.

### 14.1 Düğüm tipleri

| Tip | Biçim | Nerede |
|---|---|---|
| `pending` | F1'de küçük boş halka; haritada kilitli 34 pt halka | Henüz gelinmemiş adım |
| `active` | Nefes döngüsüyle soluyan dolu nokta; haritada 50 pt odak | O an çalışan / sıradaki aşama |
| `done` | Dolu nokta; haritada onay işaretli 36 pt düğüm | Tamamlanan aşama |
| `milestone` | Haritada çift halkalı 42 pt düğüm | Ölçüm günleri |

**Ölçüm günü yıldızla işaretlenmiyor.** PRD-Ek Onboarding §7.2'nin taslağında ⭐
var; emoji hiçbir yerde kullanılmıyor (Görsel Sistem §5) ve renkli bir yıldız tek
mürekkep kuralını da bozardı. Aynı mürekkep, farklı biçim: halka.

### 14.2 F1'de tek hareket

Bekleyiş boyunca ekranda hareket eden tek nesne aktif düğüm ve o da nefes
döngüsünün 10 saniyelik ritmiyle soluyor — kullanıcının nefesiyle aynı hızda.
Yüzde göstergesi, dönen çark ve "neredeyse bitti" yalanı yok; ikisi de bekleyişi
ölçülecek bir yüke çevirir. Ekranın butonu da yok: yapılacak bir şey olmadığı için
boş bir CTA koymak bekleyişi kullanıcının sorunu gibi gösterirdi.

Nefes genliği bu ekranda `BreathAmplitude.generation` (%80): arka plan "çalışıyor"
gibi değil, "soluk alıyor" gibi durur.

### 14.3 F2'nin basılı tut butonu

`HoldToStartButton` — 1.4 saniye basılı tutulur, buton parmağın altında %14
büyür, haptik nabız hızlanır (başta ~180 ms, sonda ~70 ms) ve şiddetlenir.
Bırakılırsa yay hareketiyle eski boyutuna döner ve hiçbir şey olmaz.

**Haptik tek kademe kalır** (Ton eki §7): stil hep `.soft`, değişen yalnızca
`intensity` ve sıklık. `.rigid` / `.success` kullanılmıyor.

**Gerekçe:** bu dokunuş onboarding'in sonu ve ilk oturumun başı; tek yanlış
dokunuşla geçilecek bir eşik değil. Ürün bu kalıbı zaten tanıyor — SOS butonu da
basılı tutulunca büyüyor (Ton eki §2.2).

**Erişilebilirlik:** VoiceOver ve Switch Control basılı tutma jesti üretemez;
buton yardımcı teknolojiden gelen etkinleştirmede beklemeden çalışır. Reduce
Motion'da büyüme yerine mürekkep soldan sağa dolar — bekleme kalır, hareket gider.

### 14.4 Harita hareketi ve performans

Rota satır başına native `Shape` + `trim` ile bir kez çizilir; scroll sırasında
tercih/state yazan geometri ölçümü yapılmaz. Satırların gecikmesi üstten alta
kademeli fakat toplam görünüş hareketi 800 ms altındadır. Aktif düğüm ve bu iki
harita ekranındaki mesh normal koşullarda 60 Hz zaman çizelgesi ister. Düğümün
nefes değeri yalnızca aktif grafik overlay'ine verilir; satır metni ve kart gövdesi
zaman çizelgesinin dışında kalır. Düşük güç, ciddi termal baskı, arka plan ve
Reduce Motion güvenlik düşüşleri sürekli hareketi durdurur. Reduce Motion'da rota
doğrudan tamamlanmış, aktif düğüm statik gösterilir; dekoratif çizgi ve düğümler
VoiceOver'dan gizlidir.

Fazların yatay ritmi `PathPlan.phase` + `JourneyRouteLayout` ile deterministiktir;
rastgelelik kullanılmaz. F2'de faz değişimi kısa çizgi aralığıyla gösterilir.
Onboarding sonrası Yolum'da ise rota hiçbir fazda kesilmez: faz etiketi izin
kenarına alınır, gelecek bölüm kesik yerine daha soluk düz çizgi olur ve yatay
düğüm–metin bağlantıları kaldırılır. AX Dynamic Type'ta aynı anlam düz sol ray
üzerinde korunur. Oturum sonrası aktif → tamamlandı dönüşümü yalnızca sunucudan
yeniden okunan `completed_at` değişimiyle çalışır ve tek yumuşak haptik verir.

### 14.5 Yolum boşluk illüstrasyonları

Yolum, mevcut C1/C2'nin kırık beyaz dokulu şerit ailesini sürdüren üç transparan
heykelsi görsel kullanır: `journey-relief`, `journey-practice` ve
`journey-closing`. Başlıktaki görsel sıradaki adımın gerçek fazından; rota
boşluklarındaki görseller yalnızca gerçek faz başlangıçlarından seçilir. Ham
problem metni, yaş veya cinsiyet görsel seçmez. Orta fazların aynı pratik formunu
paylaşması görsel çeşitlilik uğruna sahte kişiselleştirme üretilmesini engeller.

Uygulama kopyaları 512 piksel uzun kenar ve yaklaşık 93–186 KB'dır. Görseller
statik, düşük opaklıklı, dokunulamaz ve VoiceOver'dan gizlidir. AX Dynamic Type'ta
metin alanını daraltmamak için gösterilmez; Reduce Transparency'de başlık görseli
daha da solar. Emoji, yüz, ödül, yıldız, ok ve sonuç grafiği içermezler.
