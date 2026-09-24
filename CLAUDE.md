# CLAUDE.md

Bu dosya Claude Code'a bu depoda çalışırken rehberlik eder. **Geçmiş kararların
tam gerekçesi ve tarihli günlük `docs/decision-log.md`'de** — bir kararı geri
almayı düşünüyorsan önce orayı kontrol et. Bu dosya yalnızca **güncel durumu**
ve değişmeyen kuralları tutar; tarihli günlük girişleri buraya eklenmez.

## Proje durumu

**Patika** (çalışma adı) — kullanıcının derdini kendi kelimeleriyle anlattığı,
karşılığında 7/14/21/28 günlük **ölçülen ve biten** bir program aldığı iOS
meditasyon/zihinsel iyi oluş uygulaması. Sahibi: Novum Apps.

Bu depoda asıl kaynak kod değil, **ürün spesifikasyonudur** — herhangi bir
özellik yazmadan önce ilgili PRD bölümü okunmalı (bkz. Doküman haritası).

**Çalışan:** onboarding'in tamamı (A1 → identity → A2 → B → C → D → E1 → H2 →
F1 → F2 → commitment → G1 → G2 → price → H1), ilk oturum (G1) ve günlük oturum
("Yolum" sekmesi, aynı motor), "Ben" sekmesi (v2), Keşfet (hazır patikalar v2,
yalnızca İngilizce), path üretimi + JIT ses (ElevenLabs `eleven_v3`, aracısız),
ölçüm skorlaması (istemci + sunucu, deterministik). **Faz 0 hâlâ tamamlanmadı**
(bkz. aşağı) — PRD'deki her şey hipotez.

**Henüz yok:** Xcode test hedefi (testler elle `swiftc` ile derlenip koşuluyor),
String Catalog dışı arayüz metinleri (bkz. altta), RevenueCat/Apple mağaza
hesabı yapılandırması ve gerçek cihaz satın alma doğrulaması, H3, VoiceOver
tam turu, resmî kriz hattı numaralarının doğrulanması. RevenueCatUI satın alma
akışı kodda var; canlı ürün/offering/paywall kurulumu tamamlanmadı.

## Komutlar

Xcode projesi: `patika.xcodeproj` · Tek hedef/şema: **`MyApp`** (ürün adı `patika`).

```bash
# Derle (simulator) — Xcode Localizable.xcstrings'i bozmasın diye SWIFT_EMIT_LOC_STRINGS=NO şart
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  SWIFT_EMIT_LOC_STRINGS=NO build

# Şema/hedef listesi
xcodebuild -list -project patika.xcodeproj

# Simülatörde çalıştır
xcrun simctl boot "iPhone 17 Pro"; open -a Simulator
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'id=<UDID>' -derivedDataPath /tmp/patika-dd SWIFT_EMIT_LOC_STRINGS=NO build
xcrun simctl install booted /tmp/patika-dd/Build/Products/Debug-iphonesimulator/MyApp.app
xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp
xcrun simctl io booted screenshot /tmp/shot.png

# Swift testleri (Xcode test hedefi yok, elle derlenir — bkz. dosya başları için Tests/*/main.swift)
bash scripts/run-swift-tests.sh

# Deno (sunucu) testleri
npx --yes deno test --no-prompt --allow-read --allow-env --allow-net supabase/functions/tests/
```

> **Simülatör tuzağı:** `simctl uninstall` sonrası `cfprefsd` eski `UserDefaults`
> değerlerini servis etmeye devam eder; onboarding tamamlanmış görünebilir.
> Sıfırdan denemek için `xcrun simctl erase <udid>`.

**Deployment target: iOS 26.0** (2026-09-08 kararı, PRD'nin "pazarın ~%95'i"
gerekçesi artık geçerli değil — pazar kapsamı dokümanda yazandan dar).

## Kod yerleşimi

Hedef **file-system synchronized group** kullanır (`PBXFileSystemSynchronizedRootGroup`):
`MyApp/` altına konan her dosya otomatik derlenir. **`.pbxproj` elle düzenlenmez.**

| Klasör | İçerik |
|---|---|
| `MyApp/App/` | `@main` giriş noktası, `RootView` (üç sekme + sabit SOS) |
| `MyApp/DesignSystem/` | `Theme`, guaj sahne/kâğıt bileşenleri, nefes döngüsü yardımcıları |
| `MyApp/Models/` | `DomainEnums`, `PersistentModels` (SwiftData), `MeasurementLibrary`, `MeasurementScoring`, `PathPlan`, `ProfileRecord`/`ProfileSnapshot`, `BadgeCatalog`, `WeeklyRhythm` |
| `MyApp/Content/` | `Copy` (mikrometin ad alanı), `Tone` (kademeler + yasak ifadeler) |
| `MyApp/Content/Localizable.xcstrings` | Metnin **tek** kaynağı (bkz. altta) |
| `MyApp/DesignSystem/Components/` | `DisplayText`/`BodyText`, `PrimaryButton`, `OnboardingHeader`, `PathProgressBar`, `OnboardingQuestionLayout`, `OnboardingStatementLayout`, `ChoiceRow`, `MoodScale`, `IntensityScale`, `OnboardingTextInput`, `TrailRow`, `JourneyMapRow`, `HoldToStartButton` |
| `MyApp/Features/<Özellik>/` | MVVM ekranları: Onboarding (kimlik + A–H), Path (Yolum), Me (Ben), Discover (Keşfet) |
| `assets/illustrations/` | Görsel kaynak dosyaları (uygulamaya giren kopyalar `Assets.xcassets/`) |

## Mimari: MVVM

- **ViewModel** — `@Observable @MainActor final class`. Tüm karar/doğrulama/navigasyon burada. `SwiftUI` import etmez.
- **View** — yalnızca yerleşim ve bağlama; iş kuralını `if`/`switch` ile hesaplamaz, ViewModel'in hazır özelliğini okur.
- **Model** — `Models/` altındaki enum'lar ve SwiftData sınıfları.
- Onboarding'de **akış VM'i tek sahiptir**: `OnboardingFlowViewModel` adım yönlendirmesini, `OnboardingDraft` taslağını ve sahne seçimini tutar. Adım VM'leri ona yazar, birbirini tanımaz.
- `OnboardingDraft` bilerek `struct` ve kalıcı değil — onboarding yarıda kalırsa yarım kayıt kalmaz.

## Görsel sistem: guaj sahneler, gradyan yok (2026-09-22 kararı)

Metal shader / `MeshGradient` / kategori paleti tamamen kaldırıldı — **uygulama
genelinde gradyan yok**. Her bölümün tam ekran bir guaj sahnesi vardır
(`OnboardingArtwork`, `OnboardingSceneLayer`); A2–B6 arası sahne seçilen
kategoriye göre değişir, B6'nın ruh hâli sahne perdesini koyultup açar
(`MoodLevel.sceneDimming`). **Görsel yoksa ekran hiç kırılmaz** — düz
`WoodlandStyle.background`a düşer. `OnboardingSurfaceStyle` iki değerlidir:
`.paper` (krem okuma/cevap yüzeyi) ve `.plain` (sahne cevabın kendisi, A2/B6).
Meditasyon ekranı (`PathSessionView`, G1) de gradyansız: `bg-session` sahnesi +
düz `BreathOrb`, yalnızca `.preparing` fazında görünür.

Nefes döngüsü hâlâ 10 sn (4 al / 0.5 tut / 5.5 ver); genlik ekran grubuna göre
değişir (oturum %100, ölçüm %35, kriz **%0**). Bütün animasyonlar 800 ms altı.

## Emoji yasak

**Hiçbir yerde emoji kullanılmaz** — arayüzde, metinde, kod yorumunda. Yerine
**SF Symbols** (monokrom, Dynamic Type ile büyür, VoiceOver hazır). Kategori
ikonları `ProblemCategory.icon` arkasında. PRD-Ek Onboarding §3.6'nın B6 için
tarif ettiği emoji ölçek uygulanmadı — `MoodLevel` monokrom hava metaforu kullanır.

## Onboarding — güncel kurallar

- **SOS yok.** `OnboardingHeader` yalnızca geri butonu + ilerleme izi taşır;
  kriz yakalaması B1/B4'teki serbest metin sınıflandırıcısıyla yapılıyor. SOS
  onboarding bittikten sonra `RootView`'da sabit.
- **İlerleme sayı değil iz** (`PathProgressBar`). `OnboardingStep.progress` nil
  ise iz solar ama son değerini korur. Uç noktada düğüm yok. İlerleme bölüm
  içidir: soru bölümü = kimlik(3) + A2 + B1–B6 = 10 ekran; D ve E kendi
  ölçekleriyle yeniden başlar.
- **Kabuk kalıcı.** `OnboardingContainerView` arka plan/geri butonu/izi bir kez
  kurar. Geri butonu çıplak `chevron.left`, yuvarlak arka plan yok, her zaman
  yerini korur (`canGoBack` false ise sadece görünmez). Adım geçişi sıralı fade
  (`AnyTransition.onboardingStep`).
- **Klavye/taşma:** footer `safeAreaInset(edge: .bottom)` ile verilir (klavye ve
  footer aynı mekanizmayı paylaşır); arkasında `footerBackdrop` karartması var.
  Tek satırlı alanlarda `return` = "Done"; çok satırlılarda klavye üstü araç
  çubuğu. `CrisisView`, `NotYetBuiltView`, F1 kendi `ScrollView`'larını alır.
- **B2/B3/B6:** dokunmak seçimdir, cevap değil — "Devam" butonuna basmak gerekir
  (otomatik ilerleme yok). Buton satırının yeri her ekranda ayrılır
  (`Color.clear`, `EmptyView` değil).
- **Kimlik 3 ayrı ekran:** `NameView`, `GenderView`, `AgeRangeView`, A1'in
  hemen sonrasında. İsim isteğe bağlı; kullanılan yerler sınırlı (C1, C4) —
  yeni kullanım yeri bilinçli bir karar olmalı. Cinsiyet/yaş hiçbir davranışı
  değiştirmez (bunu ekranda kullanıcıya söyleyen not var).
- **C bölümü** (`OnboardingStatementLayout`) cümle cümle beklemez (2026-09-21'de
  geri alındı); `statementReveal`/`woodlandReveal` (0,045 sn adım, en fazla 5).
  `sequentialReveal` (1,5 sn) yalnızca `PathSessionView`'de kalır.
- **D bölümü (D1–D8):** ölçüm **cevap toplar, skor üretmez** — hiçbir ekranda
  toplam/yorum yok. Cevaplar ham durur (`OnboardingDraft.measurementResponses`).
  Varsayılan cevap yok, atlanamaz. Madde `id`'leri asla değişmez.
- **E bölümü artık yalnızca E1** (hatırlatma saati) — E2 (uzunluk) ve E3 (ton)
  silindi (bkz. decision-log 21/22 Eylül). E1'de varsayılan yanlılık bilinçli
  kullanılır (B3 cevabından önceden dolu saat); bu teknik **ödeme/abonelik
  kararlarında kullanılmaz**.
- **F bölümü:** F1 (üretim, gerçek ağ isteğine bağlı ilerleme, buton yok — iş
  bitince kendi geçer) → F2 (kısa, ekrana sığan özet — otomatik kaydırılan uzun
  harita değil) → **commitment** (imza/işaret, yerel kalır, sunucuya gitmez) →
  G1. F1/F2'de geri yok. "Yola çık" `HoldToStartButton` ile basılı tutulur
  (1.4 sn), kırık beyaz dolgu büyür (gradyan yok).
- **G1/G2:** G1 path'in JIT üretilen 1. adım sesini oynatır, sahneler nefes
  döngüsüyle zamanlanır (saniyeyle değil). Ses eksikse ekran sessiz sürüme
  düşer (hata değil). G2 kutlama şiddeti 1/5; sonuna kadar dinlenmediyse
  "tamam" denmez, kalan adım sayısı yazılmaz. `completed_at` yalnızca tam
  dinlendiğinde sunucuda yazılır.
- **Kriz sınıflandırıcısı bloklayıcı.** `CrisisClassifier` cihazda ön filtre
  (anahtar ifade + TR normalizasyon); B1 ve B4 çıkışında çalışır. Sunucuda
  `_shared/crisis.ts` **aynı ifade kümesi ve normalizasyonu** kullanır
  (`crisis_contract_test.ts` ayrışmayı yakalar). Onsuz onboarding yayına çıkmaz.
- **Serbest metinde otomatik düzeltme kapalı** (kullanıcının cümlesi F2'de
  yansıtılıp G1'de seslendirilir — düzeltilmiş cümle onun cümlesi olmaz).
  Karakter sayacı yok.
- **DEBUG-only ileri sarma:** `OnboardingDebugSkip.swift` (`#if DEBUG`).
  `-patika-debug-step <adım>`, `-patika-debug-session-speed 40`,
  `-patika-debug-tab ben -patika-debug-me v2full|v2badges|v2empty|v2crisis`,
  `-patika-debug-no-art`.

## Path üretimi ve ses — özet

Ayrıntı **zorunlu okuma**: `docs/PRD-Ek-Path-Uretimi-ve-AI.md` (backend/AI
çalışırken), `docs/PRD-Ek-Oturum-Motoru-ve-JIT.md` (oturum çalarken).

- **LLM plan üretir, metin değil.** JSON şeması sabit, `block_ids` enum —
  model var olmayan blok uyduramaz. Kişiselleştirme çerçevede (açılış/geçiş/
  kapanış), teknik (nefes sayımı, body scan sırası) sabit.
- **Maliyetin %92–98'i TTS.** JIT: F1'de yalnızca plan + 1. adımın sesi
  üretilir; sonraki günler bir adım önden.
- **Kriz sinyali tek yönlü** — yükseltilebilir, indirilemez.
- **Hibrit ses:** oturumun ~%70'i önceden render blok sesi (`block_audio`
  tablosu, paylaşılan, kişisel veri yok); açılış + kişiselleştirilmiş 2–3 dk
  taze TTS. Sessizlik TTS ile üretilmez, istemcide zamanlanır
  (`AVAudioEngine` + iki `AVAudioPlayerNode` → `AVAudioMixerNode`,
  `.playback` + `UIBackgroundModes: audio`). Ses modeli/voice ID sabittir.
- **TTS: aracısız ElevenLabs `eleven_v3`**, standart (AB dışı) uç nokta —
  bilinçli karar, veri ikametgâhı gerekiyorsa `ELEVENLABS_BASE_URL` ile AB'ye
  dönülür (DPA/SCC + gizlilik metninde satır gerektirir). Kişisel ses
  slot başına, `previous_text`/`next_text` **göndermez** (v3 desteklemiyor).
- **Seed blok metinleri klinik gözden geçirmeden geçmedi** (`reviewed_at`
  null). Yayından önce `select * from public.unreviewed_blocks` boş dönmeli.
- **Dil:** `AppLocale.current` şu an **sabit İngilizce** (yalnızca İngilizce
  MVP kararı) — ses ve blok metinlerinin dilini belirler, arayüz metinleri
  ayrı bir konu (bkz. altta).
- **Bilinen engel:** Supabase'teki `ELEVENLABS_API_KEY` geçmişte geçersizdi
  (`tts_request_failed_400_invalid_api_key`) — canlıya çıkmadan önce
  doğrulanmalı.

### Ölçüm skorlaması

`MyApp/Models/MeasurementScoring.swift` — deterministik, model yok. 0…100 ve
**düşük iyidir** (zorlanma ölçüsü, `higherMeansBetter` maddelerde eksen
çevrilir). Cevap tavanı maddeden okunur (`maximumRawValue`), elle yazılmaz.
Cevapsız madde sıfır sayılmaz, atlanır. Baseline ilk iki ölçümün ortalaması.
Herhangi bir katmanda kötüleşme varsa Kova C'ye yuvarlanır (muhafazakâr taraf).
Sunucu tarafı `_shared/measurement.ts`te ayrı bir tekrar — **madde eklenince
iki taraf da güncellenmeli**, kalıcı çözüm henüz yok. Vaka tablosu
`Tests/MeasurementScoringTests` (elle derlenir, bkz. dosya başı komutu).

Klinik ölçek (GAD-7, PHQ-9) **kullanılmaz** — lisans/tıbbi cihaz riski. Kendi
ölçeğimiz: duygu %30, davranış %40, öz-yeterlik %30. 4 ölçüm noktası
(baseline/gün7/gün14/son), madde rotasyonu (A/B/C varyant, aynı skorlama).

### Metin kataloğu

Metnin **tek yeri** `MyApp/Content/Localizable.xcstrings` (kaynak dil
İngilizce, tüm kayıtlar `extractionState: manual`). Kodda metin yazılmaz:
`Text(.tabPath)`. `Copy.*` sıfır metinli bir ad alanı ön yüzü. Xcode dışı
testler için sembol örtüsü: `python3 scripts/generate-string-symbol-shim.py`.
`Tests/LocalizationCatalogTests` manuel kayıt/yasaklı ifade/emoji/yer tutucu
tutarlılığını denetler.

> **Tuzak:** Xcode derlemesi `SWIFT_EMIT_LOC_STRINGS=NO` olmadan
> `Localizable.xcstrings`i sessizce bozar (extractionState'siz kayıt ekler,
> dosyayı yeniden biçimlendirir). Bu bayrak olmadan asla derleme.
> `git checkout` ile geri almadan önce HEAD'den sonra eklenen meşru kayıtları
> tek tek karşılaştır (bir keresinde gerçek bir kayıt kazara silinmişti).

## Doküman haritası — kod yazmadan önce oku

| Doküman | Ne zaman gerekli |
|---|---|
| `docs/decision-log.md` | Bir kararı geri almayı düşünüyorsan **önce burayı oku** — tam tarihli gerekçe arşivi |
| `docs/PRD.md` | Her şeyin kaynağı: ölçüm (§8), path mimarisi (§9), kriz protokolü (§11), fiyatlandırma (§12), stack (§13), karar günlüğü (§19) |
| `docs/PRD-Ek-Onboarding.md` | Ekran ekran metinler, funnel hedefleri, segmentasyon (akış sırası güncel değil, bkz. yukarı) |
| `docs/PRD-Ek-Ton-ve-Nudge.md` | Ton, mikrometin, bildirim kuralları, erişilebilirlik |
| `docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md` | **Kısmen geçersiz** (shader/palet kaldırıldı, 2026-09-22) — yalnızca nefes/erişilebilirlik bölümleri geçerli |
| `docs/PRD-Ek-Oturum-Motoru-ve-JIT.md` | Oturum çalarken zorunlu: blok `script` şeması, K1–K6, JIT üretim |
| `docs/profile-design.md` | "Ben" sekmesinde çalışırken zorunlu |
| `docs/PRD-Ek-Path-Uretimi-ve-AI.md` | Backend/AI çalışırken zorunlu |
| `docs/onboarding-redesign.md` | Onboarding'in orman dili + guaj sahne geçişinin planı |

## Değiştirilemez kurallar

Bunlar tercih değil; ihlal edildiğinde ürün etik olarak bozulur ya da mağazadan döner.

**Güvenlik**
- Kullanıcının yazdığı **her serbest metin** kriz sınıflandırıcısından geçer. Sinyal varsa akış **durur**: path üretilmez, ölçüm yapılmaz, kayıt istenmez, ekranda hareket yok.
- "Destek al" menüde **her zaman** görünür, **asla** paraya çevrilmez, **asla** ödeme duvarının arkasına konmaz.
- Teşhis yok, ilaç yorumu yok, garanti yok, "terapi/tedavi/klinik olarak kanıtlanmış" iddiası yok.
- Kriz anında harita değil, **numara** gösterilir (TR/DE/EN).

**Gamification — sınırları çizilmiş serbestlik**
Serbest: kilometre taşı rozetleri (geri alınmaz), nazik haftalık seri, sade
kutlama (native beliriş + tek yumuşak haptik, Lottie yok). Yasak: toplam
sayılar, lig/sıralama/kıyas, sıfırlanan ilerleme, kayıp bildirimi, sahte
aciliyet, can/enerji, değişken ödül döngüsü. Seri kırılınca mesaj yok,
bildirimde seriden söz edilmez; kaçırılan gün dönüşte tek cümle: *"Buradasın.
Kaldığın yerden devam edelim."* Kriz modunda ve Kova C'de rozet/kutlama/seri
görünmez (Kova C'de rozet sessizce rafta belirir, kutlama yaprağı açılmaz).

**Ticari**
- 24 Eylül 2026 ürün sahibi kararı: ilk kişisel oturum tamamlanıp G2 özeti
  geçildikten sonra RevenueCat paywall gösterilir; yarım oturumda gösterilmez.
  Tek seferlik ödeme yalnız etkin patikanın kalan adımlarını açar. Kapatma ve
  ücretsiz içeriğe dönüş hemen erişilebilir. Eski gün 7 ödeme kararı geçersizdir.
- Path sonu üç kovadır (A belirgin / B kısmi / C ilerleme yok); `başarılı/başarısız` dili yok.
- **Kova C'de satış yapılmaz**, devam patikası ücretsiz (ömür boyu 2 limit).
- Varsayılan yanlılığı (önceden doldurulmuş seçim) **ödeme/abonelik kararlarında kullanılmaz**.
- Veri yokken sayısal sosyal kanıt yazılmaz (grafikler dahil — eksenlerde sayı yok).

**Gizlilik**
- Bildirim metni **asla** path adını/sorunu içermez.
- Ham problem metni şifreli ve ayrı tabloda; LLM'e giden bağlam özettir.
- Ölçüm verisi ve problem metni **asla** analitik araçlara gönderilmez.
- Sadece push kanalı — SMS/e-posta ile ruh sağlığı içeriği gönderilmez.
- `UNNotificationInterruptionLevel` her zaman `.active`; `.timeSensitive`/`.critical`/`.provisional` kullanılmaz.
- Günlük hatırlatmalar cihazda `UNCalendarNotificationTrigger` ile planlanır, sunucudan değil.

## Kullanıcıya görünen metin yazarken

Marka sesi: **Sakin · Dürüst · Yanında.** Ünlem neredeyse hiç kullanılmaz.

Ton dört kademeli, bir ekranın kademesi **yukarı çıkmaz**: 🔴 Nötr (kriz, Kova
C, Destek al, feragat) · 🟠 Sakin (oturum, ölçüm, harita) · 🟡 Sıcak (path sonu
A/B, rozet) · 🟢 Oyuncu (Keşfet, nefes, boş durumlar). Şüphede bir kademe aşağı in.

**Ses testi:** Yazdığın cümleyi gece 2'de uyuyamayan ve kendini kötü hisseden
birine yüksek sesle söyleyebiliyor musun?

Yasak ifadeler: "Harika iş çıkardın! 🎉", "Seni özledik", "Serini kaybetmek
üzeresin", "Sadece 2 gün kaldı!", "Diğer kullanıcılar...", "Endişelenme"/"Sakin
ol", "Bunu aşacaksın", "Başarısız". Konfeti, uçuşan emoji, rainbow modu yok.

Buton metinleri ürüne özel: Başla → **Yola çık**, Devam et → **Kaldığın
yerden**, İptal → **Şimdilik değil**, Atla → **Bugün geç**, Kaydet → **Bende
kalsın**, Bitir → **Burada duralım**. Tam liste: `docs/PRD-Ek-Ton-ve-Nudge.md` §3.

Her hata metninde "kaybolmadı / senin yüzünden değil" ifadesi geçer.

## Erişilebilirlik — opsiyonel değil

- `accessibilityReduceMotion`: sahne geçişleri kapanır, yalnızca opacity.
- `accessibilityReduceTransparency`: düz koyu zemin.
- Dynamic Type zorunlu, sabit punto yok; **AX5'te hiçbir ekran kırılmamalı**.
- Metin arkası kontrastı WCAG AA (büyük başlık 3:1) — `Tests/ContrastTests`.
- Ses efektleri varsayılan **kapalı**; haptik tek seviye (`.soft`).
- Tüm animasyonlar 800 ms altı.
- Renk tek başına anlam taşımaz — iyileşme/kötüleşme oku + metinle birlikte.

## Stack kararları

iOS-only SwiftUI native (cross-platform bilinçli reddedildi — ses motoru +
görsel katman paylaşılamaz) · `AVAudioEngine` · SwiftUI native guaj sahneler
(Metal shader kaldırıldı) · SwiftData (yerel) · Node/Python + Postgres
(backend, Supabase) · Sign in with Apple birincil · **RevenueCat**
(2026-09-22 kararı, PRD'nin "StoreKit 2 birincil" satırını geçersiz kılar;
paywall henüz yazılmadı) · PostHog/Amplitude.

Android Faz 4'e ertelendi (D30 ≥%25, LTV > CAC, ayrı kaynak koşullu kapı).

## Faz 0 uyarısı

PRD **0 kullanıcı görüşmesi ve 0 davranışsal veriyle** yazıldı; içindeki her
şey hipotezdir. Faz 0 (10+ görüşme, elle uygulanan tek path, ölçümün gerçekten
fark gösterip göstermediği) tamamlanmadan bu MVP kodlaması PRD'nin kendi
kararına aykırı çalışıyor. Karar kapısı: medyan iyileşme %20 altındaysa tasarım
değişir. Açık sorular (PRD §18) kapanmadı: ürün adı, birincil pazar, ilk path
tipi, ses kimliği, kova eşikleri, ücretsiz adım sayısı — bunlara bağlı bir
uygulama kararı gerekiyorsa varsayım yapma, kullanıcıya sor.
