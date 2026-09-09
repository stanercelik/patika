# Patika repository instructions

Bu dosya, repository kokunde calisan tum kod ajanlari icin `/init` kurallaridir.
Patika, kullanicinin kendi sorununu anlattigi ve 7/14/21/28 gunluk, olculen ve
biten bir zihinsel iyi olus programi aldigi native iOS uygulamasidir. Urun bir
meditasyon kutuphanesi, chatbot, terapi veya klinik degerlendirme araci degildir.

## Kaynak onceligi

Karar verirken su sirayi kullan:

1. Kullanicinin bu oturumdaki acik talebi.
2. Bu `AGENTS.md` dosyasindaki kurallar.
3. Kodda uygulanmis ve `CLAUDE.md` icinde tarihli olarak kaydedilmis daha yeni
   urun sahibi kararlari.
4. Ilgili PRD eki.
5. Ana `docs/PRD.md`.

PRD'ler 4 Eylul 2026 tarihli taslaklardir; kod ve `CLAUDE.md` 8 Eylul 2026
urun sahibi kararlarini da icerir. Bir celiski varsa eski PRD davranisini geri
getirme. Ozellikle su guncel kararlar eski metni ezer:

- Deployment target iOS 26.0'dir; PRD'deki iOS 18 maddesi guncel degildir.
- A1 tek animasyonlu kancadir; uc ekranli karsilama/ozellik karuseli yoktur.
- Urunun hicbir yerinde emoji kullanilmaz; monokrom SF Symbols kullanilir.
- Onboarding sirasinda SOS gosterilmez. Onboarding sonrasinda uygulama kabugunda
  sabittir; B1 ve B4 serbest metin kriz taramasi bloklayicidir.
- B2, B3 ve B6'da secim akisi otomatik ilerletmez. Secim geri bildirimidir;
  kullanici alttaki `Devam` dugmesiyle onaylar.
- Onboarding ust cubugu kalicidir; ekranlar kendi header'ini cizmez.
- Ilerleme gostergesi sayac degil izdir; ucunda dugum yoktur.

Bir urun kararini degistirmeden once ilgili dokumanin karar gunlugunu ve
`CLAUDE.md` kaydini oku. Acik sorulara bagli karar gerekiyorsa varsayma; kullaniciya
sor.

## Her ise baslarken

- Once `CLAUDE.md` dosyasini ve degisecek ozellikle ilgili PRD bolumlerini oku.
- Repository durumunu ve mevcut kod kalibini incele; kullanici degisikliklerini
  koru, ilgisiz dosyalari duzeltme veya geri alma.
- Guvenlik, kriz, olcum, odeme, gizlilik ya da kullaniciya gorunen metin
  etkileniyorsa ilgili degistirilemez kurallari kontrol et.
- Yeni dosyayi `MyApp/` altinda dogru klasore koy. Proje file-system synchronized
  group kullandigi icin `.pbxproj` dosyasini elle duzenleme.
- Is bittiginde kapsamla orantili derleme/test yap ve yalnizca gercek sonucunu
  bildir. Test hedefi yoksa bunu acikca soyle; derlemeyi test diye sunma.

## Proje durumu

- Xcode projesi: `patika.xcodeproj`
- Tek hedef ve sema: `MyApp`
- Uygulama girisi: `MyApp/App/PatikaApp.swift`
- Deployment target: iOS 26.0
- SwiftUI + SwiftData + Observation tabanli native uygulama
- Koyu moda sabit
- A, B ve C onboarding bolumleri calisiyor. D-H bolumleri henuz uygulanmadi ve
  `d0MeasurementIntro` su anda yapilmamis ekranina gider.
- Test target, String Catalog, ses motoru, ag katmani ve sunucu tarafi kriz
  siniflandiricisi henuz yoktur.
- `Shaders.metal` derleme icin zorunludur.

Temel klasorler:

| Yol | Sorumluluk |
|---|---|
| `MyApp/App/` | Uygulama girisi, ortak durum, kok navigasyon |
| `MyApp/Features/` | Ozellik bazli MVVM ekranlari |
| `MyApp/DesignSystem/` | Tema, palet, shader, hareket ve ortak UI |
| `MyApp/Models/` | Domain enum'lari ve SwiftData modelleri |
| `MyApp/Content/` | Ton ve kullaniciya gorunen metin |
| `MyApp/Assets.xcassets/` | Uygulama varliklari |
| `assets/` | Kaynak gorseller, Rive brief'leri ve kurulum notlari |
| `docs/` | Urun spesifikasyonlari ve karar gunlukleri |

## Derleme ve dogrulama

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Test hedefi eklendiginde:

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Sema ve hedefleri kontrol etmek icin:

```bash
xcodebuild -list -project patika.xcodeproj
```

Metal toolchain eksikse:

```bash
xcodebuild -downloadComponent MetalToolchain
```

Gorsel bir degisiklikte yalnizca derleme yeterli degildir. Simulatorde normal
metin boyutu, buyuk Dynamic Type, Reduce Motion ve Reduce Transparency
davranislarini kontrol et. Kontrast, kirpilma, tasma ve dokunma alanlarini da
dogrula.

## Mimari ve kodlama kaliplari

- MVVM kullan.
- ViewModel: `@Observable @MainActor final class`. Karar, validasyon ve navigasyon
  burada bulunur; ViewModel `SwiftUI` import etmez.
- View yalnizca yerlesim ve binding yapar. Is kuralini `if`/`switch` ile yeniden
  hesaplamaz; ViewModel veya domain modelindeki hazir ozelligi okur.
- Ekran ViewModel'ini View'in `init`inde `@State private var` olarak kur.
- Akis nesnesini disaridan enjekte et. Onboarding'in tek akis sahibi
  `OnboardingFlowViewModel`dir; adim ViewModel'leri birbirini tanimaz.
- `OnboardingDraft` gecici bir `struct` olarak kalir. Akis bitmeden SwiftData'ya
  yarim `ProblemStatement` veya `UserProfile` yazma.
- Paylasilan durumu `.environment(...)` ile gecir.
- Urun kararlarini ekranda tekrarlanan kosullara dagitma. Domain enum'u veya tek
  kaynak API ile ifade et. Mevcut ornekler: `OutcomeBucket.allowsSelling`,
  `badgeShowsNumbers`, `ToneTier`, `BannedPhrases`, `BreathAmplitude.crisis`,
  `ProgramPath.needsAdaptation`, `UserProfile.canClaimFreeContinuation`.
- SwiftUI `Path` tipiyle cakismamak icin domain tipi `ProgramPath` olarak kalir.
- Yeni bagimlilik eklemeden once sistem API'si ve mevcut tasarim sistemiyle
  cozumu tercih et.

## Degistirilemez guvenlik kurallari

- Kullanicinin girdigi her serbest metin kriz siniflandiricisindan gecmelidir.
  B1 ve B4 cihaz ici on filtreden gecer; path uretimi eklendiginde sunucuda tekrar
  siniflandirma zorunludur.
- Kriz sinyali varsa akis durur: path uretilmez, olcum yapilmaz, kayit veya odeme
  istenmez. Ekranda hareket ve kutlama olmaz.
- Kriz ekraninda harita yerine ulkeye uygun acil numara birincil sunulur.
- `Destek al` onboarding sonrasinda her zaman gorunur, ucretsizdir, paywall
  arkasina konmaz ve reklam/yetkin uzman yonlendirme komisyonuyla paraya cevrilmez.
- Teshis koyma veya ima etme. Ilac onerme ya da ilac yorumu yapma. Travma
  ayrintisi isteme. EMDR veya maruz birakma gibi terapotik mudahale uretme.
- `terapi`, `tedavi`, `klinik olarak kanitlanmis`, `iyilestirecek`, `gececek` gibi
  teshis/garanti/tedavi iddialari kullanma.
- Kriz siniflandiricisinin esigi gevsek kalir: yanlis pozitifin maliyeti destek
  ekrani, yanlis negatifin maliyeti guvenlik ihlalidir.
- Uygulama 18+ urundur.

## Olcum ve sonuc kurallari

- GAD-7, PHQ-9, PSS gibi klinik olcekleri kullanma veya kopyalama.
- Olcum uc katmanlidir: duygu siddeti %30, davranis %40, oz-yeterlik %30.
- Baseline ilk iki gunun ortalamasidir. Noktalar baseline, gun 7, gun 14 ve sondur.
- Maddeler A/B/C/A varyantlariyla doner.
- Skoru mutlak yorumlama. Yalnizca kullanicinin kendi gecmisiyle karsilastir.
- Baseline sonunda skor gosterme; ilk karsilastirma gun 7'de gorunur.
- Her olcum ekraninda bunun klinik degerlendirme olmadigini belirt.
- D1-D8 baseline bolumu atlanamaz; diger onboarding bolumlerinde belgelenmis
  cikis kapilarini koru.
- Sonuc dili `basarili/basarisiz` degil A/B/C kovalaridir.
- Kova C'de satis, upsell veya indirim yoktur. Farkli yaklasimli devam ucretsizdir;
  omur boyu en fazla iki ucretsiz devam hakki vardir.
- Kova C rozeti sonucu uydurmaz; sayisal ilerleme yerine yalnizca emegi tanir.
- Gercek veri yokken sosyal kanit veya sayisal sonuc yazma. C3 grafiginde eksen
  sayisi yoktur ve `sonuc vaadi degil` notu kaldirilamaz.

## Ticari ve davranissal kurallar

- Onboarding'de paywall yoktur. F4 yalnizca fiyat seffafligi ekranidir ve kart
  bilgisi istemez.
- Paywall gun 7 olcum ve karsilastirma ekranindan sonra gelir; asla once degil.
- Tek patika ve abonelik ayni kullaniciya farkli gizli fiyatlarla sunulmaz.
  Segmentasyon yalnizca hangi planin vurgulandigini degistirebilir.
- Aboneligin farki indirim degil sureklilik ve biriken baglamdir.
- Odeme/abonelik secimlerinde onceden isaretli secenek veya default bias kullanma.
- Streak, lig, siralama, can/enerji, kullanicilar arasi kiyas, sifirlanan ilerleme,
  geri sayim, sahte aciliyet ve degisken odul dongusu yasaktir.
- Kacirilan gun ilerlemeyi geri almaz. Donus dili sucluluk yaratmaz.
- Mikro oturum tamamlanirsa adim tam tamamlanmis sayilir; yarim/eksik etiketi yok.
- Oturum sonunda birincil off-ramp uygulamayi kapatma secenegidir; daha fazla
  tuketim ikincildir.

## Gizlilik ve bildirimler

- Ham problem metnini sifreli ve ayri sakla. LLM'e mumkun oldugunca ozet baglam
  gonder; ham metni gonderme.
- Problem metni ve olcum verisini analitik araclara asla gonderme.
- Veri indirme ve hesap silme urun icinden erisilebilir olmalidir.
- Kullaniciya ozel sesler imzali URL ile sunulur.
- Bildirim metni path adini, sorun turunu veya hassas bilgiyi asla icermez.
- Ruh sagligi icerigi icin SMS veya e-posta kullanma; yalnizca push.
- Yerel gunluk hatirlatmalari cihazda `UNCalendarNotificationTrigger` ile planla.
- `UNNotificationInterruptionLevel` yalnizca `.active`; `.timeSensitive`,
  `.critical` ve `.provisional` kullanma.
- OS bildirim iznini ancak H2 aciklamasinda kullanici kabul ettikten sonra iste.
- Bildirim frekansi zamanla azalir; ayni durumda ikinci bildirim gonderme. Art arda
  bes bildirim acilmazsa sistemi durdur veya haftada bire dusur.

## Ton ve kullanici metni

Marka sesi `Sakin, Durust, Yaninda`dir. Gece 02:00'de uyuyamayan ve kendini kotu
hisseden birine yuksek sesle soylenemeyecek cumleyi yazma.

Ton bir ekran icinde yukari cikmaz:

- Notr: kriz, Kova C, Destek al, feragat. Sifir susleme.
- Sakin: oturum, olcum, path haritasi. Yalnizca yumusak hareket/gecis.
- Sicak: Kova A/B sonucu, rozet, oturum sonu. Olculu mikro animasyon.
- Oyuncu: Kesfet, nefes egzersizleri, bos durumlar ve ayarlar.

Kurallar:

- Unlem isaretini neredeyse hic kullanma.
- Konfeti, rainbow modu, ucan parcalar ve emoji kullanma.
- `Harika is cikardin`, `Seni ozledik`, `Serini kaybetmek uzeresin`, `Sadece iki
  gun kaldi`, `Diger kullanicilar`, `Endiselenme`, `Sakin ol`, `Bunu asacaksin`
  ve `Basarisiz` ifadelerini kullanma.
- Hata metni kaybin olmadigini veya hatanin kullanicinin sucu olmadigini belirtir.
- Standart buton yerine urun sozlugunu kullan: `Yola cik`, `Kaldigin yerden`,
  `Simdilik degil`, `Bugun gec`, `Bende kalsin`, `Burada duralim`.
- Tam metin ve istisnalar icin `docs/PRD-Ek-Ton-ve-Nudge.md` bolum 3'e bak.
- Kullaniciya gorunen metinler TR ve EN yerellestirmesine hazir olmali. String
  Catalog eklendiginde sabit ekran metnini View icine dagitma.

## Onboarding kontrati

- Toplam hedef akis 31 ekrandir: A kanca, B kesif, C yansitma, D olcum, E tercih,
  F uretim/teslim, G ilk oturum, H hesap/izin.
- Her ekran ya kullanici hakkinda veri toplar ya da toplanani kullaniciya yansitir.
  Ozellik karuseli veya sirketi anlatan ekran ekleme.
- Hesap G1 ilk degerinden sonra H1'de istenir ve `Simdilik gec` gercekten calisir.
- A2 en fazla iki kategori secimine izin verir. Secim paleti canli degistirir.
- B1 ve B4 metninde otomatik duzeltme kapali kalir; kullanicinin kelimeleri F2 ve
  G1'de geri kullanilir.
- B5'te `Hicbir sey` diger seceneklerle birlikte secilemez. Terapi secimi tonu,
  onceki uygulama secimi C3 kosulunu degistirir.
- C bolumu soru sormaz; `OnboardingStatementLayout` kullanir ve cumleler 1 sn
  baslangic araligiyla sirayla belirir. Varligi olmayan illustasyon yuvasi hic yer
  kaplamaz. C1 gorseli durum + sure metninden sonra 282 pt, C2 gorseli ilk cumleden
  sonra 292 pt sahnede gelir; erisilebilir Dynamic Type'ta 194 pt'ye kuculur.
- C4 raster gorsel kullanmaz. `ExpectationCurveChart` once kesik/soluk "Diger
  uygulamalar", sonra duz/parlak "Patika" cizgisini `easeInOut` ile cizer. Patika
  ilk 8 gun sakin ilerler, sonra ivmelenir; dikey eksende uydurma sonuc sayisi yoktur.
- D bolumu kendi ilerleme olcegini kullanir. C'de soru izi solar fakat sifira
  ziplamaz.
- E tercihlerinin her biri uygulamanin davranisini gercekten degistirir.
- F1 bekleme adimlari gercek ilerlemeyi temsil eder; espri kullanma.
- G1 ilk oturum kullanicinin kendi cumlesini icerir.
- H2, gizlilik dostu bildirim on izlemesini OS izin penceresinden once gosterir.

## Gorsel sistem

- Uygulama ici dinamik arka plan video degil `MeshGradient` + tek Metal
  `colorEffect` shader'idir. Video yalnizca pazarlama icindir.
- Palet sirasi: kategori, ruh hali, gece modu. Gece modu en son uygulanir.
- Iki kategori harmaninda renk noktalarini mevcut `Palette.blend` kuraliyla sec ve
  daha koyu arka plani koru.
- Ruh hali ekseni agir ucta lacivert, sakin ucta sicak saridir. Ton karisimindan
  sonra luminansi geri kilitle; arka plan kontrastini yanlislikla acma.
- Saf kirmizi kullanma. Ofke paleti yesil-teal kalir.
- Mesh'in dis sinir noktalarini kenarlarda sabit tut; yalnizca merkez noktasini
  hareket ettir.
- `smoothsColors: true` ve perceptual renk uzayini acik yaz.
- Uygulama koyu modda ve sabit RGB degerleriyle calisir.
- Nefes dongusu 10 saniyedir: 4 saniye al, 0.5 saniye tut, 5.5 saniye ver. Tek
  `breathValue(at:)` kaynagi kullanilir.
- Kriz genligi 0, olcum genligi %35, oturum genligi %100'dur.
- Metin kirik beyaz `#F2EFE9`dir. Guvenli bolgede WCAG AA en az 4.5:1; buyuk
  baslikta en az 3:1 kontrast sagla.
- Material blur ile gradyan kimligini yikama; shader icindeki yumusak scrim'i kullan.
- Arka plan render butcesi kare basina 2 ms'dir. Dusuk guc, termal baski,
  arka plan, Reduce Motion ve Reduce Transparency durumlarini ele al.

## Tasarim sistemi ve erisilebilirlik

- Tipografi rollerini `Theme.Weight` uzerinden sec: display heavy, title bold,
  body medium, action bold, emphasis semibold. Satir ici font agirligi yazma.
- Cizgi rollerini `Theme.Line` uzerinden kullan; degerleri ekrana dagitma.
- Semantik font stilleri ve Dynamic Type kullan; sabit punto kullanma.
- AX5'te ozellikle olcum ekranlari ve plan ekrani kirilmamalidir.
- Renk tek basina anlam tasimaz; ikon/ok ve metinle desteklenir.
- Dekoratif gradyan ve animasyonlari VoiceOver'dan gizle. Kontrollerin label,
  value ve hint'lerini anlamli ver.
- Reduce Motion'da kaymayi kaldir ve basit opacity/static duruma gec.
- Reduce Transparency'de duz koyu arka plan kullan.
- Ses efektleri varsayilan kapali; haptik yumusak tek seviyedir ve kapatilabilir.
- Genel animasyonlar 800 ms altinda kalir. Onboarding palette gecisi gibi PRD'de
  acikca belirtilen daha uzun, yavas cevrimsel gecisler istisnadir.
- Dokunma hedefleri en az 44x44 pt olmalidir.

## PRD haritasi

| Belge | Ne zaman okunur |
|---|---|
| `docs/PRD.md` | Urun, olcum, path, guvenlik, fiyat, teknik, yol haritasi |
| `docs/PRD-Ek-Onboarding.md` | 31 ekran, kopya, kosullar, funnel ve izinler |
| `docs/PRD-Ek-Ton-ve-Nudge.md` | Ton, mikrometin, nudge, bildirim ve erisilebilirlik |
| `docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md` | Palet, shader, animasyon, gorsel brief ve promptlar |

Bu belgelerdeki pazar rakamlari, fiyatlar, yasal tarihler ve platform yayginligi
zamanla degisebilir. Bunlara dayanan yeni bir karar veya kullaniciya verilecek
guncel bilgi icin birincil kaynaktan dogrulama yap; urun kararlarini sessizce
degistirme.

## Faz ve kapsam sinirlari

- Faz 0 dogrulamasi tamamlanmadan temel etkinlik iddiasini kanitlanmis gibi sunma.
- Faz 1: onboarding, olcum, uc path, blok kutuphanesi, hibrit ses, harita, sonuc,
  gun 7 paywall, SOS/Destek al/kriz protokolu.
- Faz 2: hazir path kutuphanesi, artifact, 14/28 gun, rozet, geri kazanim.
- Android ancak D30 retention en az %25, pozitif birim ekonomisi ve ayri gelistirme
  kaynagi birlikte saglaninca degerlendirilir.
- Sosyal akis, topluluk, canli terapist, chatbot, wearable, web/masaustu ve B2B v1
  kapsaminda degildir.

Kapsami genisleten bir ihtiyaci sessizce uygulama. Once hangi PRD kararini veya
faz sinirini etkiledigini belirt ve kullanicidan yon iste.
