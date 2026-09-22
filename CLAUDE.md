# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 22 Eylül 2026 — gradyan kaldırıldı, sahne dili geldi; her soru kendi sayfasında; klavye/taşma düzeltmesi

Ürün sahibinin kararı: **uygulama genelinde gradyan yok** — ne onboarding'de ne
meditasyon ekranında. Plan: `docs/onboarding-redesign.md` (ikinci oturum, 2026-09-22
başlıklı bölüm). Bu, önceki "Görsel sistem: video değil shader", "tam güçte
`BreathingMeshBackground`", "A2 ve B6 zemin katmanında kalır (mesh içeriktir)" ve
onboarding'in genel palet mimarisi kararlarını **geçersiz kılar**.

- **Silindi:** `BreathingMeshBackground.swift`, `Shaders.metal` (`grainAndScrim`),
  `Palette.swift` (10 kategori paleti + `mood-*` çapaları + `blend`/`moodAdjusted`/
  `nightAdjusted`), `PaletteController.swift`. `RGB.mixed(with:)` ve
  `RGB.withLuminance(_:)` de silindi — **ikisi de artık ölü koddu**: `withLuminance`
  zaten hiçbir yere bağlı değildi (dokümanların "ton serbest, luminans kilitli"
  iddiası hiç doğru olmamıştı, gerçek kilit yalnızca `Tests/ContrastTests`'ti);
  `mixed` yalnızca `moodAdjusted` ve `HoldToStartButton`'ın gradyan dolgusu
  tarafından kullanılıyordu, ikisi de gitti. Metal toolchain zorunluluğu kalktı.
- **Yerine geldi:** her bölümün tam ekran bir guaj sahnesi (`OnboardingArtwork`,
  `OnboardingSceneLayer`). A2'den B6'ya kadar sahne **seçilen kategoriye göre**
  değişir (`OnboardingFlowViewModel.currentScene`, taslaktan ya da A2'nin henüz
  commit edilmemiş canlı seçiminden okur) — bu işi eskiden canlı palet yapıyordu.
  B6'nın ruh hâli artık sahne perdesini koyultup açıyor (`MoodLevel.sceneDimming`,
  0,26–0,50), palet tonlaması değil. 16 sahne (6 bölüm + 10 kategori) henüz
  üretilmedi; prompt'lar `assets/illustrations/scenes/prompts.md`'de. Görsel
  yoksa (ki şu an hepsi yok, `onboarding-threshold` hariç) ekran düz
  `WoodlandStyle.background`a düşer — hiçbir ekran kırılmaz.
- **`OnboardingSurfaceStyle` ikiye indi:** `.paper` ve `.plain` (eski `.ground` ve
  kullanılmayan `.scene` kalktı). A2 ve B6 `.plain` kalır (sahne cevabın kendisi);
  `PathSessionView` hâlâ bu ortam değerini hiç kurmuyor, varsayılan `.plain`
  onu değiştirmeden koruyor.
- **Meditasyon ekranı da gradyansız.** `PathSessionView` ve G1
  (`FirstSessionView`) artık `bg-session` sahnesi + yeni `BreathOrb` (düz kırık
  beyaz dolgu + ince halka, gradyan yok) kullanıyor. **Küre yalnızca `.preparing`
  fazında görünür** — `.running`da faz görseli (`SessionArtworkView`) zaten
  nefesle ölçekleniyor, ikisi aynı anda ekranda iki ayrı nefes hareketi üretip
  görsel olarak çakışıyordu (simülatörde ölçüldü, düzeltildi). Bu arada
  `SessionArtworkView`nin nefesi de düzeldi: zaman önceden `palette.current.speed`
  (0,18–0,40) ile çarpılıyordu, yani görselin "nefesi" ekranın gerçek 10 sn'lik
  döngüsünün 2,5–5 katı yavaştı; artık ham zaman kullanıyor.
- **E3 ("Sana nasıl bir ses iyi gelir?") silindi.** `TonePreference` enum'u,
  `resolvedTonePreference` ve sunucu alanı **kalıyor** (`_shared/schema.ts` `tone`u
  zorunlu ve doğrulanan bir alan istiyor). Silinen: `PreferenceChoiceViews.swift`
  (`TonePreferenceView` + `sample` uzantısı), `OnboardingStep.e3Tone`,
  `extension TonePreference: OnboardingChoice`, `ChoiceRow.detail` (tek
  tüketicisi E3'tü), 8 katalog kaydı. **`draft.voicePreference = .feminine`
  ataması `commitTonePreference`den `commitReminder`a taşındı** — taşınmasaydı
  ses tercihi hiç kurulmazdı, sessiz bir kayıp olurdu. E1'den sonra akış artık
  doğrudan F1'e gidiyor. Ben sekmesindeki ton satırı da kalktı (`MeViewModel`,
  `SettingsSheet`): kullanıcı hiç seçmediği bir tercihi seçilmiş gibi göstermek
  "verisi olmayan bölüm çizilmez" kuralını ihlal ederdi.
- **Kimlik yeniden üçe bölündü.** 2026-09-21'de isim+cinsiyet+yaş tek kartta
  ilerleyen açılımla birleştirilmişti (`IdentityView`); ürün sahibi "her soru
  kendi sayfasında" isteğiyle bunu geri aldı. Üç ayrı ekran: `NameView`,
  `GenderView`, `AgeRangeView` (`OnboardingStep.identityName/.identityGender/
  .identityAge`). Soru bölümünün izi artık 10 ekran (kimlik 3 + A2 + B1–B6).
- **Klavye ve taşma düzeltmesi.** Kök neden: alt buton bölgesi `ScrollView`'ın
  **dışında**, kardeş bir `VStack` satırıydı; klavye açılınca sistemin klavye
  kaçınması bu sabit satırı hesaba katmadan çalışıyor, odaklanan alan klavyenin
  altında kalabiliyordu. Düzeltme: footer artık `OnboardingQuestionLayout` ve
  `OnboardingStatementLayout`ta **`safeAreaInset(edge: .bottom)`** ile veriliyor;
  klavye ve footer aynı mekanizmadan (safe area inset toplama) geçiyor. İçerik
  bu inset'in altından kayarak geçebiliyor (`safeAreaInset`in kastı budur, bir
  "List altında mini oynatıcı" gibi); bu yüzden footer'ın arkasına yukarıdan
  sızan yumuşak bir karartma (`footerBackdrop`) eklendi — yoksa AX5'te uzun bir
  kâğıt kartın kuyruğu butonun/geç bağlantısının arkasından görünüp okunaksız
  oluyordu (simülatörde ölçüldü, ekran görüntüsüyle doğrulandı).
  `OnboardingTextInput` artık tek satırlı alanlarda `return`ü "Done" yapıp
  `onSubmit` çağırıyor (isim ekranı bunu kullanıyor); çok satırlı alanlarda
  (B1/B4, `return` yeni satır eklediği için) klavyenin üstünde "Done" içeren bir
  araç çubuğu var. `CrisisView`, `NotYetBuiltView` ve F1 (`GenerationView`)
  kendi `ScrollView`'larını aldı — AX5'te hiçbir ekran kırılmaz kuralı üçünde de
  tutulmuyordu.
- **F1 "Building your path" artık gerçekten dinamik.** Eski davranış
  `completedStages`i 1'den doğrudan 4'e atlıyordu — 2. ve 3. satır hiç aktif
  olmuyordu (yorumu "gerçekçi zamanlayıcı"dan söz ediyordu ama kodda zamanlayıcı
  yoktu). Artık gerçek ağ isteği (`flow.generatePath`) uçarken 2. ve 3. aşama
  ölçülü bir tempoyla ilerliyor (`pacedAdvance`, 1,2 sn / 1,6 sn); **4. aşama
  yalnızca gerçek sonuç gelince** işaretleniyor, ağ hızlı dönse bile ara
  aşamalar en az `minStepDisplay` (650 ms) görünür kalıyor. İz artık
  `TrailRow`'un segmentleri yukarıdan aşağı **büyüyerek** beliriyor
  (`scaleEffect(y:anchor: .top)`), aktif düğüm `.generation` genliğinde nefes
  alıyor (önceden sabit `.ambient`ti, `TrailRow` artık `activeAmplitude` alıyor).
- **`Tests/ContrastTests` yeniden yazıldı.** Eski hâli `Palette.all` üzerinden 55
  kombinasyonu tarıyordu, palet silinince derlenmiyordu. Yeni hâli yalnızca
  kâğıt/kartın sabit oranlarını ve görsel yokken düz zeminin kontrastını ölçüyor
  — **sahne + gerçek görselin** üstündeki kontrastı ölçmek `ImageRenderer`
  tabanlı bir XCTest hedefi gerektiriyor ve bu hâlâ yazılmadı (dokümanların
  baştan beri not ettiği eksik).
- **Uygulama durumu:** derleniyor, 13 Swift testinin 13'ü yeşil, simülatörde
  A1→H1 baştan sona ekran görüntüsüyle doğrulandı (görselsiz düşüş dahil, AX5
  dahil). Deno testlerine dokunulmadı (sunucu değişmedi). **Açık kalan:**
  jestler (cetvel, kaydırıcı, kadran, ruh hâli sürüklemesi) statik doğrulandı,
  parmakla sürülmedi.

### Aynı gün devamı — 16 sahne görseli geldi, sert kesme düzeltildi

Ürün sahibi 16 sahne görselini üretti (`~/Downloads/`), depoya alındı:
`assets/illustrations/scenes/*.png` (kaynak) ve
`MyApp/Assets.xcassets/Onboarding/bg-*.imageset/artwork.jpg` (uygulamaya giren
kopya, q85 JPEG, 887×1774, opak). Simülatörde A2 (kategori), isim (bg-gathering),
C1 (bg-reflection), F1 (bg-prepare), G1 (bg-session) ekran görüntüsüyle
doğrulandı — hepsi metin bandı kurallarına (üstte/altta sakin bant) uyuyor.

- **Sahne değişimi sert kesiyordu, düzeltildi.** `OnboardingSceneLayer`'da
  `artwork` değeri aynı `if` dalı içinde değişiyordu (ör. A2'de kategoriden
  kategoriye) ve `Image`'in varlık adı animatable bir özellik olmadığı için
  `.animation(value: artwork)` bunu yakalayamıyordu — sahne bir kesme gibi
  değişiyordu. Düzeltme: `.id(artwork)` her sahneyi ayrı bir görünüm kimliğine
  bağlıyor, böylece SwiftUI kaldırma/ekleme olarak görüyor ve `.transition(.opacity)`
  gerçekten çalışıyor; süre `Theme.Motion.crossFade`den (0,25 sn) `Theme.Motion.palette`ye
  (1,2 sn) çıkarıldı — tam ekran bir kimlik değişimi eski palet geçişiyle aynı
  gerekçeyle ("ani değişim irkiltir") aynı hızda yumuşatılıyor. `reduceMotion`da
  geçiş kapanır. Karartma (`dimming`) artık `ZStack`in tamamına `.overlay` ile
  bindiriliyor — görsel yokken de aynı satırdan geçtiği için iki ayrı kod yolu
  yerine tek kod yolu var.
- **Diğer dinamik görsel/animasyon noktaları tarandı, ek düzeltme gerekmedi:**
  `MoodScale` ve `TrailRow` zaten `Theme.Motion.crossFade` altında doğru
  animasyonlanıyor; `SessionArtworkView` ve `PathLandscapeScene` tek bir sabit
  varlıkla çalışıyor (mid-view swap yok), `.id()` düzeltmesine ihtiyaçları yok.
- **Tuzak tekrar yakalandı ve gerçek kayba yol açıyordu.** Doğrulama
  derlemelerinden biri `Localizable.xcstrings`i yeniden biçimlendirdi ve 13 kaydı
  (`age Range` etiketleri, `%@`/`%lld` gibi format kalıntıları) `localizations`
  alanı boş bırakılmış hâlde bozdu — `generate-string-symbol-shim.py` bu yüzden
  çöktü. `git checkout -- ...xcstrings` ile HEAD'e (commit `9874bcf`) dönüldü,
  ama bu HEAD'den sonra eklenmiş **gerçek** bir kayıt olan `button.doneKeyboard`
  (Faz 5 klavye "Done" tuşu, `OnboardingTextInput.swift`) da beraberinde silindi
  ve derleme `LocalizedStringResource has no member 'buttonDoneKeyboard'` ile
  kırıldı. Kayıt elle geri eklendi. **Ders:** bu dosyayı `git checkout` ile
  sıfırlamadan önce `git show HEAD:...` ile HEAD'in gerçekten temiz olduğunu
  doğrulamak yetmez — HEAD'den sonra eklenen meşru kayıtları da tek tek
  karşılaştırmak gerekir; `SWIFT_EMIT_LOC_STRINGS=NO` her zaman geçilmeli ve
  geçildikten sonraki derlemede dosyanın gerçekten dokunulmadığı (`git diff --stat`)
  doğrulanmalı.

## 21 Eylül 2026 — onboarding yeniden tasarımı (orman dili, ifade eden girdiler, yeni akış)

Plan ve gerekçeler: `docs/onboarding-redesign.md`. Ürün sahibi kapsamı genişletti:
ekranlar birleştirilebilir/kesilebilir/eklenebilir, onboarding'de fiyat şeffaflığı ve
gamification serbest. İki sınır kalır: **uydurma yorum ya da kullanıcı sayısı yok**,
**kriz yolu bozulmaz**. Baseline ölçümü 8 maddesiyle kalır.

- **Üç katman:** zemin (tam güçte `BreathingMeshBackground`) → kâğıt (krem `paperSurface()`,
  yalnızca okuma/cevap yüzeyi) → sahne (tam ekran guaj). Onboarding'de **A2 ve B6 zemin
  katmanında kalır**: A2 paleti, B6 ruh hâlini arka plana yazar; önlerine kart koymak
  neden-sonucu koparır. Me (0,16) ve Keşfet (0,58) mesh'i dekor olarak kısıyordu, burada
  arka plan içeriktir; o kompozisyonlar miras alınmaz.
- **`CalmSurface` değişmez.** `PathSessionView` (oturumun ortası) onun tüketicisi; yerinde
  yeniden biçimlendirmek çalışan meditasyonun ortasına krem kart koyar. Kâğıt ikizleri
  eklenir, `OnboardingSurfaceStyle` ortam değeri varsayılanı `.ground`.
- **Ses yarışı düzeltildi (2026-09-21).** F1 sesi "ateşle ve unut" istiyor; G1'e istek
  ulaşmadan gelen kullanıcı adımı `pending` görüyordu ve eski döngü `pending`i bitiş
  sayıp kalıcı olarak vazgeçiyordu (oturum sonsuza dek sessiz). `AudioReadiness.wait`
  `pending`i bekler, hâlâ `pending` ise isteği **bir kez** kendisi atar. F1 ve G1 aynı
  idempotency anahtarını paylaşır (sunucu (kullanıcı, anahtar) çiftine bakıyor; yeni anahtar
  ikinci bir TTS faturası) ve G1 istek atmadan önce F1 görevini bekler (uçuştaki isteğe
  ikinci kuyruk mesajı iki işçiyi aynı slotlara sokardı). `failed` bitiştir; 503/422
  (sağlayıcı yok) beklemeyi keser. `live-smoke-audio.py` sesi yoklamadan **önce**
  istediği için bu yarışı hiç görmüyordu; regresyon testi `Tests/AudioReadinessTests`.
- **Ölçüm aracı zamanlar arası aynı kalır.** `PathMeasurementQuestionView` gün 7/14/son
  ölçümünü aynı ViewModel'le toplar; D ekranı yalnızca onboarding'de değişirse baseline
  ile takip farklı araçla toplanır ve gün 7 "iyileşmesi"nin bir kısmı araç farkı olur.
  D ekranları iki yerde birlikte, ortak bir cevap görünümüyle değişir.
- **Uygulama durumu (2026-09-21, akşam).** Kodda bitti: Faz 1-6 ve 8-10 (aşağıdaki sapmalarla).
  Kâğıt katmanı: kimlik (3 ekran tek kartta), B1-B5, C1-C4, taahhüt, D0, E1, E3, fiyat, H2.
  Zeminde kalan: A2, B6, D1-D8. Yeni: `RadialClockDial` (E1),
  `MeasurementAnswerView` (onboarding D ve yol içi
  ölçümün **tek** cevap alanı), `MoodScale` sürüklemesi (B6 arka planı parmağın altında
  boyar), F4 fiyat şeffaflığı (G2 sonrası), H2 bildirim ön hazırlığı (`ReminderScheduler`).
  Akış: A1, kimlik, A2, B, C, **taahhüt**, D, E, F, G, **fiyat, H2**, H1. DEBUG: bütün adımlar
  `OnboardingGallery` önizlemesinde; `-patika-debug-step identity|commit|price|h2|e3|b2`.
- **Planla ayrıldığım yerler ve nedenleri.**
  1. **D2-D8 cetvele çevrilmedi.** Kova etiketleri cümle uzunluğunda ve aracın parçası; cetvel
     yalnızca seçili etiketi gösterirdi, kullanıcı cevaplamadan önce seçenek metnini göremezdi.
     Bu baseline ile gün-7 arasındaki tek karşılaştırmayı değiştirirdi. Yalnızca cevap alanı
     iki çağrı yerinde birleşti. `IntensityScale` (D1) dokunulmadı.
  2. **E3 kaydırıcı değil.** `TonePreference` sıralı değil (kısa/sakin, yönlendirici, yalnızca
     bilgi); kaydırıcı olmayan bir sırayı ima eder. Plandaki asıl niyet, her tonun gerçek örnek
     cümlesi, `ChoiceRow(detail:)` ile yapıldı.
  3. **B3 kadran değil.** `ProblemTiming` numaralandırılmış bir küme; kadranın açısını
     kovaya eşlemek sunucu sözleşmesini riske atar. Kadran yalnızca E1'de. Erişilebilirlik
     boyutlarında ve VoiceOver açıkken tekerlek (açık şemayla) kullanılır.
  4. **A1 sahnesi geldi, yol animasyonu silindi.** Görsel `onboarding-threshold` ile tam ekran
     sahne çizilir (kabuk zemini + alt karartma). Sahne yoksa (Reduce Transparency, AX boyutu,
     `-patika-debug-no-art`) çıplak mesh, başlık ve düğme kalır. `PathDrawAnimation` planın
     dediği gibi silindi; "marka kimliği yol animasyonu" notu (A1 satırları) geçersiz.
  5. **Fiyat ekranındaki rakamlar PRD §12.1'den, katalogda sabit metin.** Paywall **RevenueCat** ile yapılacak
     (ürün sahibi kararı, 2026-09-22; Stack kararındaki "StoreKit 2 birincil" bununla geçersiz). Yayından önce RevenueCat
     offering'inden okunmalı ve birincil pazar kararı (PRD §18, açık soru 2) verilmeli: €12.99
     Türkiye için yüksek. Taahhüdün cevabı saklanmıyor ve sunucuya gitmiyor.
  6. **Kontrol edilmedi:** sürükleme jestleri (cetvel, kaydırıcı, kadran, ruh hâli) derlendi ve
     statik çizildi, parmakla sürülmedi (test hedefi ve dokunma enjeksiyonu yok). Görsel
     tabanlı kontrast ölçümü (zemin ekranları) yok; `Tests/ContrastTests` yalnızca değer
     düzeyinde. Yeni 10 guaj parçası üretildi ve projeye alındı (2026-09-22, kaynaklar `assets/illustrations/onboarding/`, uygulamaya içerik sınırına kırpılmış 1200 px kopyalar; F2 görseli hâlâ canlı mesh üstünde, sahne zemini yok).
- **Tuzak: bir yaprak bileşen mürekkebi kendi çağıranından okuyamaz.** Kâğıt kartın içindeki
  bir metin `@Environment(\.patikaInk)`i **çağıran ekranda** okursa `.light` görür (ekran
  kartın dışında durur) ve kâğıtta açık renkle görünmez kalır. Ekranlarda `.inkStyle(.primary)`
  kullanılır (değiştirici değeri kendi hiyerarşisinden okur).
- **Tuzak: Xcode `Localizable.xcstrings`i kirletir.** Derleme, kaynaktaki düz `Text("...")`
  sabitlerinden `extractionState`sız kayıtlar ekleyip dosyayı yeniden biçimler; bu hem
  `generate-string-symbol-shim.py`yi çökertir hem katalog testini kırar. `xcodebuild`e
  `SWIFT_EMIT_LOC_STRINGS=NO` verilirse dosyaya dokunmaz. Bilinen kaynaklar: `JourneyMap.swift`
  (Türkçe düz metin), yaş aralığı ve `MeasurementLibrary` etiketleri.

## 21 Eylül 2026 — yalnızca İngilizce MVP, tek ses, tek metin kataloğu, oturum tempo düzeltmesi

Ürün sahibi MVP'yi **yalnızca İngilizce ve yalnızca kadın sesiyle** çıkarmaya karar verdi;
metinlerin tek yerde toplanmasını istedi. Bu, önceki "sabit Türkçe arayüz", "TR + EN ses",
"iki ses seçimi (E4)" ve "Keşfet ses seçici" kararlarını geçersiz kılar.

- **Dil tek noktadan:** `AppLocale.current` sabit `.english`. Cihaz Türkçe olsa da arayüz,
  Keşfet, ses ve sunucuya giden dil İngilizce (simülatörde `-AppleLanguages (tr)` ile
  doğrulandı). Türkçeyi geri açmak: `current`i cihaz diline bağla + kataloğa `tr` ekle.
- **Metnin tek yeri `MyApp/Content/Localizable.xcstrings`** (kaynak dil İngilizce, 700+ kayıt,
  hepsi `extractionState: manual`, çünkü Xcode yalnızca manuel kayıtlar için sembol üretiyor).
  Kodda metin yazılmaz: `Text(.tabPath)`, `LocalizedStringResource.authApple`. `Copy.*`
  **sıfır metinli** bir ad alanı ön yüzüdür (`static let apple: LocalizedStringResource = .authApple`);
  yeni metin katalogda başlar, `Copy` yalnızca gruplama gerekiyorsa ona işaret eder.
  Xcode dışında `swiftc` ile derlenen testler için sembol örtüsü katalogdan üretilir:
  `python3 scripts/generate-string-symbol-shim.py` (`bash scripts/run-swift-tests.sh` bunu kendi yapar).
  Kuralları `Tests/LocalizationCatalogTests` denetler: manuel kayıt, yasaklı ifade (İngilizce
  `BannedPhrases`), emoji, yer tutucu tutarlılığı. Çoğul metinler katalogda `variations.plural`.
  `#Preview` ve yalnızca DEBUG olan geliştirici metinleri katalog dışı, doğrudan İngilizce.
- **Kriz ön filtresi İngilizce geldi.** Önceki liste ağırlıklı Türkçeydi; İngilizce-only bir
  uygulamada bu bir güvenlik açığıydı. Cihazdaki `CrisisClassifier` ve sunucudaki
  `_shared/crisis.ts` **aynı ifade kümesini ve aynı normalizasyonu** (kesme işareti düşer,
  tire boşluk olur) kullanır; ayrışmayı `crisis_contract_test.ts` yakalar. Vaka tablosu:
  `Tests/CrisisClassifierTests`. Türkçe ifadeler korunuyor.
- **Tek ses = kadın; adım uzunluğu kullanıcıya sorulmuyor.** E4 (ses) ve E2 (uzunluk) onboarding'den
  **silindi** (ürün sahibi kararı: uzunluğu biz ayarlıyoruz). Uzunluk taslağın varsayılanı (10 dk),
  ses `commitTonePreference`te `.feminine`e yazılır; E bölümü artık E1 (saat) + E3 (ton). Keşfet'te ve
  Ben'de ses/uzunluk satırı yok. Sunucu ve oturum bu alanları okumaya devam eder.
- **Oturum tempo düzeltmesi (K1-K6, `docs/PRD-Ek-Oturum-Motoru-ve-JIT.md` §2).** Üç kademe:
  *join* (~350 ms, **olay değil**, sonraki konuşmanın `leadInMs`i), *beat* (yazılan `ms`,
  nefese yuvarlanmaz), *practice* (nefes katı, bloğun kendi periyoduyla: kutu nefesi 16 sn).
  Manifest `version: 1`de kaldı, tüm yeni alanlar opsiyonel ve eklemeli; eski manifestler çalışır.
  Ses ve ekran **aynı** `SessionTimeline`ı okur; çizelge dosyalar yüklenip **ölçüldükten**
  sonra kurulur (`durationMs` yalnızca planlama). Oynatma sıralıdır, mutlak zaman yok
  (`SessionScheduler`: kenar fade tamponları + dosyadan çalan orta segment + gerçek sessizlik
  tamponları), bu yüzden çakışma yapısal olarak imkânsız. `Tests/SessionSchedulerTests` bunu
  `AVAudioEngine` çevrimdışı işlemeyle **dalga formu** üstünden doğrular.
  Sunucu: `mp3.ts` (gerçek süre), lead/tail sessizlik, `joinLeadInMs`, `breathMsFor`.
  > **`landOn` sunucuda çözülmüyor, bilerek.** `alignedSilenceMs` yazıldı ve test edildi ama
  > worker'a bağlı değil: arka plan nefesi duvar saatinden akıyor (`BreathingMeshBackground`),
  > oturum saatine kilitli değil. Kilit yokken sanal fazla süreyi kaydırmak hiçbir şey
  > kazandırmayıp süreyi ±yarım nefes oynatırdı. Bağlamak için önce mesh nefes saati
  > oturum çizelgesine kilitlenmeli.
- **Keşfet v2.** Katalog `version: 2`: adım = `segments: [{text, quietMs}]` + ortak `closing`;
  çoğu adımın süresi sessizliktir (~3 dk sessizlik, ~1 dk konuşma). Yeni metin yazılmadı,
  mevcut `guidance` cümle sınırlarından bölündü. `DiscoverText.tr` isteğe bağlı ve boş.
  Sesler **yerelde** üretilir: `scripts/render-discover-audio.py` (kırpma, iki geçişli -16 LUFS,
  15 ms tıklama önleyici, 64 kbps mono; ham ses `build/` altında önbelleklenir, son işlem
  değişirse yeniden ödenmez). Anahtar yalnızca `ELEVENLABS_API_KEY` ortam değişkeninden gelir;
  depoda anahtar olmadığını bir Deno testi tarar. `render-discover-audio` edge fonksiyonu
  depodan kaldırıldı (uzaktaki kopyası her çağrıda 403 döner, silinebilir).
  Ses dosyaları Git LFS'te (`.gitattributes`). Tam katalog (286 kayıt, ~20 bin karakter) tek
  ses/tek dil ile ~20 MB. **Şu an yalnızca `breath` patikası üretildi** (örnek).
- **Blok kütüphanesi** `scripts/render-block-audio.py` ile yerelde render edilip Supabase CLI ile
  (`supabase storage cp --linked`, `supabase db query --linked`, hizmet anahtarı gerekmez)
  yüklenir. Sunucunun `renditionHash`i ile bire bir aynı özet: Python-Deno eşitliği
  `Tests` altındaki altın vektörlerle sınanır.
- **Test komutları.** Swift: `bash scripts/run-swift-tests.sh`. Deno:
  `npx --yes deno test --no-prompt --allow-read --allow-env --allow-net supabase/functions/tests/`
  (`--no-prompt` şart, yoksa izin sorusunda asılı kalır). `JourneyRoutePatternTests` bu işten
  önce de bayattı (tip artık yok).
- **Dağıtıldı (2026-09-21).** Migrasyonlar `20260921090000`, `100000`, `100100`, `110000` uygulandı;
  tüm fonksiyonlar dağıtıldı; `render-discover-audio` uzaktan silindi; 39 blok sesi yüklendi.
  Bekleme **1500 ms** (ürün sahibi dinleme testinde 800 ve 1500'ü beğendi). Canlı uçtan uca:
  `python3 scripts/live-smoke-audio.py` (15/15: İngilizce patika, ses kuyruğu, manifest sözleşmesi,
  açık kovadaki blok sesi). Yapılan canlı düzeltmeler, ikisi de kişisel slot sesini hiç
  üretilemez kılan **eski** hatalardı (geçersiz anahtar yüzünden görünmemişti):
  1. `eleven_v3` `previous_text`/`next_text` (istek dikişi) kabul etmiyor -> `400 unsupported_model`.
     `speechRequestBody` v3'te bağlam göndermez.
  2. `audio_assets` upsert'inin conflict hedefi **kısmi** indeksle eşleşmiyordu (42P10 ->
     `database_write_failed`); indeks koşulsuz yeniden kuruldu (`20260921110000`).
- **Nefes blokları gerçek sayımla yazıldı** (yalnızca İngilizce, `version 2`): `breath.extendedExhale`
  (3 döngü, alma ve **verme** sayımı) ve `breath.box` (2 döngü, her parça tam 4 sn = 16 sn).
  Sayım cümleleri ölçülerek seçildi; bekleme ölçülen konuşma süresini tamamlar. Ekrandaki nefes
  hâlâ 10 sn'lik sabit döngü ve bu bloklarla senkron değil, bu yüzden bloklar ekrana atıf yapmaz
  (yalnızca `breath.awareness` "ekrandaki hareketi takip et" der, faz bağımsız).
  Manifest `ms >= 250` ister (SQL CHECK ve doğrulama); 200 ms'lik bir bekleme migrasyonu düşürdü.
- **Keşfet sesi tam:** 10 patika, 286 kayıt, 18 MB, seviye yayılımı 1,0 LU, hepsi Git LFS'te.
  Render'da ElevenLabs eşzamanlılık sınırı 3 (`--workers 2` kullan). Kalan kota ~27 bin karakter.

## 16 Eylül 2026 — Yolum düzenlemesi

Ürün sahibinin son talebiyle Yolum başlığı sabit olmaktan çıkarıldı; kaydırma ile
parallax/fade/blur uygular ve geri dönünce görünür. Mevcut adım kartı da artık
kapatılıp yeniden açılabilir; “Buradasın” etiketi ve düğüm konumu korunur.
Bu kararlar önceki sabit başlık ve mevcut kartın kapanmaması kararını geçersiz kılar.
Uzun adım başlıkları kırpılmadan sarılır, rota ayrı koridorda daha yumuşak kıvrılır.
Tasarım ve doğrulama ayrıntıları: `docs/path-home-design.md`.

## 16 Eylül 2026 — uygulama genelinde arayüz iyileştirmesi

Ürün sahibi kapsamı tüm uygulamanın UI/UX kalitesine genişletti. Seçim ve yazı
alanları ortak CalmSurface kullanır; erişilebilir büyük yazıda kategori listesi
tek sütun olur. Ben başlığı semantik tipografi ve ayrı defter görseli kullanır.
Oturumda kullanıcının sözü Theme.Voice.user ile gösterilir. Karşılama ve oturum
sonu ekranları uzun içerikte kaydırılabilir. Tasarım ve doğrulama kapsamı:
`docs/ui-refinement-2026-09-16.md`.

## 16 Eylül 2026 — Keşfet hazır patikaları

Ürün sahibinin açık talebi hazır patika kütüphanesini bu çalışmanın kapsamına aldı.
Keşfet üç adet yedi adımlı, kişiselleştirilmemiş patika sunar. Adımlar arasında gün
bekleme yoktur. Önizlemede oynatma yoktur; katılım sonrası sıradaki adım ve tamamlanan
adımlar açılır. Her patikanın ilerlemesi cihazda ayrı saklanır; kişisel sunucu
patikası silinmez. İngilizce ses için mevcut kadın/erkek sesleri ayrı seçeneklerdir.
İçerik TR/EN çiftleriyle, arayüz metinleri Discover String Catalog ile tutulur.
Yolum başlığındaki dekoratif görsel kullanıcı talebiyle kaldırıldı.
Ses üretimi ElevenLabs 402 payment_required nedeniyle tamamlanamadı; ses dosyaları
paketlenmeden katılım etkinleşmez. Ayrıntılar: `docs/discover-design.md`.

## 17 Eylül 2026 — ortak guaj illüstrasyon dili

Ürün sahibi Keşfet'teki illüstrasyonları uygulamanın genel görsel dili olarak seçti.
Bu karar önceki tek mürekkepli, buzlu cam/heykelsi raster görsel brief'ini ezer.
Yeni aile: koyu teal, adaçayı, soluk mavi, krem ve kayısı; guaj dokusu ve gerçek
alfa kanallı PNG kesitleri. C1/C2, F2, G2, Ben başlığı ve Yolum bu aileyi kullanır.
Dinamik palet, ölçüm/kriz kuralları ve SF Symbols kontrol dili korunur. Kriz
modunda dekoratif görsel gösterilmez. Kaynaklar ve prompt'lar:
`assets/illustrations/gouache/prompts.json`.

Ürün sahibi Headspace kart listesini Yolum için reddetti; yön, Duolingo/Noom/Ahead
benzeri görsel rota ve duraklardır. Streak, enerji ve ödül mekaniği eklenmez.

## 17 Eylül 2026 — Ahead manzara patikası uygulandı

Ürün sahibi Ahead'in manzara içinde yolculuk yaklaşımını açıkça onayladı.
Yolum artık küçük yan dekorlar yerine ekran genişliğinde, kaydırmayla ilerleyen
iki özgün guaj manzarası kullanır: orman açıklığı ve gölet/nehir kıyısı. Bunlar
statik illüstrasyon katmanlarıdır; alttaki düşük genlikli MeshGradient korunur.
Rota ve gerçek adım düğümleri native çizilir; manzaraya gömülü tıklama noktaları
yoktur. Arka plan sahneleri birbirine karışır, başlık kaydırmayla solar.
Mevcut durak krem halka ve “Buradasın” ile ayrılır; ayrıntısı açılıp kapanır.
Reduce Motion parallax'ı kapatır; Reduce Transparency ve AX boyutlarında düz
koyu zemine geçilir. Görsel, veri veya ilerleme üretmez; oturum erişimi mevcut
MyPathViewModel kurallarından gelir. Ayrıntılar: `docs/path-home-design.md`.

## 20 Eylül 2026 — Keşfet v2

Ürün sahibi Keşfet'i Ben v2'nin diline taşımayı ve hazır patika kütüphanesini
genişletmeyi istedi. Kütüphane 10 patika (kategori başına bir), bölüm başlıklarıyla
dikey akış; Keşfet'e özgü `discover-world` manzarası, krem kâğıt kartlar, yüzen cam
başlık; "Explore" üst etiketi kalktı, yazı yalnızca `Theme.TypeFace`. Detay artık
sheet değil push (zoom geçişi) ve zemini patikanın kategori paletidir. Katılınan
hazır patika Yolum'u devralmaz, Keşfet'te kalır; birden fazlasına katılınabilir.
Dil `AppLocale`e uyar; ses hâlâ üretilmediği için sesi olmayan patika "Yakında"
görünür ve katılım kapalı kalır. Bu karar Keşfet'in önceki sabit-İngilizce ve
sheet-önizleme kararlarını geçersiz kılar. Plan: `docs/discover-v2-plan.md`;
tasarım: `docs/discover-design.md`; görseller:
`assets/illustrations/discover/prompts.md`.

Ürün sahibi görsel yoğunluğu geri bildirimle azalttı (2026-09-20): `discover-world`
manzarası koyu orman tonunda %58 perdeyle karartılır (`PathLandscapeScene`
`dimming`; Yolum'un varsayılanı 0, değişmedi), kart görsel bandı 150 pt'den
112 pt'ye iner, yatay şerit kalır; kart özeti koyu mürekkep (`ink`) ve bir punto
büyük, durum etiketi kapsül içinde. Bölüm başlıkları düz krem yazıdır; koyu zeminde
kontrastı ölçüldü (medyan 7,2:1). Keşfet görselleri JPEG imageset'tir.

## 20 Eylül 2026 — oturum kalıcılığı, defter yüzeyi, not sınırı

Ürün sahibi patikanın, profil fotoğrafının ve defter notlarının uygulama yeniden
açılınca kaybolduğunu bildirdi. Kök neden `AuthSessionStore`: Keychain oturumu
fire-and-forget bir Task'la geri yükleniyordu, açılışta ilk jeton isteyen "henüz
yüklenmedi"yi "oturum yok" sanıp yeni bir anonim kullanıcı açıyor ve gerçek oturumu
eziyordu (iOS 27 simülatöründe 3 açılışta 3 farklı kullanıcı, canlı sunucuda
doğrulandı). Her açılışta boş patika, kaybolan not ve fotoğraf, Yolum'un boş
durumundaki "Başla" ile de baştan onboarding buradan geliyordu.

- **Her giriş noktası geri yüklemeyi bekler** (`restoration`); jeton istekleri tek
  uçuştaki Task'ı paylaşır ve çağıranın iptalinden bağımsızdır.
- **Geçici hata kimliği yok etmez.** Yeni anonim kullanıcı yalnızca Keychain
  gerçekten boşsa ya da sunucu yenileme jetonunu kesin reddettiyse
  (`AuthClientError.sessionRejected`) açılır; bağlantılı hesapta hiç açılmaz.
  Test: `Tests/AuthSessionStoreTests` (swiftc ile derlenir, bkz. dosya başı).
- **`markOnboardingCompleted` filtresizdi**: Supabase `pg_safeupdate` 400 dönüyor,
  hiçbir profilde `onboarding_completed_at` dolmamıştı. `user_id=eq.` filtresi eklendi.
- **Onboarding'in son ekranından önce çıkılırsa** ve sunucuda bu kimliğin patikası
  varsa açılışta onboarding tamamlanmış sayılır (`PatikaApp.adoptExistingPathIfAny`,
  4 sn zaman aşımı). Taslak (`OnboardingDraft`) hâlâ kalıcı değil; patika üretilmeden
  yarıda kalan akış baştan başlar.
- **Defter her zaman kâğıt yaprak ve açılan kapakla gelir**, kayıt olmasa da; boş
  defter kâğıdın üstünde koyu mürekkeple çizilir (`JournalView.paperSheet`).
- **Not sınırı 1000** (`JournalNote.maxLength` = sunucudaki `maxNoteLength`, ikisi
  birlikte değişir; UTF-16 birimiyle ölçülür). Sayaç yalnızca son %10'da görünür;
  ödev hissi vermesin. Bu, eski "sessiz 4000" kararını geçersiz kılar.
- Bu hatadan önce oluşan veri eski anonim kimliklerin altında kaldı ve
  kurtarılamaz (anonim kimliğin kimlik bilgisi yok).

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

> **Geri alındı (2026-09-21):** C ekranları artık cümle cümle beklemiyor; ürün sahibi bekleyişi uygulamanın yavaş olması gibi okudu. Kâğıt ekranlar `statementReveal` ile `woodlandReveal` kullanır (0,045 sn adım, en fazla 5 adım; sayısı dinamik olan C1 paragrafları için tavan şart). `sequentialReveal` ve 1,5 sn yalnızca zemin malzemesinde, yani `PathSessionView`da kalır (D0 kâğıda alındı). Aşağıdaki paragraf o tarihe kadarki gerekçeyi taşır.

C ekranlarındaki her paragraf `.sequentialReveal(index)` ile sırayla süzülürdü (400 ms giriş + adım başına 1,5 sn, her biri 700 ms'de solarak ve 8 pt aşağıdan). Aralık 1 sn'den 1,5 sn'ye çıkarıldı (ürün sahibi kararı, 2026-09-08): bir saniye önceki cümleyi bitirmeye yetmiyor, sonraki cümle okuma sürerken belirip gözü aşağı çekiyordu. Beklemek zorunlu değil — CTA baştan basılabilir. Gerekçe (ürün sahibi kararı, 2026-09-08): aynı anda basılan 3–4 cümle "duvar" gibi görünüyor ve göz nereden başlayacağını bilemiyor; bir saniyelik ritim her cümleye kısa bir okuma payı bırakıyor. Reduce Motion'da kayma yok, yalnızca solma.

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
- 2026-09-22 kararı bu uzun haritayı geçersiz kıldı: F2 artık otomatik
  kaymayan, ilk dört durağı ekrana sığdıran kısa bir özettir.

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

**Onboarding durumu:** A bölümü (A1 kanca + A2 kategori seçimi), **B bölümü (B1–B6 problem keşfi)**, **C bölümü (C1–C4 yansıtma)**, **D bölümü (D0 giriş + D1–D8 baseline ölçüm)** **E bölümü (E1–E3 tercihler)** ve **F bölümü (F1 üretim + F2 yol haritası)** çalışıyor; canlı palet geçişi, ruh hâline göre renk kayması, kategoriye göre placeholder rotasyonu, B5'in koşullu terapi notu, C3'ün koşullu atlanması, cümle cümle beliren C metinleri, C3'ün iki sütunu, C4'ün kompakt grafiği, D bölümünün sekiz sorusu, isimli hitap, E1'in önerilen saati, F1'in işaretlenen izi ve F2'nin yol haritası simülatörde doğrulandı. A2'de 10 seçeneğin tamamı varsayılan metin boyutunda kaydırmasız görünür; `ScrollView` yalnızca büyük Dynamic Type boyutlarında devreye girer. A1'de kelime markası yok; açılış manzarası (`onboarding-threshold`) markanın ilk izlenimi (yol animasyonu 2026-09-22'de silindi). H bölümünün kalanı (H2, H3) yazılmadı; `OnboardingStep.g1FirstSession` ve `g2SessionComplete` çalışıyor (yukarıya bak); H bölümünde yalnızca H1 var, H2 (bildirim ön hazırlığı) ve H3 yazılmadı. **F4 (fiyat şeffaflığı) yersiz kaldı** — aşağıya bak.

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
- **Yolum rotası kesintisizdir** (ürün sahibi kararı, 2026-09-10). F2'nin kısa
  faz aralıkları onboarding sunumunda kalır; günlük Yolum ekranında faz eşiği
  çizgiyi kesmez, gelecek bölüm kesikli olmaz ve düğüm–metin bağlantı çubukları
  çizilmez. Tamamlanan bölüm daha belirgin, gelecek bölüm daha soluk tek bir
  mürekkep izi olarak devam eder.
- **Yolum faz görselleri gerçek faza bağlıdır.** Üç kırık beyaz, dokulu şerit
  illüstrasyonu (`journey-relief`, `journey-practice`, `journey-closing`) yalnızca
  sıradaki faz ve gerçek faz başlangıçlarından seçilir. Ham problem metni resme
  çevrilmez; AX Dynamic Type'ta görseller saklanır ve hepsi VoiceOver'dan gizlidir.
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

### "Ben" sekmesi çalışıyor — geriye bakan defter (2026-09-12)

`MyApp/Features/Me/`. Tasarım ve bütün kararlar: `docs/profile-design.md`.
"Yolum" ileriye bakan harita, "Ben" geriye bakan defter; **birincil CTA yok**.
Bölüm sırası sabit: başlık → Ne değişti → Defter → Yürüdüğün yollar → Sana göre
ayarlananlar → Destek al → (anonim hesap) → Ayarlar ve gizlilik.

- **Cihazda artık bir kayıt var** (`ProfileStore` → `ProfileRecord`, tek JSON,
  `completeUnlessOpen`). Önceden onboarding bitince ad, B1 cümlesi, baseline ve
  tercihler hiçbir yerde kalmıyordu. Kayıt `completeFirstStep` ve
  `completeOnboarding`da yazılır; kriz sinyali verilmiş akış kaydedilmez.
  `PersistentModels` (SwiftData) hâlâ kullanılmıyor.
- **Değişim sayıyla değil konumla** (`BaselineTrack`): nokta kullanıcının kendi
  başlangıç işaretine göre iyi yönde sağa kayar; yön = kelime + ok + konum, renk
  yok. Ana sayfada ve ayrıntıda yüzde yok; sayı yalnızca path sonu raporunda.
  Cümle deterministik şablon (`ChangeSentence`); kötüleşen katman **mutlaka** geçer.
- **Karşılaştırma ortak maddelerle yapılır** (`ChangeAnalysis.comparableScores`):
  14. gün kısa form; farklı madde setleri hiçbir cevap değişmemişken katmanı
  hareket etmiş gösteriyordu.
- **Kullanıcının cümlesi serif** (`Theme.Voice.user`, New York), ürünün sesi SF
  Pro. Defter düzenlenmez, yalnızca silinir.
- **Rozet = mühür = yolun rota çizimi** (`RouteSeal`); kova farkı çizimde yok.
- **Hatırlatma artık gerçekten planlanıyor** (`ReminderScheduler`: cihazda,
  `.active`, ses yok, izin anahtar açılınca). Uzunluk/ton/ses **salt okunur** —
  sunucuda path tercihlerini güncelleyen uç nokta yok.
- `PathSessionViewModel` sabit 10 dakika yerine kayıttaki `sessionLength`i kullanır.
- **Uygulama kilidi** (`AppLockController`, Face ID/parola, 30 sn tolerans) ve
  arka plana geçerken içeriği örten perde (`PrivacyShieldView`). **SOS ikisinin
  de üstünde.**
- **Destek al** (`SupportView`, `SupportResources`): ülkeye göre numara, tek
  dokunuşla arama. ⚠️ Numaralar yayından önce resmî kaynaktan doğrulanmalı.
- DEBUG: `-patika-debug-tab ben -patika-debug-me pending|compared|worse|finished|crisis|empty`,
  `-patika-debug-me-anchor …`, `-patika-debug-me-sheet change|settings|reminder|support`.

**Güncelleme (2026-09-12, aynı gün): sayfa yalnızca gerçek veriyle çalışıyor.**

- **Kaynak sunucu.** `me-profile` Edge Function'ı ad, ilk cümle + kaçınma
  cümlesi, oturum cevapları (şifreleri sahibine çözülmüş), ölçümler, yollar ve
  yolun kurulduğu tercihleri döndürür; `ProfileStore.apply(_:)` kayda işler.
  Cihaza ait olanlar (hatırlatma, gizlilik, kilit) korunur. Defter artık yalnızca
  sunucudan dolar — yerel `appendReflection` çağrıları kaldırıldı.
- **Verisi olmayan bölüm çizilmez, not yok.** Gerçek karşılaştırma yoksa "Ne
  değişti" yok; cümle yoksa defter yok; yol yoksa mühür yok; hazır patikada
  uzunluk/ton/ses satırı yok. Klinik feragat yalnızca değişim kartıyla birlikte
  (PRD §8.1). `me-paths-empty` illüstrasyonu bu yüzden kullanılmıyor.
- **Yeni Edge Function'lar (dağıtık):** `me-profile`, `update-profile` (ad,
  şifreli + kriz taraması), `delete-journal` (tek cevap / ilk cümleler / hepsi),
  `delete-account` (kişisel ses dosyaları + `auth.admin.deleteUser`, tablolar
  cascade). Migrasyon gerekmedi. Canlı duman testi geçti.
- **Yol içi ölçüm akışı yazıldı** (`PathSessionViewModel`): 7./14. adım ve son
  adımdan sonra, sonuna kadar dinlendiyse ve o gün için kayıt yoksa. Cevaplar
  `measurements` tablosuna REST ile yazılır; aynı gün çakışması (409) başarı
  sayılır. `MeasurementSchedule` gün ↔ ölçüm noktası eşlemesi.
- **Düzeltilen hata:** sorusu olmayan adımlar (hazır patika) hiç `completeStep`
  çağırmıyordu ve yol ilerlemiyordu. Artık sonuna kadar dinlenen her adım
  tamamlanır; ağ hatasında "Yeniden dene".
- **Hesap silme gerçek:** sunucu silmeyi tamamlarsa cihaz kaydı silinir, oturum
  kapanır, uygulama onboarding'e döner.
- Ad onboarding sonunda sunucuya yazılır (`completeOnboarding`).

**Güncelleme 2 (2026-09-12): açık kalan sunucu işleri kapandı.**

- **Yol sonu:** `complete-step` tamamlanmamış adım kalmadığında yolu
  `completed` işaretler (`pathStatus` döner). "Yolum" aktif **ya da tamamlanmış**
  en yeni yolu okur (`status=in.(active,completed)`), son adımdan sonra boşalmaz;
  `ActivePath.isCompleted` üretim uzlaştırmasının bitmiş yolu yeni yol sanmasını
  engeller. "Ben" tamamlanan yolun kovasını baseline ↔ son ölçümden
  deterministik hesaplar (`ChangeAnalysis.bucket`); son ölçüm yoksa kova yazılmaz.
- **Ölçümler yola bağlı** (`20260912120000_measurements_per_path.sql`, uygulandı):
  `measurements.path_id`, baseline kullanıcı başına tekil (kısmi dizin), ara/son
  ölçüm yol başına tekil; ekleme politikası yolun sahibini denetler. `generate-path`
  baseline'ı kısmi dizin yüzünden `onConflict` yerine ekle-ve-çakışmayı-geç ile
  yazar. "Ne değişti" yalnızca baseline + ilgili yolun ölçümlerini karşılaştırır.
- **Migrasyon defteri onarıldı:** uzaktaki yinelenen `20260909152752` ve
  `20260909155018` `reverted` işaretlendi; yerel ve uzak birebir.
- **Fonksiyon testleri koşuyor:** `npx --yes deno test --allow-read --allow-env
  --allow-net supabase/functions/tests/` — 21/21 geçti (yeni
  `profile_contract_test.ts`: şifreleme gidiş-dönüş, bozuk şifre reddi, ölçüm
  migrasyonu sözleşmesi).
- **Canlı uçtan uca doğrulandı:** 21 adımlı yol üretimi → 7. gün ölçümü (201) →
  aynı gün tekrar (409) → yabancı yola ölçüm (403) → 21 adım tamamlama (20.
  adımda `active`, 21.'de `completed`) → `me-profile` → hesap silme.

> **Açık kalan:** yalnızca satın alma satırı (StoreKit). `me-paths-empty`
> illüstrasyonu boş durum çizilmediği için kullanılmıyor.

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
| `docs/PRD-Ek-Profil-Sayfasi.md` | "Ben" sekmesinin ilk iskeleti ve Ahead/Fabulous/Ladder/Yazio incelemesi. Abonelik satırı eskidi; güncel tasarım aşağıdaki dosyada |
| `docs/profile-design.md` | **"Ben" sekmesinde çalışırken zorunlu.** Ekran ekran tasarım, Ahead etkileşim döngüsü analizi, durum matrisi, mikrometin, uygulama durumu (§18) ve görsel prompt'ları (§19) |
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

**Gamification — sınırları çizilmiş serbestlik (güncellendi, 2026-09-19)**
Serbest: kilometre taşı rozetleri, nazik haftalık seri, sade kutlama. Rozet geri
alınmaz; kutlama Lottie ya da özel damga animasyonu değil, sade native beliriş ve
tek yumuşak haptiktir.
Yasak kalan: toplam sayılar, lig/sıralama ve kullanıcılar arası kıyaslama,
sıfırlanan ilerleme, kayıp bildirimi ("seni özledik"), sahte aciliyet/geri sayım,
can/enerji sistemi, değişken ödül döngüsü. Kaygı ürününde kayıp kaçınması =
üretilmiş kaygı.
Seri kuralları: seri "bu hafta" demektir — pazartesi–pazar arasında tamamlanan adım
günleri. Kırılınca sıfırlanma mesajı gösterilmez, "kaybetmek üzeresin" denmez,
bildirimlerde seriden hiç söz edilmez. Haftada 0 gün varsa noktalar boş kalır,
yanında metin olmaz. Kaçırılan gün hiçbir şeyi geri almaz; dönüşte tek cümle:
*"Buradasın. Kaldığın yerden devam edelim."*
Kriz modunda rozet, kutlama, illüstrasyon ve seri görünmez; Kova C'de rozet verilir
ama kutlama yapılmaz — rozet raf'ta sessizce belirir.

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

iOS-only SwiftUI native (cross-platform **bilinçli olarak reddedildi** — iş mantığı sunucuda, paylaşılmayan kısım ses motoru + shader, yani RN'in en zayıf yeri) · `AVAudioEngine` · `MeshGradient` + Metal · Rive (opsiyonel; SwiftUI `Path` + `trim` alternatifi var) · SwiftData (yerel) · Node/Python + Postgres (backend) · Sign in with Apple birincil · **RevenueCat** (ürün sahibi kararı, 2026-09-22; PRD'nin "StoreKit 2, RevenueCat opsiyonel" satırını geçersiz kılar; paywall henüz yazılmadı) · PostHog/Amplitude.

Android Faz 4'e ertelendi ve üç koşullu bir karar kapısına bağlandı (D30 ≥%25, LTV > CAC, ayrı kaynak). Kod yazarken backend/blok kütüphanesi/ölçüm mantığı yeniden kullanılabilir kalmalı.

## Faz 0 uyarısı

PRD kendi ifadesiyle **0 kullanıcı görüşmesi ve 0 davranışsal veriyle** yazıldı; içindeki her şey hipotezdir. Faz 0 (10+ problem görüşmesi, elle uygulanan tek bir path, ölçümün gerçekten fark gösterip göstermediği) tamamlanmadan MVP kodlamasına geçilmemesi PRD'nin açık kararıdır. Karar kapısı: elle uygulanan path'te medyan iyileşme %20'nin altındaysa tasarım değişir.

Açık sorular (PRD §18) hâlâ kapanmadı: ürün adı, birincil pazar (TR mi DE/EN mi — fiyatlandırmayı ve ASO'yu değiştirir), ilk path tipi (öneri: uyku), ses kimliği, kova eşikleri, ücretsiz adım sayısı. Bunlara bağlı bir uygulama kararı gerekiyorsa varsayım yapma, kullanıcıya sor.

## 17 Eylül 2026 — kesintisiz manzara ve yön duyarlı başlık

Ürün sahibi iki bağımsız sahnenin koyu birleşimini reddetti. Yolum artık tek uzun
(1:3) guaj çayır görselini, eşleşen açık uçlarda %12 örtüşerek tekrarlar.
Sahne, başlık dahil bütün kaydırılan içeriğin arkasındadır; koyu geçiş maskesi yoktur.
Normal metinde başlık aşağı kaydırmada saklanır, yukarı kaydırmada geri gelir.
Arka planı açık renkli native material ve yalnızca son 32 pt'de yumuşak geçiştir.
AX boyutlarında başlık içerik akışında kalır; Reduce Motion'da yalnızca opacity,
Reduce Transparency'de düz koyu zemin kullanılır.

## 17 Eylül 2026 — Yolum ve Ben ortak guaj yüzeyleri

Yolum durakları krem yüzeylere geçti, tek anchor tabanlı rota satır köşelerini
kaldırdı. Sahne parallax'ı 24 pt, defter parallax'ı 10 pt sınırındadır. Ben'de
krem illüstrasyonlu kapak ve koyu adaçayı bölüm kartları kullanılır. Mobbin Ahead
kişisel kayıt ve Finch profil grupları incelendi; detaylar profile-design §20.
Krizde dekoratif hareket ve anonim hesap bağlama çağrısı gösterilmez.

## 19 Eylül 2026 — oturum ekranı: oynatma kontrolleri ve faz görseli

Ürün sahibinin talebiyle oturum ekranı (`SessionStageView`, G1 ve Yolum ortak)
yeniden düzenlendi. Kontroller: 15 sn geri · krem kâğıt oynat/duraklat · 15 sn
ileri (cam) + "Burada duralım". İleri sarma kapanış sahnesinin içine atlamaz.
Kalan süre hâlâ sayıyla gösterilmez. Kilit ekranı/kulaklık 15 sn atlama da çalışır.
Ses varken sahne saati sesin saatini okur (iki saat artık kaymıyor); duraklatma
durumu sesten okunur, kilit ekranından duraklatınca sahne de durur. Kaldığı yerden
devam eden seste sahne de o noktadan başlar. Ortadaki guaj görsel adımın fazından
seçilir (`SessionArtwork`), arka planla aynı nefeste %3 ölçeklenir; Reduce Motion
ve duraklatmada durur, AX boyutlarında gösterilmez, varlık yoksa yer kaplamaz.
Görsel adları ve prompt'lar: `assets/illustrations/session/prompts.md`.

## 19 Eylül 2026 — Ben v2 ve gamification kural güncellemesi

Ürün sahibi "Ben" sekmesinin v2 düzenlemesini onayladı: kimlik kartı (fotoğraf, ad,
yol, mini iz, haftalık ritim noktaları), illüstrasyonlu defter kartı ve kullanıcı
notlarıyla ayrı defter sayfası, kilometre taşı rozetleri ve nazik haftalık seri,
koyu orman dilinde bütünleşik ayarlar. Bunun gerektirdiği kural değişikliği:
gamification artık kategorik yasak değil, **sınırları çizilmiş serbestlik** —
serbest: rozet, nazik seri, kutlama; yasak kalan: toplam sayılar, lig/kıyas,
sıfırlanan ilerleme, kayıp bildirimi, sahte aciliyet, can/enerji (yukarıda
"Değiştirilemez kurallar" güncellendi). Seri kırılınca mesaj yok; bildirimde seri
yok. Rozet anı kutlaması Sıcak kademesindedir (sade beliriş + tek yumuşak
haptik); kriz ve Kova C'de Nötr — Kova C'de rozet raf'ta sessizce belirir,
kutlama yaprağı açılmaz. "Yürüdüğün yollar" ve "Sana göre ayarlananlar" bölümleri
geçersiz: ilki rozetlere, ikincisi Ayarlar'a taşınıyor; sürüm yazısı profilden
kalkıp ayarların en altına iniyor. PRD §10'un "streak yok" satırı bu kararla
kısmen geçersizdir (PRD gövdesi güncellenmedi; karar günlüğü #17'ye bak). Plan:
`docs/profile-v2-plan.md`; tasarım: `docs/profile-design.md` §21; görseller:
`assets/illustrations/me-v2/prompts.md`.

## 19 Eylül 2026 — Ben v2 uygulandı

`docs/profile-v2-plan.md` Aşama 0–8 kodda bitti. Sayfa: kimlik kartı (fotoğraf, ad,
yol, iz, haftalık ritim), guaj defter kartı (bulanık önizleme, kapak açılışı, zoom
geçişi), rozet rafı, kompakt "Ne değişti", Destek al; ayarlar dişliyle açılan yaprakta
ve koyu orman + adaçayı dilinde (`PatikaSettings`). Defter ayrı sayfa
(`JournalView`), kullanıcı kendi notunu yazar/düzenler/siler (`NoteComposerSheet`).
"Yürüdüğün yollar" ve "Sana göre ayarlananlar" profilden kalktı; `PathDetailView`
silindi.

- **Kurallar kodda:** `BadgeCatalog.earned` saf ve deterministik; rozet geri alınmaz
  (`BadgeAwarder` yalnızca ekler). Ölçüm rozetleri katılımdan verilir. Kutlama
  yaprağı `BadgeCelebration.shouldPresent` ile denetlenir: kriz modunda ve Kova C
  yol sonunda açılmaz. Seri "bu hafta" demek (`WeeklyRhythm`, pazartesi başlar).
- **Not güvenliği:** cihazdaki `CrisisClassifier`, sonra sunucu taraması
  (`save-note`); sinyalde not yazılmaz ve **`SupportView`** açılır (numara).
  Taslak `NoteDraftStore` dosyasında (`UserDefaults` değil). Kriz metni sunucuda
  `_shared/crisis.ts` tek kaynağından geçer; `providers.ts` kendi listesini tutmaz.
- **Destek al metni** `Support.xcstrings`te: numara cihaz bölgesinden, dil
  `AppLocale.current`ten. Diğer arayüz hâlâ sabit Türkçe.
- **Dağıtıldı (2026-09-20).** Migrasyon `20260919120000_*` ve yedi Edge Function
  (`save-note` yeni; `me-profile`, `delete-journal`, `delete-account`, `complete-step`,
  `update-profile`, `generate-path` güncellendi) uzak projede. Canlı duman testi:
  `python3 scripts/live-smoke-ben-v2.py` (39/39; iki anonim kullanıcı açar ve
  siler). Hâlâ açık: cihazda gerçek fotoğraf seçimi, VoiceOver turu, Destek
  numaralarının resmî kaynaktan doğrulanması.
- **Görsel yoksa ekran kırılmaz:** `PatikaArt.exists(_:)` varlığı sorar; yoksa ya yer
  kaplamaz ya da adaçayı düz yüzey çizilir (`PatikaPaperTexture`, `BadgeMedallion`,
  `JournalCoverFace`). `-patika-debug-no-art` bütün görselleri yokmuş gibi gösterir.
  AX boyutlarında defter kapağı da düz yüzeydir (dekoratif görsel saklanır).
- **Fotoğraf önbelleği:** `me-profile` `avatarUpdatedAt` döndürür; `AvatarStore`
  önbellek sürümü sunucudakinden eskiyse yeniden indirir.
- **`Form` satırları:** `listRowBackground` `Form`a verilince satırlara geçmiyor;
  her satıra `settingsFormRow()` verilir.
- **Defter kartı geçişi:** kapak kartta değil **hedef sayfada**, kâğıdın üstünde
  açılır (`JournalCoverOverlay`) ve zoom geçişiyle aynı anda oynar; sistemin zoom
  geçişi kaynağın anlık görüntüsünü kullandığı için kartın içindeki dönüş görünmez.
- **Test:** `Tests/BadgeCatalogTests` (rozet kuralları, haftalık ritim, eski
  `record.json`'ın okunabilmesi). Test hedefi yok, elle derlenir:

```bash
swiftc -o /tmp/badgetest MyApp/Content/Tone.swift MyApp/Models/DomainEnums.swift \
  MyApp/Models/ProfileRecord.swift MyApp/Models/ProfileSnapshot.swift \
  MyApp/Models/BadgeCatalog.swift MyApp/Models/WeeklyRhythm.swift MyApp/Models/PathPlan.swift \
  MyApp/Models/SessionManifest.swift MyApp/Models/MeasurementLibrary.swift \
  MyApp/Models/MeasurementScoring.swift MyApp/Infrastructure/Backend/RetryPolicy.swift \
  MyApp/Infrastructure/Backend/BackendError.swift MyApp/Infrastructure/Backend/BackendClient.swift \
  MyApp/Features/Onboarding/OnboardingDraft.swift Tests/BadgeCatalogTests/main.swift && /tmp/badgetest
```

  Deno: `npx --yes deno test --allow-read --allow-env --allow-net supabase/functions/tests/`
  (29/29; yeni `notes_contract_test.ts`: şifreleme gidiş-dönüşü, kriz reddi,
  başka kullanıcının notuna 403, rozet tekilliği, avatar kovası).
- **Yerleşim tuzağı:** `scaledToFill` bir görselin ideal genişliği piksel boyutudur;
  yerleşimin içinde durursa üst `ZStack`i ve sayfayı ekrandan geniş yapar
  (kimlik kartı ve rozet başlığı iki yandan kırpılıyordu). Görseller `.background`
  ya da `.overlay` içinde ve `.clipped()` ile durur (`MeBackdrop`, `JournalCoverCard`).
- DEBUG: `-patika-debug-me v2full|v2badges|v2empty|v2crisis`,
  `-patika-debug-me-route journal|badges`,
  `-patika-debug-me-sheet note|badge|settings|change|support`.

## 22 Eylül 2026 — onboarding responsive etkileşim güncellemesi

Ürün sahibi onayıyla onboarding'in soru/teslim akışı güncellendi. Yaş ekranı tek
yaş seçilen bulanık derinlikli wheel'dir; kesin yaş yalnızca akış belleğinde kalır,
kalıcı ve ağ katmanına mevcut `AgeRange` yazılır. B2/B3 doğrudan seçeneklerdir;
B3 aynı guaj sahneyi sabah–gündüz–akşam–gece tonlarında değiştirir. B5 `Other`
metni cihazda kalır ve commit öncesi kriz taramasından geçer. B6 hava durumu
ikonları yerine beş patika taşı ve aynı kompozisyonun ışık/haze karşılığıdır.

Akışın teslim sırası artık `D8 → E1 → H2 → F1 → F2 → commitment → G1 → G2 →
price → H1`dir. Bildirim sistem izni yalnızca H2'de açık kabulün ardından istenir.
F2 uzun otomatik tur değil, ekrana sığan kısa özettir. Taahhüt F2 sonrasındadır:
kullanıcı yerel, korumalı dosyaya kaydedilen imza/işaret çizer; basılı tutma ilk
temasta tepki verir ve G1'den önce “Let’s begin with day one.” mesajı görünür.

Doğrulama: `bash scripts/run-swift-tests.sh` bütün kayıtlı suite'lerde geçti;
`xcodebuild ... SWIFT_EMIT_LOC_STRINGS=NO build` iPhone 17 Pro simülatöründe
başarılı. Varsayılan Dynamic Type'ta age, B2, B3, B5, B6, D1, F2, commitment ve
G2; dar iPhone 16e'de B5, F2, commitment ve G2 elle kontrol edildi. AX5 + Increase
Contrast'ta age, B5, D1, F2, commitment ve G2 denetlendi; AX'te footer içerikle
birlikte akar ve ızgara tek kolona düşer. Reduce Motion'da wheel derinlik hareketi
kalkar. CTA'lar/içerik kesilmiyor, alt siyah bant yok. VoiceOver turu bu kayıtta
yapılmış sayılmaz.
