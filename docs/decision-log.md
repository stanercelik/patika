# Karar günlüğü (arşiv)

Bu dosya, `CLAUDE.md`'nin şişmesini önlemek için oradan taşınan tarihli günlük
girdilerinin tam metnini tutar (2026-09-23'te taşındı). `CLAUDE.md` artık yalnızca
**güncel durumu** özetliyor; buradaki girdiler o güncel duruma nasıl varıldığının
gerekçesini taşıyor. Bir kararı geri almayı düşünüyorsan önce ilgili girdiyi oku.

Kronolojik sıra korunmuştur (en eski en üstte).

## 16 Eylül 2026 — Yolum düzenlemesi

Ürün sahibinin son talebiyle Yolum başlığı sabit olmaktan çıkarıldı; kaydırma ile
parallax/fade/blur uygular ve geri dönünce görünür. Mevcut adım kartı da artık
kapatılıp yeniden açılabilir; "Buradasın" etiketi ve düğüm konumu korunur.
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
Mevcut durak krem halka ve "Buradasın" ile ayrılır; ayrıntısı açılıp kapanır.
Reduce Motion parallax'ı kapatır; Reduce Transparency ve AX boyutlarında düz
koyu zemine geçilir. Görsel, veri veya ilerleme üretmez; oturum erişimi mevcut
MyPathViewModel kurallarından gelir. Ayrıntılar: `docs/path-home-design.md`.

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
sıfırlanan ilerleme, kayıp bildirimi, sahte aciliyet, can/enerji (CLAUDE.md'deki
"Değiştirilemez kurallar" bu kararla güncellendi). Seri kırılınca mesaj yok; bildirimde
seri yok. Rozet anı kutlaması Sıcak kademesindedir (sade beliriş + tek yumuşak
haptik); kriz ve Kova C'de Nötr — Kova C'de rozet raf'ta sessizce belirir,
kutlama yaprağı açılmaz. "Yürüdüğün yollar" ve "Sana göre ayarlananlar" bölümleri
geçersiz: ilki rozetlere, ikincisi Ayarlar'a taşınıyor; sürüm yazısı profilden
kalkıp ayarların en altına iniyor. PRD §10'un "streak yok" satırı bu kararla
kısmen geçersizdir (PRD gövdesi güncellenmedi). Plan:
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

## 21 Eylül 2026 — onboarding yeniden tasarımı (orman dili, ifade eden girdiler, yeni akış)

Plan ve gerekçeler: `docs/onboarding-redesign.md`. Ürün sahibi kapsamı genişletti:
ekranlar birleştirilebilir/kesilebilir/eklenebilir, onboarding'de fiyat şeffaflığı ve
gamification serbest. İki sınır kalır: **uydurma yorum ya da kullanıcı sayısı yok**,
**kriz yolu bozulmaz**. Baseline ölçümü 8 maddesiyle kalır.

- **Üç katman:** zemin (tam güçte `BreathingMeshBackground`) → kâğıt (krem `paperSurface()`,
  yalnızca okuma/cevap yüzeyi) → sahne (tam ekran guaj). Onboarding'de **A2 ve B6 zemin
  katmanında kalır**: A2 paleti, B6 ruh hâlini arka plana yazar; önlerine kart koymak
  neden-sonucu koparır. Me (0,16) ve Keşfet (0,58) mesh'i dekor olarak kısıyordu, burada
  arka plan içeriktir; o kompozisyonlar miras alınmaz. (⚠️ Bu üç katman kararı
  2026-09-22'de gradyan kaldırıldığında büyük ölçüde geçersiz kılındı — bkz. o girdi.)
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
     cümlesi, `ChoiceRow(detail:)` ile yapıldı. (⚠️ E3'ün kendisi 2026-09-22'de tamamen
     silindi — bkz. o girdi.)
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
  > oturum çizelgesine kilitlenmeli. (⚠️ `BreathingMeshBackground` 2026-09-22'de silindi;
  > bu not artık geçersiz bir yapıya atıf yapıyor.)
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
temasta tepki verir ve G1'den önce "Let's begin with day one." mesajı görünür.

Doğrulama: `bash scripts/run-swift-tests.sh` bütün kayıtlı suite'lerde geçti;
`xcodebuild ... SWIFT_EMIT_LOC_STRINGS=NO build` iPhone 17 Pro simülatöründe
başarılı. Varsayılan Dynamic Type'ta age, B2, B3, B5, B6, D1, F2, commitment ve
G2; dar iPhone 16e'de B5, F2, commitment ve G2 elle kontrol edildi. AX5 + Increase
Contrast'ta age, B5, D1, F2, commitment ve G2 denetlendi; AX'te footer içerikle
birlikte akar ve ızgara tek kolona düşer. Reduce Motion'da wheel derinlik hareketi
kalkar. CTA'lar/içerik kesilmiyor, alt siyah bant yok. VoiceOver turu bu kayıtta
yapılmış sayılmaz.

## 23 Eylül 2026 — Apple/Google girişi native SDK'ya geçti

Ürün sahibinin talebiyle Apple ve Google girişi Supabase'in genel web-OAuth
redirect akışından (`ASWebAuthenticationSession` + `/auth/v1/authorize`) native
SDK'lara taşındı: Apple için `ASAuthorizationAppleIDProvider`, Google için
`GoogleSignIn` SDK (Xcode'da SPM ile eklenecek, henüz eklenmedi). Bu, önceki
"Apple/Google girişi Supabase'in genel OAuth uç noktası üzerinden" örtük
kararını geçersiz kılar; anonim-önce akış (`AuthSessionStore`, Keychain, "yalnızca
kesin ret'te sıfırla" kuralı) **değişmedi**.

- **Tek uç nokta: `/auth/v1/token?grant_type=id_token`.** Her iki sağlayıcı da
  native SDK'dan aldığı `id_token`'ı (Apple: ham nonce'un SHA256 hex'i Apple
  isteğine, ham nonce Supabase'e; Google: `id_token` + `access_token`) bu uca
  gönderir. `signIn` bunu Authorization header'sız çağırır (yeni oturum);
  `link` **mevcut anonim oturumun `access_token`'ını Authorization header'ı
  olarak** ekler — Supabase bunu görünce yeni kullanıcı açmak yerine kimliği
  anonim kullanıcıya bağlıyor (bkz. Supabase "Link identity with native OAuth
  (ID token)" dokümantasyonu). Eski `/user/identities/authorize` redirect
  akışı ve ona bağlı PKCE/`ASWebAuthenticationSession` kodu tamamen kaldırıldı
  (`SupabaseAuthClient.swift`).
- **Apple:** `ASAuthorizationController` + delegate (aynı sınıf, `SupabaseAuthClient`
  zaten `NSObject`). `fullName`/`email` scope'u istenir ama `AuthSession`'a
  yazılmaz — isim zaten ayrı bir onboarding ekranında soruluyor, Apple'ın
  yalnızca ilk girişte verdiği bu veriyi burada tüketmek kırılgan olurdu.
- **Google:** `GIDSignIn.sharedInstance.signIn(withPresenting:)` (completion-handler
  tabanlı, async/await sürümü yok — Context7 ile doğrulandı). `PatikaApp.swift`'e
  `.onOpenURL { GIDSignIn.sharedInstance.handleURL($0) }` eklendi (Google'ın
  sistem tarayıcısından dönen OAuth geri çağırması için gerekli).
- **Dışarıda kalan, kullanıcının tamamlayacağı adımlar (kod bunlara bağlı,
  henüz yapılmadı):** Xcode'da Sign in with Apple capability + GoogleSignIn SPM
  paketi + `CFBundleURLTypes` (reversed client ID); Google Cloud Console'da iOS +
  Web OAuth client; Supabase Dashboard > Auth > Providers'da Apple (Services ID,
  Team ID, Key ID, .p8) ve Google (Client ID/Secret) + "Enable manual linking"
  açık olmalı. `AppConfiguration.live.googleClientID` hâlâ placeholder
  (`GOOGLE_IOS_CLIENT_ID_PLACEHOLDER...`) — gerçek client ID girilmeden Google
  girişi derlenir ama çalışmaz. `.pbxproj` elle düzenlenmedi (CLAUDE.md kuralı);
  capability ve paket eklemesi kullanıcı tarafından Xcode'da yapılacak.
- **Doğrulanmadı:** gerçek cihaz/simülatörde uçtan uca Apple ve Google girişi
  (yukarıdaki dış bağımlılıklar tamamlanmadan test edilemez), `AccountLinkView`/
  `ReturningUserAuthView` UI'ları değişmedi (yalnızca alttaki `AuthClient`
  implementasyonu değişti), `Tests/AuthSessionStoreTests` bu koddan etkilenmedi
  (mock `AuthClient` kullanıyor).
