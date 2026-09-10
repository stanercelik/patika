# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proje durumu

**Patika** (çalışma adı) — kullanıcının derdini kendi kelimeleriyle anlattığı, karşılığında 7/14/21/28 günlük **ölçülen ve biten** bir program aldığı iOS meditasyon/zihinsel iyi oluş uygulaması. Sahibi: Novum Apps.

**Temel katman kuruldu, onboarding'in ilk 29 ekranı çalışıyor.** Mevcut kod: tasarım sistemi (palet + shader + nefes), domain enum'ları, SwiftData modelleri, mikrometin kütüphanesi, üç sekmelik uygulama kabuğu, kimlik bloğu ve onboarding A + B + C + D + E + F bölümleri. Oturum çalar ve path üretimi **henüz yazılmadı**; ölçümün skorlanması da (ekranlar cevap topluyor, skor üretmiyor).

Bu depoda asıl kaynak kod değil, **ürün spesifikasyonudur** — herhangi bir özellik yazmadan önce ilgili PRD bölümü okunmalı.

## Komutlar

Xcode projesi: `patika.xcodeproj` · Tek hedef ve tek şema: **`MyApp`** (ürün adı `patika` ama target adı henüz `MyApp`).

```bash
# Derle (simulator)
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Testler (test hedefi henüz yok — eklendiğinde bu komut geçerli)
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Tek test
xcodebuild ... test -only-testing:MyAppTests/PaletteTests/testBlendPicksDarkerBackground

# Şema/hedef listesi
xcodebuild -list -project patika.xcodeproj
```

```bash
# Simülatörde çalıştır (görsel doğrulama için)
xcrun simctl boot "iPhone 17 Pro"; open -a Simulator
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'id=<UDID>' -derivedDataPath /tmp/patika-dd build
xcrun simctl install booted /tmp/patika-dd/Build/Products/Debug-iphonesimulator/MyApp.app
xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp
xcrun simctl io booted screenshot /tmp/shot.png
```

**Metal toolchain zorunlu.** `Shaders.metal` olmadan proje derlenmez. Kurulu değilse:
`xcodebuild -downloadComponent MetalToolchain`

**Deployment target: iOS 26.0.** PRD §13.1 ve karar #13 minimum iOS 18 diyordu; 2026-09-08'de bilinçli olarak **iOS 26.0'a çekildi** (kullanıcı kararı). Yani en yeni API'ler serbest, ama PRD'nin "pazarın ~%95'i" gerekçesi artık geçerli değil — pazar kapsamı dokümanda yazandan belirgin şekilde dar. PRD'yi bu kararla güncellemek gerekiyor.

## Kod yerleşimi

Hedef **file-system synchronized group** kullanır (`PBXFileSystemSynchronizedRootGroup`): `MyApp/` altına konan her dosya otomatik derlenir. **`.pbxproj` elle düzenlenmez** — yeni dosya eklemek için sadece dosyayı oluştur.

| Klasör | İçerik |
|---|---|
| `MyApp/App/` | `@main` giriş noktası, `RootView` (üç sekme + sabit SOS) |
| `MyApp/DesignSystem/` | `RGB`, `Palette` (10 kategori + harmanlama + gece modu), `BreathCycle`, `BreathingMeshBackground`, `Shaders.metal`, `Theme`, `PaletteController` |
| `MyApp/Models/` | `DomainEnums` (kategori, kimlik, path, ölçüm, sonuç kovaları, tercihler), `PersistentModels` (SwiftData), `MeasurementLibrary` (D1–D8 maddeleri + A/B/C varyantları), `PathPlan` (F2 yol haritası satırları) |
| `MyApp/Content/` | `Copy` (mikrometin), `Tone` (kişilik kademeleri + yasak ifadeler) |
| `MyApp/DesignSystem/Components/` | `DisplayText`/`BodyText`, `PrimaryButton`, `OnboardingHeader` (+geri butonu), `PathProgressBar`, `OnboardingQuestionLayout`, `OnboardingStatementLayout`, `ChoiceRow`, `MoodScale`, `IntensityScale`, `OnboardingTextInput`, `OnboardingIllustration`, `ComparisonColumns`, `ExpectationCurveChart`, `TrailRow`, `JourneyMapRow`, `HoldToStartButton` |
| `MyApp/Features/<Özellik>/` | MVVM ekranları. Onboarding'de kimlik bloğu ve A, B, C, D, E, F bölümleri hazır |
| `assets/illustrations/` | Üretilecek görsellerin kaynak dosyaları + kurulum talimatı (uygulamaya giren kopyalar `Assets.xcassets/Onboarding/`) |

## Mimari: MVVM

- **ViewModel** — `@Observable @MainActor final class`. Tüm karar, doğrulama ve navigasyon burada. `SwiftUI` import etmez.
- **View** — sadece yerleşim ve bağlama. `if`/`switch` ile iş kuralı hesaplamaz; ViewModel'in hazır özelliğini okur (`canContinue`, `isDimmed(_:)` gibi).
- **Model** — `Models/` altındaki enum'lar ve SwiftData sınıfları.
- Ekran ViewModel'i `@State private var viewModel` olarak View'in `init`'inde kurulur; akış nesnesi (`OnboardingFlowViewModel`) dışarıdan enjekte edilir.
- Paylaşılan durum `.environment(...)` ile geçer (`PaletteController`, `AppState`).

Onboarding akışında **akış VM'i tek sahiptir**: `OnboardingFlowViewModel` adım yönlendirmesini, `OnboardingDraft` taslağını ve palet senkronunu tutar. Adım VM'leri (`WelcomeViewModel`, `CategorySelectionViewModel`) ona yazar, birbirini tanımaz.

`OnboardingDraft` bilerek `struct` ve kalıcı değil: onboarding yarıda kalırsa veritabanında yarım kayıt kalmaz. `ProblemStatement` / `UserProfile` ancak akış tamamlanınca üretilir.

### Emoji yasak

**Hiçbir yerde emoji kullanılmaz** — arayüzde, metinde, kod yorumunda. Emoji çok renkli ve platforma göre değişken; tek mürekkepli tasarım sistemini bozuyor ve ürünün ciddiyetiyle çelişiyor.

Yerine **SF Symbols**: monokrom, metin ağırlığıyla eşleşir, Dynamic Type ile büyür, VoiceOver'a hazır, sıfır bağımlılık. Kategori ikonları `ProblemCategory.icon` arkasındadır — markaya özel bir ikon setine geçilecekse yalnızca orası değişir.

Bu kural PRD'yi de ezer: PRD-Ek Onboarding §3.6 B6'yı 5'li **emoji** ölçek olarak tarif ediyor, uygulanan `MoodLevel` ise monokrom bir hava metaforu (`cloud.heavyrain` → `sun.max`). Aynı beş kademe, aynı tek dokunuş.

### Onboarding'de SOS yok

`OnboardingHeader` yalnızca geri butonu ve ilerleme izi taşır. Bu, PRD §6'nın "HER EKRANDA SOS" kuralından **bilinçli bir sapmadır** (ürün sahibi kararı, 2026-09-08): onboarding kısa bir akış ve kriz yakalaması B1'deki serbest metin sınıflandırıcısıyla yapılıyor. SOS, onboarding bittikten sonra `RootView`'da her ekranda sabit.

> Mağaza incelemesi ruh sağlığı kategorisinde kriz kaynaklarının erişilebilir olmasını istiyor (PRD §14.3). B1 sınıflandırıcısı bu yüzden bloklayıcı — onsuz onboarding canlıya çıkmamalı.

### İlerleme göstergesi sayı değil, iz

"Adım 1 / 7" gibi sayaç kullanılmaz; `PathProgressBar` bir iz çizer — A1'deki yol animasyonuyla aynı dil. Sayı, kalan adımları saydırıp "daha ne kadar var" hissini öne çıkarır; iz kat edilen yolu öne çıkarır. `OnboardingStep.progress` 0…1 döner; nil ise iz solar ama **son değerini korur**, sıfıra dönmez.

İzin ucunda **düğüm yok** (karar, 2026-09-08): düğüm gözün takip ettiği bir nesne yaratıyordu ve izin kendisi yerine noktanın konumu okunuyordu.

İlerleme **bölüm içi**dir: soru bölümü = kimlik (3) + A2 + B1–B6 = 10 ekran, iz B6'da dolar. C bölümünde soru yok, iz solar; D (8) ve E (3) kendi ölçekleriyle yeniden başlar.

### Onboarding kabuğu kalıcı, yalnızca içerik değişir

`OnboardingContainerView` arka planı, geri butonunu ve ilerleme izini **bir kez** kurar; adım değişirken bunlar yerinde kalır. Ekranlar kendi üst çubuğunu **çizmez** — `OnboardingHeader` yalnızca kabukta bulunur.

Bu bir düzeltmedir (ürün sahibi kararı, 2026-09-08): önceden her ekran kendi çubuğunu çiziyordu, geçişte geri butonu gidip geliyor ve iz sıfırdan doluyordu; akış tek bir yol değil 31 ayrı ekran gibi görünüyordu.

- Geri butonu **her zaman yerini korur**; `canGoBack` false ise yalnızca görünmez ve dokunulamaz olur. Yerinden kaldırmak izin yatay konumunu kaydırıyordu.
- Geri butonu çıplak `chevron.left` — **yuvarlak arka plan yok**. Daire, geri gitmeyi ekranın en belirgin nesnesi yapıyordu. Dokunma alanı yine 44×44.
- Adım geçişi **sıralı fade**: giden içerik 160 ms solar, gelen içerik 340 ms'de 14 pt aşağıdan süzülerek belirir (`AnyTransition.onboardingStep(reduceMotion:)`). Yatay kayma yok, eşzamanlı cross-fade de yok — iki farklı yükseklikteki içerik üst üste binip kirli görünüyordu.
- Yeni soru ekranı `OnboardingQuestionLayout` (soru + ipucu + cevap alanı + alt aksiyon) üzerine kurulur; tek seçimlik listeler `ChoiceList` + `ChoiceRow`. **Soru sormayan** ekranlar (C bölümü) `OnboardingStatementLayout` kullanır — aynı alt buton ritmi, farklı içerik iskeleti.

### C bölümünde cümleler tek tek belirir

C ekranlarındaki her paragraf `.sequentialReveal(index)` ile sırayla süzülür (400 ms giriş + adım başına 1,5 sn, her biri 700 ms'de solarak ve 8 pt aşağıdan). Aralık 1 sn'den 1,5 sn'ye çıkarıldı (ürün sahibi kararı, 2026-09-08): bir saniye önceki cümleyi bitirmeye yetmiyor, sonraki cümle okuma sürerken belirip gözü aşağı çekiyordu. Beklemek zorunlu değil — CTA baştan basılabilir. Gerekçe (ürün sahibi kararı, 2026-09-08): aynı anda basılan 3–4 cümle "duvar" gibi görünüyor ve göz nereden başlayacağını bilemiyor; bir saniyelik ritim her cümleye kısa bir okuma payı bırakıyor. Reduce Motion'da kayma yok, yalnızca solma.

Gecikmeler `Theme.Motion.revealDelay(_:)` üzerinden hesaplanır — sıraya dahil olmayan ama sırayı bekleyen öğeler (C4 grafiği) de aynı fonksiyonu kullanır, böylece iki hareket yarışmaz. C3'ün iki sütunu istisnadır: bir satırın iki yanı **aynı** indeksi alır, çünkü karşılaştırma çiftin birlikte görülmesiyle kuruluyor.

C ekranlarının raster görselleri `OnboardingIllustration` yuvasına konur ve **varlık yoksa bileşen hiç yer kaplamaz**. C1 görseli durum + süre aynalamasından sonra 282 pt, C2 görseli yaygınlık cümlesinden sonra 292 pt sahnede gelir; erişilebilir Dynamic Type'ta ikisi de 194 pt'ye iner. C4 raster kullanmaz: `ExpectationCurveChart`, diğer uygulamaları önce kesik/soluk; Patika'yı sonra düz/parlak çizgiyle ve `easeInOut` zamanlamayla çizer. Grafik **kompakttır** (132 pt) ve çevresinde yalnızca gösterge satırı + iki uç etiketi vardır; ortadaki dönüm etiketi ve alt not kaldırıldı (ürün sahibi kararı, 2026-09-08) — ekranda zaten üç cümle var, dört metin katmanı onlarla yarışıyordu. **C3 artık grafik taşımaz**: karşılaştırma `ComparisonColumns` ile solda kütüphane / sağda Patika olarak yan yana yapılır. Güncel görsel kuralları Görsel Sistem eki §11'de, raster kaynaklar `assets/illustrations/` altındadır.

### Kimlik bloğu: isim, cinsiyet, yaş

PRD'de yok, sonradan eklendi (ürün sahibi kararı, 2026-09-08). Üç ekran **A1'in sonrasında, A2'nin öncesinde**: kanca ekranının önüne form koyulmaz, ama hitap adı akışın geri kalanında gerekiyor.

- **İsim isteğe bağlı.** "İsim vermek istemiyorum" akışın hiçbir yerini kapatmaz; ada göre iki sürümü olan metinler `Copy.Onboarding` içinde fonksiyon (`mirroringHeadline(name:)`, `honestExpectationHeadline(name:)`), isimsiz sürüm eksik sürüm değil. Ad `OnboardingDraft.displayName` üzerinden okunur.
- **Ad sayılı yerde kullanılır**, her ekranda değil: şu an C1 (aynalama — en yüksek güven anı) ve C4 (dürüst beklenti — hoşa gitmeyecek şeyi kişisel söylemek). Her cümlede adı geçen arayüz samimi değil, ısrarcı olur ve satış yazılımı gibi okunur. Yeni bir kullanım yeri eklemek bilinçli bir karar olmalı.
- **Cinsiyet ve yaş ürünün hiçbir davranışını değiştirmez** (`Gender`, `AgeRange` doküman yorumları). Bu bir sınır: kategori/ruh hâli/ölçüm path'i değiştirir, bunlar değiştirmez. İkisinin de ekranında bunu **kullanıcıya söyleyen** bir not var (`identityStatsNote`) — sorduğumuz her şeyin karşılığı olmalı kuralının dürüst istisnası. Path üretimine girecekse ayrı bir karar ve gerekçe gerekir.
- Doğum tarihi sorulmuyor; bağlayıcı 18+ kontrolü kayıt ekranında (H1) kalıyor (PRD §11.4). Buradaki aralık istatistik, kapı değil.
- Ad da serbest metin olduğu için `CrisisClassifier`dan geçer — kuralın istisnası olduğu an kural değildir.

### E bölümü: üç cevabın üçü de davranışı değiştirir

E1 hatırlatma saati (bildirim), E2 adım uzunluğu (blok seçimi + ses uzunluğu), E3 ton (TTS istemi). "Kişiselleştirme tiyatrosu" değil — kullanıcıya renk seçtirmek kişiselleştirme değildir.

- **E1'de varsayılan yanlılığı bilinçli olarak kullanılır:** saat B3'ün cevabından önceden dolu gelir ve gerekçesi kullanıcının kendi cevabına atıfla yazılır (`ProblemTiming.reminderReason`). Sınır değişmedi: aynı teknik **ödeme ve abonelik kararlarında kullanılmaz**. "Başka saat seç" tekerleği yerinde açar, ayrı ekran yok.
- **E2'de önerilen seçenek (10 dk) önceden seçilidir** (`SessionLength.isRecommended`), PRD'nin açık tercihi.
- **E3'te önceden seçim yoktur.** PRD ton için bir öneri vermiyor; olmayan bir öneriyi varsayılan seçimle ima etmek kullanıcıyı kendi tercihi olmayan bir sese iter. `OnboardingDraft.tonePreference` bu yüzden opsiyonel; profil kurulurken `resolvedTonePreference` devreye girer.

E3'ten sonra akış `f1Generation`a düşer; orası henüz `NotYetBuiltView`.

### F bölümü: iz dili, birleştirilmiş harita, basılı tut

**F2 ile F3 birleştirildi** (ürün sahibi kararı, 2026-09-09). PRD ikisini ayırıyordu: F2 özet kart, F3 kaydırınca açılan "gerçek" harita. İkisi de aynı şeyi gösteriyordu; "kaydırınca haritaya geç" adımı kullanıcıya zaten gördüğü bir şeyi tekrar açtırıyordu. Harita doğrudan F2'de, ölçüm noktaları üstünde işaretli.

- **F1 ve F2 aynı rota metaforunu farklı ölçekte kullanır.** F1'in kompakt üretim izi `TrailRow`; F2'nin okunabilen haritası ve onboarding sonrası "Yolum" ekranı ortak `JourneyMapRow`dur. Harita sağa-sola kıvrılır, metin düğümün karşı kolonunda kalır ve erişilebilir Dynamic Type'ta düz sol raya döner. Ölçüm günleri **yıldızla değil halkalı düğümle** işaretlenir (PRD taslağında yıldız var; emoji yasağı ve tek mürekkep kuralı).
- **F1'in butonu yok.** Kullanıcının yapacağı bir şey yok; boş bir CTA bekleyişi kullanıcının sorunu gibi gösterirdi. Ekran işi bitince kendi geçer — onboarding'de dokunuş beklemeyen tek ekran. Yüzde göstergesi ve dönen çark da yok; hareket eden tek şey nefes döngüsüyle solan aktif düğüm.
- **F1'in zamanlayıcısı geçici.** Ağ katmanı yok, aşamalar `GenerationViewModel`de zamanlayıcıyla ilerliyor. Süreler bilerek gerçekçi (toplam ~11 sn): 2 saniyede biten bir sahte bekleme, gerçek üretim eklendiğinde ekranı bambaşka hissettirirdi. Gerçek üretimde `advance` sunucu olaylarına bağlanır, ekran değişmez.
- **F1 ve F2'de geri yok.** F1'de üretim çalışıyor, F2'de path üretilmiş durumda; geri dönüp E3'ün tonunu değiştirmek elde duran path'i sessizce yanlış hâle getirirdi.
- **"Yola çık" basılı tutulur** (`HoldToStartButton`, 1.4 sn): buton bir kapsülden başlayıp **tüm ekranı kaplayan** bir alana büyür (ürün sahibi kararı, 2026-09-09), haptik nabız hızlanıp şiddetlenir, bırakılırsa yayla geri iner. Dolgu paletin en parlak noktasının kırık beyazla karışımından gradyanlı: ton kategoriden geliyor, luminans metin renginden — arka planın akrabası ama ondan ayrık ve siyah buton metni büyüme boyunca okunur. Tamamlanınca dolgu geri inmez; F2→G1 geçişi o ışığın altında olur. Önceki %14'lük büyüme bekleme süresinin nerede olduğunu göstermiyordu. Haptik yine tek kademe — `.soft`, değişen yalnızca `intensity` ve sıklık. Aynı kalıp SOS butonunda da var (Ton eki §2.2). VoiceOver/Switch Control jesti üretemediği için buton yardımcı teknolojiden gelen etkinleştirmede beklemeden çalışır; Reduce Motion'da büyüme yerine mürekkep dolar.
- **Path başlığı ve uzunluğu geçici.** Gerçeği path üretiminden gelecek (PRD §9.1); `ProblemCategory.provisionalPathTitle` çevrimdışı ve hata durumları için yedek olarak kalır. Faz açıklamaları da öyle (`PathPhase.roadmapDescription`) — üretim onları kullanıcının cevaplarından kişiselleştirecek.
- **F2'de paywall yok** ve bu bilinçli bir risk (PRD-Ek Onboarding §7.3). Buraya ödeme koymak "işe yaradığını gördükten sonra öde" iddiasını ilk beş dakikada çürütürdü.
- Liste öğeleri `listReveal` kullanır (0.11 sn aralık), C'nin `sequentialReveal`ı (1.5 sn) değil: yedi satırlık harita, okuma temposuyla belirse son satır 14. saniyede görünürdü.

> **Açık karar: F4 nereye gidiyor?** PRD'de fiyat şeffaflığı ekranı F4'tü ve G1'den önce geliyordu. F2'nin "Yola çık"ı artık doğrudan G1'i başlattığı için F4 akışta yersiz kaldı. En makul yeni yeri G2'den (oturum sonu) sonra, H1'den (kayıt) önce — ama bu henüz onaylanmadı. **Silinmedi, ertelendi:** onboarding'de fiyatın gösterilmesi PRD'nin yapısal kararlarından biri.

### Soru ile cevap arası sabit boşlukla ayrılır

`OnboardingQuestionLayout`ta soru ile cevap alanı arasındaki aralık 24 pt (`questionToAnswerGap`). Bir ara bu boşluk esnetilip cevap ekranın altına itilmişti; **geri alındı** (ürün sahibi kararı, 2026-09-08): cevap alanı sorudan kopuyor ve ekranda birbiriyle ilgisiz iki blok gibi duruyordu. Sabit ama eskisinden geniş bir aralık ikisini bir arada tutuyor.

### D bölümü: ölçüm cevap toplar, skor üretmez

Sekiz soru sekiz ayrı ekrandır (`OnboardingStep.dMeasurement(Int)`, 1 tabanlı) — tek ekrana yığmak "iş" gibi görünüyor, teker teker göstermek hızlı hissettiriyor. Sorular `MeasurementLibrary`den gelir; ekran hangi sorunun sorulduğunu bilmez, yalnızca cevabın biçimini çizer (kova listesi ya da `IntensityScale`).

- **Skor yok.** Bu ekranların hiçbirinde toplam, yorum ya da iyi/kötü işareti yoktur (PRD §7.3). Cevaplar `OnboardingDraft.measurementResponses`ta **ham** durur (anahtarlar `Measurement.rawResponses` ile aynı); normalize etme ve skorlama ölçüm servisinin işi ve henüz yazılmadı. `MeasurementItem.higherMeansBetter` yön bilgisini o güne kadar saklar — ekranlar bu bayrağı okumaz.
- **Varsayılan cevap yok.** Önceden doldurulmuş bir cevap baseline'ı kirletir ve 7. gündeki karşılaştırmayı anlamsız kılar. Varsayılan yanlılığı E1'de bilinçli bir araç, ölçümde veri sahtekârlığı olurdu.
- **Atlanamaz.** D ekranlarında "geç" bağlantısı yoktur (PRD-Ek Onboarding §10): baseline olmadan 7. günde karşılaştırılacak bir şey kalmıyor.
- **Madde rotasyonu koda gömülü** (PRD §8.3): ifade `MeasurementVariant`a göre değişir, `id` ve cevap kovaları değişmez. `MeasurementItem.id` **asla değiştirilmez** — değişirse kullanıcının geçmiş ölçümüyle bağ kopar.
- **D5 kategoriye göre değişir** (PRD §8.5). PRD beş path tipi sayıyor, A2'de on kategori var; karşılığı olmayanlar ortak bir davranış maddesine düşer. Kategori→path eşlemesi netleşince (PRD açık soru #3) tablo path tipiyle anahtarlanmalı.
- Ölçüm ekranlarında nefes genliği kısılır (`BreathAmplitude.measurement`, %35) — genlik artık adımın kendi özelliği: `OnboardingStep.breathAmplitude`.
- Her ekranın altında `Copy.clinicalDisclaimer` sabittir (PRD §8.1).

D8'den sonra akış E bölümüne (`e1Reminder`) geçer.

### Tipografi bir kademe kalın

Genel tavır sistem varsayılanından bir kademe kalındır (ürün sahibi kararı, 2026-09-08 — gerekçe: Görsel Sistem eki §5.1). Ağırlıklar **`Theme.Weight`**, çizgi kalınlıkları **`Theme.Line`** altında tek kaynakta:

`display` `.heavy` · `title` `.bold` · `body` `.medium` · `action` `.bold` · `emphasis` `.semibold`

**Hiçbir yerde satır içi `.weight(.semibold)` yazılmaz.** Ağırlık seçmiyorsun, rol seçiyorsun — tavır geri alınacaksa tek dosya değişir.

**Ürün kuralları koda gömülüdür — düz metin yorum değil, kontrol edilebilir API:**
- `OutcomeBucket.allowsSelling` → Kova C'de **false**. Paywall çağıran her yer bunu kontrol etmeli.
- `OutcomeBucket.badgeShowsNumbers` → Kova C'de false; `BadgeArtifact.init` `headlineChange`'i bu bayrağa göre siler, yani sonuç uydurulamaz.
- `ToneTier` → kademe yukarı çıkarılamaz; `allowsWhimsy` / `maxCelebrationIntensity` üzerinden kontrol edilir.
- `BannedPhrases.check(_:)` → yasaklı ifade taraması.
- `BreathAmplitude.crisis` = 0 → kriz ekranında hareket yok.
- `ProgramPath.needsAdaptation` → üst üste 3 olumsuz geri bildirim (PRD §9.4).
- `UserProfile.canClaimFreeContinuation` → ömür boyu 2 ücretsiz devam.

`ProgramPath` adı bilinçlidir — SwiftUI'ın `Path` tipiyle çakışmaması için.

### G bölümü: ilk oturum gerçekten çalışıyor

G1 artık `NotYetBuiltView` değil. Akış: F1'de path üretilir ve **1. adımın sesi** JIT olarak sunucudan istenir (`OnboardingFlowViewModel.prepareFirstStepAudio`, PRD-Ek Path Üretimi §6); F2'de "Yola çık" basılı tutulur; G1 o adımı oynatır.

- **Sahneler nefes döngüsüyle zamanlanır**, saniyeyle değil (`SessionCue.breaths` × `BreathCycle.period`). Arka plan zaten o döngüyle soluyor; metnin döngü ortasında değişmesi nefesi bölüyordu.
- **Kişiselleştirme çerçevede, teknik sabit.** Açılış / geçiş / kapanış sunucunun `slot_copy`sinden (`BlockLibrary.Slot`), teknik ise istemcideki `BlockLibrary`den gelir — kimlikler sunucudaki `approvedBlockIds` ile birebir aynı. Tekniği ağdan çekmek çevrimdışı oturumu imkânsız kılardı.
- **Kullanıcının kendi cümlesi ikinci sahnedir** — akışın aha momenti. B1 atlandıysa sahne hiç kurulmaz; uydurma bir cümle yansıtmak kişiselleştirme iddiasını en görünür yerde çürütürdü.
- **E2'nin cevabı burada karşılığını bulur:** teknik sahnelerin süresi seçilen dakikaya ölçeklenir (tam nefes döngüsüne yuvarlanarak). Açılış ve kapanış ölçeklenmez.
- **Ses eksik olabilir ve bu hata değil.** `SessionAudioPlayer` `AVAudioEngine` + iki `AVAudioPlayerNode` → `AVAudioMixerNode` üzerine kurulu (manifest zaman çizelgesini sırayla çalıyor; sessizlik istemcide zamanlanıyor), `.playback` + `UIBackgroundModes: audio` + `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`. **TTS sağlayıcısı sunucuda yapılandırılmadığı sürece** (`PATIKA_TTS_LIVE_ENABLED`, `ELEVENLABS_API_KEY`) `generate-audio` 503 döner, ekran sessiz sürüme düşer ve oturum yine tamdır.
- Ses hazırsa **yalnızca açılışı** seslendirir ve açılış sahnesi ses bitene kadar beklet: duyulan cümleyle ekrandaki cümlenin ayrışması en kötü yerde oluyordu.
- Kalan süre **sayıyla gösterilmez**; geri sayan bir sayı oturumu bitmesi beklenen bir şeye çevirir. Yerinde ince bir iz var.

**G2 — oturum sonu.** Kutlama şiddeti 1/5 (PRD-Ek Onboarding §8): konfeti yok, rozet yok, "harika iş" yok. Ekranda tek cümle, tek bilgi, tek buton.

- **İki hâli var ve ikisi aynı şeyi söylemiyor.** Sonuna kadar dinlendiyse "İlk adım tamam."; "Burada duralım" ile çıkıldıysa **"tamam" denmez** — ölçtüğünü iddia eden bir üründe olmayan bir şeyi olmuş göstermek ilk yalan olurdu. Yarıda bırakanda kalan adım sayısı da yazılmaz: bitirmemiş birine "20 adım daha var" demek kalan yolu borç gibi okutur.
- **E1'in saati ilk kez burada işe yarar.** "Sorduğumuz her şeyin karşılığı olmalı" kuralının son halkası.
- **`completed_at` yalnızca tam dinlendiğinde yazılır** ve yazma beklenmez (`markFirstStepCompleted`, ateşle-unut). Bu sütun profildeki ilerlemeyi besleyecek; dolduramadığı bir adımı dolmuş göstermek kullanıcının kendi kaydını yalanlamak olurdu.

> **Uygulandı (2026-09-09):** `supabase/migrations/20260909120000_allow_step_completion.sql` uzak projede duruyor; `completed_at` artık `complete-step` üzerinden sunucuda yazılıyor (canlı doğrulandı). Yetki bilerek **sütun bazlı** — tabloya tam update vermek, istemcinin sunucunun ürettiği `block_ids`/`slot_copy`yi değiştirebilmesi demekti. Uygulanana kadar oturum çalışır, yalnızca ilerleme kaydı düşer.

`Config/Info.plist` bu yüzden var: `INFOPLIST_KEY_UIBackgroundModes` diye bir build ayarı yok, Xcode'un üreteci o anahtarı tanımıyor. Dosya yalnızca `UIBackgroundModes` taşır; kalan anahtarların tamamı hâlâ `GENERATE_INFOPLIST_FILE` ile üretiliyor.

### Geliştirme: onboarding ileri sarılabilir (yalnızca DEBUG)

`OnboardingDebugSkip.swift` en dışta `#if DEBUG`; Release derlemesinde hiç yok.

- Kabuğun sağ üstündeki ileri sarma düğmesi taslağı örnek cevaplarla doldurup seçilen adıma atlar.
- `-patika-debug-session-speed 40` oturumu 40 kat hızlandırır (sahnelerin sırası ve oranları aynı kalır, yalnızca saat hızlanır). On dakikalık bir oturumu her denemede baştan dinlemek G1/G2 üzerinde çalışmayı durduruyordu.
- `-patika-debug-step f1|f2|g1|g2|h1|d1|e1|...` başlatma argümanı **her çalıştırmada** o ekranda açar. Xcode şemasına yazılabilir; simülatörde: `xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp -patika-debug-step g1`.
- Örnek ölçüm cevapları `MeasurementLibrary`den türetilir, elle yazılmaz — madde listesi değişince sessizce eksik cevap üretmesin.

> **Simülatör tuzağı:** `simctl uninstall` sonrası `cfprefsd` eski `UserDefaults` değerlerini yeni kuruluma servis etmeye devam ediyor; onboarding tamamlanmış görünüp uygulama doğrudan `RootView` açılıyor. Gerçekten sıfırdan denemek için `xcrun simctl erase <udid>` gerekiyor.

**Onboarding durumu:** A bölümü (A1 kanca + A2 kategori seçimi), **B bölümü (B1–B6 problem keşfi)**, **C bölümü (C1–C4 yansıtma)**, **D bölümü (D0 giriş + D1–D8 baseline ölçüm)** **E bölümü (E1–E3 tercihler)** ve **F bölümü (F1 üretim + F2 yol haritası)** çalışıyor; canlı palet geçişi, ruh hâline göre renk kayması, kategoriye göre placeholder rotasyonu, B5'in koşullu terapi notu, C3'ün koşullu atlanması, cümle cümle beliren C metinleri, C3'ün iki sütunu, C4'ün kompakt grafiği, D bölümünün sekiz sorusu, isimli hitap, E1'in önerilen saati, F1'in işaretlenen izi ve F2'nin yol haritası simülatörde doğrulandı. A2'de 10 seçeneğin tamamı varsayılan metin boyutunda kaydırmasız görünür; `ScrollView` yalnızca büyük Dynamic Type boyutlarında devreye girer. A1'de kelime markası yok — marka kimliği yol animasyonunun kendisi olacak. H bölümünün kalanı (H2, H3) yazılmadı; `OnboardingStep.g1FirstSession` ve `g2SessionComplete` çalışıyor (yukarıya bak); H bölümünde yalnızca H1 var, H2 (bildirim ön hazırlığı) ve H3 yazılmadı. **F4 (fiyat şeffaflığı) yersiz kaldı** — aşağıya bak.

B bölümünün ürün kuralları enum'lara gömüldü: `ProblemTiming.suggestedReminderHour` (B3 → E1 varsayılan saati), `PreviousAttempt.showsLibraryComparison` (C3'ün koşulu), `PreviousAttempt.requiresTherapyAwareTone` (terapi tonu), `PreviousAttempt.isExclusive` ("Hiçbir şey" çelişkisi), `MoodLevel.suggestsGentlerStart`. Ekranlar bu kararları `if` ile hesaplamaz.

B2/B3/B6 tek seçimliktir ama **dokunmak cevap değil, seçimdir**: seçim yapılınca alttaki "Devam" butonu etkinleşir, akış kendi başına ilerlemez (`SingleChoiceStepViewModel`; `select` seçer, `submit` işler ve ilerletir).

Bu bir düzeltmedir (ürün sahibi kararı, 2026-09-08) — önceden dokunmak doğrudan ilerletiyordu. Üç gerekçe: (1) yanlış dokunan kullanıcı kendini bir sonraki ekranda buluyordu, geri alma yolu geri butonuydu; (2) B6'da seçim arka plan rengini değiştiriyor ve otomatik ilerleme bu tepkiyi görmeye zaman bırakmıyordu; (3) A2 ve B1'de zaten buton varken B2/B3/B6'da olmaması akışı iki farklı etkileşim modeline bölüyordu.

B2/B3'te ayrı "geç" bağlantısı yok: "Emin değilim" zaten dürüst bir cevap. Ama **buton satırının yeri her ekranda ayrılır** (`OnboardingQuestionFooter`, ikincil satır boşken `Color.clear` ile) — yoksa birincil buton "geç" bağlantısı olan ve olmayan ekranlar arasında zıplıyordu. `EmptyView` bu işe yaramaz, çerçeve değiştiricilerini yok sayar.

**Kriz sınıflandırıcısı — hâlâ bloklayıcı eksik.** `CrisisClassifier` cihazda çalışan bir **ön filtre**: anahtar ifade taraması + Türkçe küçük harf ve aksansız yazım normalizasyonu (`ı`/`ş`/`ö` elle ASCII'ye eşlenir; `folding(.diacriticInsensitive)` "ı" için garanti değil). İma, mecaz ve yazım hatası yakalamaz. Eşik bilerek gevşek: yanlış pozitifin bedeli yardım ekranını görmek, yanlış negatifin bedeli kriz sinyali vermiş birine program satmak. B1 **ve B4** çıkışında çalışır (ikisi de serbest metin). Path üretimi eklendiğinde metin sunucuda yeniden değerlendirilmelidir.

Serbest metin alanlarında **otomatik düzeltme kapalı** (`OnboardingTextInput`): kullanıcının kelimeleri F2'de geri yansıtılıp G1'de seslendirilecek, düzeltilmiş cümle onun cümlesi değil. Karakter sayacı da yok — yazmayı ödeve çevirir.

**A1 ekran sayısı — çözülen çelişki:** PRD §7.1 "3 karşılama ekranı" diyor, PRD-Ek Onboarding §2.1 ise tek animasyonlu ekran tarif edip kaydırmalı özellik karuselini açıkça yasaklıyor. **Ek uygulandı** (daha detaylı ve gerekçeli spec). PRD §7.1'in güncellenmesi gerekiyor.

**Blok kütüphanesi artık sunucuda.** `supabase/migrations/20260909130000_*` tabloyu, `...130100_seed_blocks_tr.sql` on Türkçe bloğu kuruyor. `script` üç tipten oluşur: `fixed` (insan yazımı, önceden render, oturumun ~%70'i), `silence` (TTS'e hiç gitmez, istemcide zamanlanır), `slot` (LLM'in dokunabildiği tek yer).

- **Sessizlik saniye değil nefes döngüsü sayar** (`breaths`) — saniyeyle yazılan sessizlik 10 saniyelik döngünün ortasında bitip sesi nefes verme evresine sokuyordu.
- **Bloğun kendi nefes ritmi olabilir** (`breath_pattern`). Kutu nefesi 4-4-4-4; arka plan varsayılan 4/0.5/5.5 ile solurken bunu anlatmak kullanıcıyı iki ritim arasında bırakıyordu. Blok kendi ritmini getiriyorsa arka plan o süre boyunca ona geçer.
- ⚠️ **Seed metinleri klinik gözden geçirmeden geçmedi** (`reviewed_at` null, bilerek). PRD-Ek Path Üretimi §2.3 bunu süreç kuralı sayıyor. Yayından önce `select * from public.unreviewed_blocks` **boş dönmeli**.

**TTS artık aracısız ElevenLabs v3.** `_shared/tts.ts`. fal.ai kuyruğu, webhook fonksiyonu ve imza doğrulaması **tamamen kaldırıldı**: doğrudan çağrı senkron, ses gövdede dönüyor.

- **Standart uç nokta** (`api.elevenlabs.io`). Tasarım AB uç noktasını varsayıyordu ama **veri ikametgâhı ElevenLabs'te Enterprise özelliği** (ölçüldü, 2026-09-09) ve ürün kullandığın kadar öde modelinde ilerliyor (ürün sahibi kararı). TTS'e giden metin kullanıcının kendi cümlesini içeriyor → GDPR Madde 9 sağlık verisi; standart uç noktada bu veri AB dışına çıkıyor, yani **DPA + SCC ve gizlilik metninde açık bir satır zorunlu**. `ELEVENLABS_BASE_URL` ile AB'ye dönmek tek secret'lık iş. Aracı yine yok — zincirde tek işleyici var, değişen yalnızca bölge.
- **Model `eleven_v3`**: multilingual_v2 ile aynı fiyat, daha iyi ve `language_code` destekliyor (v2 desteklemiyor).
- **Kişisel ses slot başına** üretilir, adım başına tek dosya değil — slotlar sabit blok parçalarıyla iç içe çalıyor. Komşu metinler `previous_text`/`next_text` ile gönderiliyor (request stitching): parça sınırlarındaki ton sıçraması böyle engelleniyor.
- **Blok sesi ayrı ve paylaşılan** (`block_audio` tablosu + açık `block_audio` kovası): kişisel veri içermiyor, bir kez render ediliyor, imzasız ve CDN'lenebilir. Kullanıcının cümlesi oraya hiç girmiyor.
- **Ses etiketleri (`[whispers]` gibi) varsayılan kapalı.** ElevenLabs kendi dokümanında etiket etkinliğinin sese göre değiştiğini söylüyor ve `[meditative]` belgelenmiş bir etiket değil — model belgelenmemiş etiketi **sesli okuyabilir**, yani meditasyonun ortasında duyulacak bir hata. Etiket blok başına opsiyonel alan (`blocks.audio_tag`); tempo asıl olarak noktalamayla (üç nokta duraklama üretir) ve bizim kendi sessizlik enjeksiyonumuzla kuruluyor.

**E4 — rehber sesi.** PRD'de yok, sonradan eklendi (ürün sahibi kararı, 2026-09-09). "Nasıl bir ses istersin" diye sıfat saydırmıyor; iki örneği dinletip seçtiriyor — sıfatın nasıl duyulduğunu kullanıcı bilmiyor. Önceden seçim yok. Örnekler uygulama paketinde (`scripts/render-voice-previews.sh` üretir), sunucudakiyle **birebir aynı ayarlarla** render edilir.

**Dil: `AppLocale`.** Varsayılan İngilizce, cihaz dili ya da bölgesi Türkçe/TR ise Türkçe. **Yalnızca sesin ve blok metinlerinin dilini** belirler — arayüz metinleri hâlâ `Copy.swift` içinde sabit Türkçe, arayüz yerelleştirmesi String Catalog ile ayrı iş.

**Anahtarlar ve gizlilik.** `AppConfiguration.live` içindeki iki değer bilinçli olarak istemcide: Supabase **publishable** anahtarı ve PostHog **project token**'ı. İkisi de kimlik doğrulaması değil, hangi projeye konuşulduğunun adresi; güvenlik sınırı RLS ve kimlik doğrulamalı Edge Function'lar. Gerçek sırlar (`SUPABASE_SECRET_KEY`, `GEMINI_API_KEY`, `ELEVENLABS_API_KEY`) yalnızca sunucuda, `supabase secrets set` ile durur ve depoda hiç geçmez. `.gitignore` bunu koruyor.

**Henüz yok:** test hedefi (Xcode'dan eklenmeli; kontrast doğrulama testi, `BannedPhrases` lint'i ve `CrisisClassifier` vaka tablosu oraya gider), String Catalog, ses motoru, ağ katmanı, **sunucu tarafı kriz sınıflandırıcısı**.

Test hedefi olmadığı için `CrisisClassifier` şimdilik elle doğrulanıyor: dosya UIKit/SwiftUI'a bağımlı değil, `swift CrisisClassifier.swift <vaka-dosyası>` ile doğrudan koşturulabilir. Bu geçici — vaka tablosu test hedefi eklenince oraya taşınmalı.

### Onboarding sonrası oturum: "Yolum" sekmesi çalışıyor

`MyApp/Features/Path/`. Onboarding sonrası günlük adım G1 ile **aynı motoru**
kullanıyor: `SessionRunner` (sahne saati, duraklatma, yarıda bırakma),
`SessionScript` (sahneleri kuran saf kurallar), `SessionStageView` (ekran),
`SessionAudioPlayer` (manifest zaman çizelgesi). İkinci bir oturum ekranı
yazmak, ilkinin düzeltilmiş hatalarını miras almadan yeni hatalar üretiyordu.

- **Kişisel soru yalnızca `personalized` patikada.** `AdaptiveQuestionView` hem
  G2'de hem "Yolum"da aynı bileşen; hazır patikada ekran soruyu **hiç
  çizmiyor** ve sunucu da cevabı kabul etmiyor. İki katman da aynı sınırı
  koruyor çünkü tek katman koruyan bir kural, kural değil.
- **Streak/seri yok, kaçırılan gün için tek kelime yok.** Ekranda iz, adımlar ve
  sıradaki adımın butonu var; ölçüm günleri halkalı düğüm (yıldız değil).
- **Harita kişisel path'in kendisidir.** Başlıklar ve teknikler gerçek
  `ActivePath`/`PathStepRecord` verisinden gelir; arayüz örnek veya rastgele adım
  yazmaz. Gelecek adımların başlıkları görünür fakat kilitli ve etkileşimsizdir;
  kesikli iz + kilit simgesi durumu rengin tek başına anlatmasını engeller.
- **F2 ve "Yolum" ortak `JourneyMapRow` kullanır.** Normal boyutta rota iki
  kolonda faza göre farklı, deterministik bir ritimle kıvrılır; faz eşiklerinde
  çizgi gerçekten açılır ve küçük faz etiketi bu aralığa oturur. AX Dynamic
  Type'ta metne yer açmak için düz sol raya dönüşür. İlk görünüş çizimi 800 ms
  altında, aktif düğüm yalnızca grafik overlay'inde 60 Hz zaman çizelgesi üstünde
  nefes ritmindedir; metin ve kartlar her kare yeniden çizilmez. Düşük güç,
  termal baskı, arka plan ve Reduce Motion'da sürekli hareket durur.
- **Tamamlama sunucu gerçeğine bağlıdır.** Oturumdan dönüşte harita yükleme
  ekranına sıçramadan aynı satır yerinde kalır; sunucuda ilk kez `completed_at`
  görüldüğünde aktif düğüm onay düğümüne kısa bir geçiş ve tek yumuşak haptikle
  dönüşür. İstemci süre doldu diye tamamlanma uydurmaz.
- **Kesinti oturumu bitirmiyor.** Telefon görüşmesi, kulaklığın çıkması ve
  uygulamanın kapanması kaldığı yeri saniyesiyle saklıyor; dönüşte cümlenin
  ortasından devam ediyor (`scheduleSegment`). Kesinti bitince ses
  **kendiliğinden** başlamıyor — kullanıcı sürdürüyor.
- **Ağ hataları path'i ikinci kez ürettirmiyor.** `RetryPolicy` aynı idempotency
  anahtarıyla en fazla üç deneme yapıyor; tükenirse sunucudaki aktif path
  okunuyor (`generatePathWithReconciliation`). -1005 mobilde sıradan bir olay ve
  yeni bir anahtar ikinci bir LLM + TTS faturası demekti.

### Sunucu durumu — 2026-09-09 canlı doğrulama

Beş Edge Function dağıtık (`generate-path` v6, `generate-audio` v5,
`process-audio-jobs`, `render-shared-audio`, `complete-step`), migrasyonlar
uygulanmış ve migrasyon defteri onarılmış durumda. Anonim kullanıcıyla ölçüldü:
TR path 3 sn'de 21 adım (`kind=personalized`, soru üretiliyor), `complete-step`
cevabı şifreleyip yalnızca 2. adımı kişiselleştirip kuyruğa alıyor, EN path
`breath.awareness.en.v1` bloğunu ve İngilizce metni kullanıyor, kriz cevabı
`status=crisis` döndürüp adımı tamamlamıyor ve sonraki adımı kuyruğa **almıyor**.

> **Tek engel: ElevenLabs anahtarı geçersiz.** Supabase'te duran
> `ELEVENLABS_API_KEY` sağlayıcı tarafından reddediliyor
> (`tts_request_failed_400_invalid_api_key`, ölçüldü). Dört ses örneği, sabit
> blok sesleri ve G1'de duyulan gerçek ses buna bağlı; kodda başka bir eksik yok.
> `fal-webhook` fonksiyonu silindi (2026-09-09); fal.ai zincirden tamamen çıktı.

## Doküman haritası — kod yazmadan önce oku

| Doküman | Ne zaman gerekli |
|---|---|
| `docs/PRD.md` | Her şeyin kaynağı. Ölçüm sistemi (§8), path mimarisi (§9), kriz protokolü (§11), fiyatlandırma (§12), teknik stack (§13), karar günlüğü (§19) |
| `docs/PRD-Ek-Onboarding.md` | 31 ekranlık onboarding akışı, ekran ekran metinler, funnel hedefleri, segmentasyon |
| `docs/PRD-Ek-Ton-ve-Nudge.md` | Tüm kullanıcıya görünen metinlerin tonu, mikrometin kütüphanesi, bildirim kuralları, erişilebilirlik |
| `docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md` | MeshGradient + Metal shader kodu, 10 kategori paleti, nefes animasyonu, Rive brief'leri, görsel prompt'ları |
| `docs/PRD-Ek-Oturum-Motoru-ve-JIT.md` | **Oturum çalarken zorunlu.** Blok `script` şeması (fixed/silence/slot), doğal akış kuralları K1–K6, ses seviyesi ve veri ikametgâhı kararı, sesle senkron arka plan (`voiceEnergy`), kademeli üretimin düzeltilmiş modeli, adım sonu sorusu |
| `docs/PRD-Ek-Profil-Sayfasi.md` | "Ben" sekmesi tasarımı. Ahead/Fabulous/Ladder/Yazio profil ekranlarından ne alındığı ve **ne alınmadığı**, önerilen yerleşim, önce gereken veri katmanı. **Taslak — onay bekliyor.** |
| `docs/PRD-Ek-Path-Uretimi-ve-AI.md` | **Backend/AI çalışırken zorunlu.** Path üretim hattı adım adım, blok kütüphanesi ve slot şeması, LLM/TTS sağlayıcı karşılaştırmaları, kişiselleştirme kademeleri, JIT üretim, üç uçtan uca vaka (söylenen cümleler + kuruş kuruş maliyet), kohort ekonomisi, gizlilik sınırları |

Her dokümanın sonunda bir **karar günlüğü** var: bir tasarım kararını değiştirmeyi düşünüyorsan önce oradaki gerekçeyi oku. Bu kararların çoğu estetik değil, etik veya ticari.

## Mimari — birden çok dokümanı okumadan anlaşılmayan kısımlar

### Path üretimi: AI seçer, icat etmez
Kullanıcı girdisi → sınıflandırma → **kriz kontrolü (bloklayıcı)** → path şablonu seçimi → ~40 bloklu kütüphaneden blok seçimi + sıralama → kişiselleştirme katmanı → çıktı güvenlik kontrolü → ses üretimi. LLM serbest içerik üretmez; onaylanmış tekniklerden oluşan bloklardan seçim yapar. Gerekçe: kalite tutarlılığı, fiyatlanabilirlik, güvenlik (PRD §9.1).

**Ayrıntı `docs/PRD-Ek-Path-Uretimi-ve-AI.md`'de** — backend veya AI tarafında çalışılacaksa okunması zorunlu. Özeti:

- **LLM'in çıktısı metin değil, plandır.** JSON şeması sabit; serbest metin yalnızca adlandırılmış ve karakter sınırlı slotlarda. `block_ids` şemada `enum` — model var olmayan blok uyduramaz.
- **Kişiselleştirme "çerçevede", teknikte değil.** Açılış, geçişler, örnekler ve kapanış kullanıcıya özel (oturumun ~%53'ü); nefes sayımı ve body scan sırası sabit. Gerekçe: "dörde kadar say"ın kişiselleştirilmiş versiyonu yok — sıfır algılanan değer, iki kat TTS maliyeti.
- **Maliyetin %92–98'i TTS, %2–8'i LLM.** Optimizasyon eforu TTS'e gider; LLM sağlayıcısını parçalamak path başına ~$0.003 kazandırıp ikinci bir SDK/DPA/hata yüzeyi getirir.
- **JIT üretim:** F1'de yalnızca planın tamamı + **1. adımın sesi** üretilir; sonraki günler bir adım önden, 8–21. adımlar ödeme sonrası. Ücretsiz penceredeki üretimin ~%43'ü aksi hâlde boşa gidiyor.
- **Sekiz adımın üçünde AI yok** ve bu bilinçli: ölçüm skorlaması, kova ataması (A/B/C) ve path uzunluğu deterministiktir. Bunlar sözleşme, model takdiri değil — "Kova C'de satış yok" taahhüdü kovayı bir modelin belirlediği üründe anlamsızdır.
- **Kriz sinyali tek yönlüdür:** yükseltilebilir, indirilemez. İstemci ön filtresi sinyal verdiyse sunucu modeli bunu geri alamaz. Modelin `stop_reason == "refusal"` dönmesi de sinyal sayılır.
- **Model rolleri sağlayıcıdan bağımsız yazılır:** "güçlü LLM" (üretim) ve "ucuz LLM" (sınıflandırma/kriz/yargıç). Birinci tercih `claude-opus-5` + `claude-haiku-4-5`; Gemini ve GPT eşdeğerleri dokümanda tabloda. Üretim çağrısı bir arayüz arkasında durur — gerekçe fiyat değil risk.
- **TTS sağlayıcısı henüz seçilmedi ve bu her şeyi bloke ediyor:** COGS'u 4–6× değiştiren tek karar, ses kimliğini kilitliyor ve kütüphane render'ını başlatıyor. Türkçe kör testi (dokümanda §5.4) yol haritasının ilk maddesi.
- **Ham metnin gittiği yerler sayılıdır** (dokümanda tam liste). PRD §13.5 "LLM'e ham metin gitmez" diyor ama G1'in aha momenti tam olarak kullanıcının kendi cümlesi; bu gerilim dokümanda açıkça çözülüyor ve PRD güncellenmeli.
- **Prompt cache mimarinin parçası:** blok kütüphanesi meta verisi sabit prefix. `usage.cache_read_input_tokens` panoda izlenmeli — sessizce bozulur ve faturayı büyütür.

### Hibrit ses mimarisi (marjın tamamı buna bağlı)
Oturumun ~%70'i önceden render edilmiş blok sesi; sadece açılış ve kişiselleştirilmiş 2–3 dakika taze TTS. Sessizlik TTS ile üretilmez, istemcide `scheduleBuffer` ile enjekte edilir. Naif yaklaşım path başına €3–10, hibrit €0.75–1.15. `AVAudioEngine` + iki `AVAudioPlayerNode` → `AVAudioMixerNode`; `.playback` kategorisi + `UIBackgroundModes: audio`; `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`. Ses modeli/voice ID **sabittir** — değiştirmek tüm kütüphaneyi yeniden render ettirir.

Bunun doğrudan sonucu: **hazır blokları kaliteli, taze slotları hızlı modelle üretmek yapılamaz** — iki model arasındaki dikiş duyulur ve tam da aha momentinde duyulur. 2026-09-09 ürün sahibi kararıyla sabit ve kişisel konuşmanın ikisi de doğrudan ElevenLabs EU uç noktasında `eleven_v3` kullanır; gecikme JIT kuyrukla gizlenir, flash/turbo ailesi kullanılmaz. Audio tag'ler LLM'in serbest metni değildir: sunucudaki sürümlü allowlist yalnızca dinleme testinden geçen belgelenmiş etiketleri semantik prosody rollerine eşler. SSML sessizliği yoktur; sessizlik istemci zaman çizelgesindedir.

### Uyarlanabilir TTS oturum motoru — onaylı tasarım (2026-09-09)

Kaynak sözleşme: `docs/superpowers/specs/2026-09-09-adaptive-tts-session-engine-design.md`.

- `program_paths.kind` iki değerdir: `personalized` ve `prepared`. Onboarding path'i `personalized`dır.
- Oturum sonu kişisel soru, şifreli cevap ve cevabın N+1 çerçevesini değiştirmesi **yalnızca kişiselleştirilmiş path'te** vardır. Hazır path'te istemci soruyu çizmez, sunucu cevap/personalization isteğini kabul etmez ve Gemini ya da kişisel TTS çağırmaz.
- F1 bütün path'in hafif iskeletini ve yalnızca ilk oturumu hazırlar. N oynarken N+1'in sabit gövdesi hazırlanır; G2 cevabından sonra yalnızca kısa kişisel çerçeve üretilir.
- Ses üretimi mobil isteği açık tutan dört senkron çağrı değildir. Kalıcı job + Supabase PGMQ kuyruğu, görünürlük süresi, aynı rendition hash ile kısmi devam ve idempotent reconciliation kullanır.
- E4 soyut sıfat veya cinsiyet sormaz: `Ses A` / `Ses B` gerçek örneğini dinletir, önceden seçim yoktur. İki ses × TR/EN dört örnek oturumla aynı ayarlardan üretilip pakete gömülür.
- Dil cihaz dili Türkçe veya bölge TR ise Türkçe, aksi hâlde İngilizcedir. Yeni path/session dilimi arayüz, ekrandaki cue ve TTS'te aynı locale'i kullanır.
- Kişiselleştirme maliyet politikası: ilk oturum daha yoğun; devamında B+ (açılış + en fazla bir köprü + kapanış). Teknik gövde sabit ve amortizedir.
- `AVAudioEngine` manifest sırasını çalar; bağlı konuşmalar arası 250–350 ms, gerçek sessizlik yalnızca kullanıcı bir şey yapıyorsa. Ses enerjisi 50 ms RMS, 80 ms attack / 450 ms release ile yumuşatılır ve mesh'e en fazla 0.03 konum / %4 parlaklık ekler. Taban hareketi durmaz; Reduce Motion'da ses tepkisi kapanır.
- İngilizce bloklar mühendislik tarafından `reviewed_at = null` taslak olarak eklenebilir; insan incelemesi olmadan yayına hazır sayılmaz.

### Ölçüm skorlaması yazıldı — `MeasurementScoring`

`MyApp/Models/MeasurementScoring.swift`. Deterministik, model yok: PRD-Ek Path Üretimi'ndeki sekiz adımın üçünde AI olmaması bilinçli — "Kova C'de satış yok" taahhüdü, kovayı bir modelin belirlediği üründe anlamsız olurdu.

- **Yön: 0…100 ve düşük iyidir.** Skor bir başarı puanı değil, zorlanma ölçüsü. `MeasurementItem.higherMeansBetter` olan maddelerde eksen çevriliyor — bu bayrağı ilk kez okuyan yer burası.
- **Cevap tavanı maddeden okunur, elle yazılmaz** (`maximumRawValue`). Bu, gerçek bir hatayı ortaya çıkardı: sunucudaki `calculateScores` tavanı "intensity ise 10, değilse 4" diye tahmin ediyordu, oysa davranış maddelerinin çoğu **dört kovalı (0–3)**. En kötü cevabı veren kullanıcı 100 yerine 75 puan alıyordu — zorlanma sistematik olarak düşük ölçülüyordu. Sunucu `_shared/measurement.ts` ile düzeltildi; **dağıtılması gerekiyor** (`supabase functions deploy generate-path`).
- **Cevapsız madde sıfır sayılmaz**, atlanır ve kalan katmanların ağırlığı normalize edilir. Sıfır saymak eksik ölçümü yapay olarak iyi gösterirdi.
- **Baseline ilk iki ölçümün ortalaması** (PRD §8). Tek nokta varsa karşılaştırma yine yapılır ama `baselineIsProvisional` ile işaretlenir — ortalamaya dönüş etkisi kullanıcıya sonuç diye satılamaz.
- **Yön eşiği aracın kendi çözünürlüğü.** Gürültü tahmini üretecek veri yok (Faz 0 yok), o yüzden uydurma bir sabit yerine "katmanda ölçülebilen en küçük değişim" eşik alınıyor (duygu 5 puan, öz-yeterlik 12.5 puan). **Geçici**: Faz 0'da art arda iki günün oynaklığı görülünce gerçek gürültü tabanı yazılmalı.
- **Kova ataması muhafazakâr.** Eşikler `OutcomeBucket` dokümantasyonundan (Faz 0'da kalibre edilecek tahminler). İki yerde bilinçli olarak sıkı taraf seçiliyor: (1) herhangi bir katmanda kötüleşme varsa diğerleri ne kadar iyileşirse iyileşsin Kova C; (2) kural metnindeki %5–10 boşluğu C'ye yuvarlanıyor — Kova C satış yapılmayan kova olduğu için belirsizliğin bedelini şirket ödüyor, kullanıcı değil.

Vaka tablosu `Tests/MeasurementScoringTests/main.swift`. Test hedefi olmadığı için elle koşuluyor — **`swift` betik kipi çok dosyayla çalışmıyor**, derlemek gerekiyor:

```bash
swiftc -o /tmp/mstest MyApp/Content/Tone.swift MyApp/Models/DomainEnums.swift   MyApp/Models/MeasurementLibrary.swift MyApp/Models/MeasurementScoring.swift   Tests/MeasurementScoringTests/main.swift && /tmp/mstest
```

> **Sürüklenme riski duruyor.** İstemci ve sunucu aynı hesabı iki ayrı yerde yapıyor; madde kütüphanesi istemcide (Türkçe metinleriyle), sunucuda yalnızca tavan/yön tablosu var. Bir madde eklendiğinde iki taraf da güncellenmeli. Kalıcı çözüm skorlamanın tek yerde kalması; o karar ölçüm servisi sunucuya taşınırken verilecek.

### Ölçüm sistemi
Klinik ölçek (GAD-7, PHQ-9) **kullanılmaz** — lisans + tıbbi cihaz düzenlemesi riski. Kendi ölçeğimiz üç katmanlı: duygu şiddeti %30, **davranış %40** (en sağlam, en zor manipüle edilir), öz-yeterlik %30. Dört ölçüm noktası (baseline / gün 7 / gün 14 / son), her noktada **madde rotasyonu** (A/B/C varyantları — aynı skorlama, farklı ifade). Skorlar asla mutlak yorumlanmaz, sadece kullanıcının kendi geçmişiyle karşılaştırılır. Baseline tek nokta değil, ilk 2 günün ortalaması (ortalamaya dönüş etkisi).

### Görsel sistem: video değil shader
Uygulama içi arka planların tamamı `MeshGradient` (iOS 18+) + tek bir Metal `colorEffect` shader'ı (grain + metin güvenli bölge scrim'i). Toplam görsel varlık < 60 KB. 10 kategori paleti, iki seçim harmanlanabilir → 55 kombinasyon, hepsi renk dizisini `withAnimation` içinde değiştirmekle çalışır.

Üç tuzak (üretimde başını ağrıtır): (1) **kenar noktaları birim karenin kenarında kalır** — kendi kenarları boyunca kayabilirler ama içeri çekilirse gradyanın bittiği yerde görünür kesim oluşur; (2) `colorSpace: .perceptual` ve `smoothsColors: true` **açıkça yazılır** (iOS 18'de opt-in); (3) uygulama `.preferredColorScheme(.dark)` ile koyu moda sabittir, `Color` yerine sabit RGB kullanılır.

Nefes döngüsü 10 sn (4 al / 0.5 tut / 5.5 ver) tek bir `breathValue(at:) -> Double` fonksiyonundan beslenir; ekran grubuna göre genlik değişir (oturum ekranı %100, ölçüm %35, kriz ekranı **%0**).

Arka plan **akar, durmaz** ve akışı kapanmaz. Merkez + dört kenar ortası noktası birden gezinir; her nokta **iki ayrı sinüsün toplamıyla** sürülür (ürün sahibi kararı, 2026-09-09). Tek sinüs noktayı bir elips üzerinde gezdiriyordu ve birkaç saniyede yörünge öğrenilip hareket "döngüye girmiş animasyon" gibi okunuyordu; iki sinüsün oranı tam sayı olmadığı için toplamları pratikte hiç tekrar etmiyor — hareket rastgele hissediliyor ama tamamen deterministik ve sınırlı. Grain de her karede yeniden atılmıyor, saniyede birkaç piksel **süzülüyor**; kaynayan doku hem yorucuydu hem yönsüz olduğu için akış hissi vermiyordu. Grain bandı ayrıca %35 yukarı taşındı (0.040–0.061): görünür doku, gradyanı "dijital degrade" olmaktan çıkarıp basılı bir yüzeye yaklaştırıyor ve mesh'in bantlaşmasını örtüyor.

Kenar ortası noktaları kendi kenarları boyunca kayar; sabit koordinatları (0 ve 1) **asla** değişmez — §6.5 tuzak #1 hâlâ geçerli. Genlik tavanı pratikte 0.13: üstüne çıkınca mesh bükülüp gradyanın yumuşaklığı bozuluyor.

> Kontrast testi yazıldığında **tek kare yetmez**: arka plan artık gözle görülür şekilde hareket ettiği için metin bandındaki en parlak an başka bir `t` değerinde olabilir. Test döngü boyunca birkaç zaman noktası örneklemeli.

Palet üç katmanda hesaplanır ve **sıra önemlidir**: kategori (A2 seçimi, iki seçim harmanlanabilir) → ruh hâli (B6 kademesi) → gece modu. Gece en sonda çünkü mutlak bir tavan koyuyor.

Ruh hâli katmanı paleti **sarı ↔ lacivert** ekseninde kaydırır (ürün sahibi kararı, 2026-09-08; Görsel Sistem eki §3.4): en ağır kademede lacivert, en sakin kademede sıcak sarı, ortada tonlama yok. Ağır kademede ekran ayrıca kısılır ve yavaşlar — kötü hissedene ekranı parlatıp hızlandırmak "neşelen" demenin görsel karşılığı olurdu.

**Kontrast bu tonlamadan etkilenmez ve bu tesadüf değil.** Karışım koyu bir rengi sarıya çekerken kaçınılmaz olarak açar. O yüzden her renk noktası karıştırıldıktan sonra `RGB.withLuminance` ile hedef luminansa geri taşınır (gamma açılmış uzayda, kanal ölçekleyerek) ve hedef paletin mevcut en parlak noktasını aşamaz; arka plan hiçbir kademede açılmaz. Kontrast yalnızca luminansa bağlı olduğu için **ton serbest, luminans kilitli**. Yeni bir ton eklenecekse doygunluğu serbestçe seçilebilir, ama bu kilit kaldırılmamalı.

### Onboarding
33 ekran, ~5 dakika. Omurga: kanca (1) → **kimlik (3)** → ilk soru (1) → problem keşfi (6) → yansıtma (4) → ölçüm (9) → tercihler (3) → üretim/teslim (**2**) → **ilk oturum (2)** → hesap/izin (3). Kimlik bloğu PRD'de yok, sonradan eklendi. Üç yapısal karar: **onboarding'de paywall yok** (yerine fiyat şeffaflığı ekranı F4), **kayıt en sonda** (kullanıcı ilk meditasyonunu dinledikten sonra), **ilk oturum akışın içinde ve kullanıcının kendi cümlesini seslendirir** (aha momenti). Ölçüm bölümü (D1–D8) atlanamayan tek bölümdür.

## Değiştirilemez kurallar

Bunlar tercih değil; ihlal edildiğinde ürün ya etik olarak bozulur ya mağazadan döner.

**Güvenlik**
- Kullanıcının yazdığı **her serbest metin** kriz sınıflandırıcısından geçer. Sinyal varsa akış **durur**: path üretilmez, ölçüm yapılmaz, kayıt istenmez, ekranda hareket yok.
- "Destek al" menüde **her zaman** görünür, **asla** paraya çevrilmez (yönlendirme komisyonu / terapist reklamı yok) ve **asla** ödeme duvarının arkasına konmaz.
- Teşhis yok, ilaç yorumu yok, garanti ("geçecek", "iyileşeceksin") yok, "terapi/tedavi/klinik olarak kanıtlanmış" iddiası yok.
- Kriz anında harita değil, **numara** gösterilir. Yardım hatları ülkeye göre yerelleştirilir (TR/DE/EN).

**Gamification — kategorik olarak yasak**
Streak, can/enerji sistemi, lig/sıralama, kullanıcılar arası kıyaslama, sıfırlanan ilerleme, "seni özledik" bildirimleri, sahte aciliyet/geri sayım, değişken ödül döngüsü. Kaygı ürününde kayıp kaçınması = üretilmiş kaygı. Kaçırılan gün hiçbir şeyi geri almaz; dönüşte tek cümle: *"Buradasın. Kaldığın yerden devam edelim."*

**Ticari**
- Paywall **gün 7'de ve ölçüm ekranından sonra** — asla önce.
- Path sonu üç kovadır (A belirgin / B kısmi / C ilerleme yok); `başarılı/başarısız` dili hiçbir yerde geçmez.
- **Kova C'de satış yapılmaz**, devam patikası ücretsizdir (ömür boyu 2 limit). Bu bir teşvik hizalaması kararıdır, pazarlık konusu değil.
- Geçişlerde indirim yok; aboneliğin farkı ucuzluk değil **süreklilik**.
- Varsayılan yanlılığı (önceden doldurulmuş seçim) **ödeme ve abonelik kararlarında kullanılmaz**.
- Veri yokken sayısal sosyal kanıt yazılmaz. Bu **grafikleri de kapsar**: C4'ün süreç grafiğinde hiçbir eksende sayı yoktur ve yatay eksende yalnızca "Başlangıç" / "21. gün" yazar. Grafik programın yapısını anlatır (sırasız yığında birikme olmaz, sıralı yolda olur), kullanıcının sonucunu değil. Sayılı bir eğri, sayı uydurmama kuralını bir ekran sonra delerdi.
  - "Bu grafik bir sonuç vaadi değil" notları kaldırıldı (ürün sahibi kararı, 2026-09-08). Karar notu değil **grafiği** hedefliyor: C3'ün eğrisi tamamen silinip yerine yan yana iki sütun kondu, C4'ün grafiği kompaktlaştırıldı. Notun işini artık biçimin kendisi yapıyor — sayısız bir sütun karşılaştırması sonuç vaat edemez. Grafiğe sayı geri gelecekse not da geri gelmeli.

**Gizlilik**
- Bildirim metni **asla** path adını veya sorunu içermez ("Sınav kaygısı patikanın 8. adımı" ❌ / "Bugünün adımı hazır" ✅). Kilit ekranına bakan biri kullanıcının neyle uğraştığını öğrenmemeli.
- Ham problem metni şifreli ve ayrı tabloda; LLM'e giden bağlam özettir, ham metin değil.
- Ölçüm verisi ve problem metni **asla** analitik araçlara gönderilmez.
- Sadece push kanalı var — SMS/e-posta ile ruh sağlığı içeriği gönderilmez.
- `UNNotificationInterruptionLevel` her zaman `.active`; `.timeSensitive`/`.critical` ve `.provisional` izin kullanılmaz.
- Günlük hatırlatmalar sunucudan değil, cihazda `UNCalendarNotificationTrigger` ile planlanır.

## Kullanıcıya görünen metin yazarken

Marka sesi: **Sakin · Dürüst · Yanında.** Ünlem neredeyse hiç kullanılmaz.

Ton dört kademelidir ve bir ekranın kademesi **yukarı çıkmaz**: 🔴 Nötr (kriz, Kova C, Destek al, feragat — sıfır süsleme) · 🟠 Sakin (oturum, ölçüm, harita) · 🟡 Sıcak (path sonu A/B, rozet) · 🟢 Oyuncu (Keşfet, nefes, boş durumlar). Şüphe varsa bir kademe aşağı in.

**Ses testi:** Yazdığın cümleyi gece 2'de uyuyamayan ve kendini kötü hisseden birine yüksek sesle söyleyebiliyor musun?

Yasak ifadeler: "Harika iş çıkardın! 🎉", "Seni özledik", "Serini kaybetmek üzeresin", "Sadece 2 gün kaldı!", "Diğer kullanıcılar...", "Endişelenme"/"Sakin ol", "Bunu aşacaksın", "Başarısız". Konfeti, uçuşan emoji, rainbow modu yok.

Buton metinleri standart değil, ürüne özel: Başla → **Yola çık**, Devam et → **Kaldığın yerden**, İptal → **Şimdilik değil**, Atla → **Bugün geç**, Kaydet → **Bende kalsın**, Bitir → **Burada duralım**. Tam liste ve hata/boş durum metinleri: `docs/PRD-Ek-Ton-ve-Nudge.md` §3.

Her hata metninde "kaybolmadı / senin yüzünden değil" ifadesi geçer — kaygılı kullanıcı hatayı otomatik kendine mal eder.

Metinlerin tamamı `String Catalog` + sunucu override ile remote config'ten yönetilir; bir kelime için mağaza incelemesi beklenmez. TR + EN (v1).

## Erişilebilirlik — opsiyonel değil

- `accessibilityReduceMotion`: nefes animasyonu statik daireye, shader hızı 0.
- `accessibilityReduceTransparency`: gradyan yerine düz koyu renk.
- Dynamic Type zorunlu, sabit punto yok; **AX5 boyutunda hiçbir ekran kırılmamalı** (özellikle D1–D8 ve F2).
- Metin arkası kontrastı WCAG AA (büyük başlık 3:1). 55 palet×ekran kombinasyonu elle denetlenemez — `ImageRenderer` ile offscreen render edip luminans ölçen **XCTest kontrast testi CI'da build'i kırar**.
- Ses efektleri varsayılan **kapalı**; haptik tek seviye (`UIImpactFeedbackGenerator(style: .soft)`).
- Tüm animasyonlar 800 ms altı. Arka plan render bütçesi kare başına **2 ms** (Instruments/Metal System Trace).
- Renk tek başına anlam taşımaz — iyileşme/kötüleşme oku + metinle birlikte.

## Stack kararları (PRD §13)

iOS-only SwiftUI native (cross-platform **bilinçli olarak reddedildi** — iş mantığı sunucuda, paylaşılmayan kısım ses motoru + shader, yani RN'in en zayıf yeri) · `AVAudioEngine` · `MeshGradient` + Metal · Rive (opsiyonel; SwiftUI `Path` + `trim` alternatifi var) · SwiftData (yerel) · Node/Python + Postgres (backend) · Sign in with Apple birincil · **StoreKit 2** (RevenueCat opsiyonel; tek platformda ana faydası yok) · PostHog/Amplitude.

Android Faz 4'e ertelendi ve üç koşullu bir karar kapısına bağlandı (D30 ≥%25, LTV > CAC, ayrı kaynak). Kod yazarken backend/blok kütüphanesi/ölçüm mantığı yeniden kullanılabilir kalmalı.

## Faz 0 uyarısı

PRD kendi ifadesiyle **0 kullanıcı görüşmesi ve 0 davranışsal veriyle** yazıldı; içindeki her şey hipotezdir. Faz 0 (10+ problem görüşmesi, elle uygulanan tek bir path, ölçümün gerçekten fark gösterip göstermediği) tamamlanmadan MVP kodlamasına geçilmemesi PRD'nin açık kararıdır. Karar kapısı: elle uygulanan path'te medyan iyileşme %20'nin altındaysa tasarım değişir.

Açık sorular (PRD §18) hâlâ kapanmadı: ürün adı, birincil pazar (TR mi DE/EN mi — fiyatlandırmayı ve ASO'yu değiştirir), ilk path tipi (öneri: uyku), ses kimliği, kova eşikleri, ücretsiz adım sayısı. Bunlara bağlı bir uygulama kararı gerekiyorsa varsayım yapma, kullanıcıya sor.
