# Keşfet v2 — ortak guaj diline geçiş, dinamik keşif ekranı, 10 patikalık kütüphane

## Uygulama durumu (20 Eylül 2026)

**Aşama 0–6 tamam ve simülatörde doğrulandı.** Aşama 7 (7 yeni patikanın içeriği) bekliyor;
Aşama 8 kısmen: sekiz görsel teslim edildi ama henüz imageset değil (aşağıya bak).

| Aşama | Durum | Not |
|---|---|---|
| 0 Doküman ve prompt'lar | Tamam | `docs/discover-design.md` v2, `assets/illustrations/discover/prompts.md`, `CLAUDE.md` notu |
| 1 Model | Tamam | `category`, `DiscoverSection`, `DiscoverShelf`, `DiscoverLibrary.Status`, dil |
| 2 Ortak dil | Tamam | `DiscoverStyle` silindi, `Theme.TypeFace`, `PatikaArt.exists` |
| 3 Ana ekran | Tamam | `DiscoverView`, `DiscoverCards`, paylaşılan `ScrollHidesHeader` ve `PathLandscapeScene` |
| 4 Detay | Tamam | push + zoom, `DiscoverTrailMap`, paylaşılan `SignpostRoute`, hero |
| 5 Oturum birleştirme | Tamam | `PathSessionViewModel.Source`, `DiscoverSessionView/ViewModel` silindi |
| 6 Katılım Keşfet'te | Tamam | Yolum devralması kalktı, çoklu katılım, `recency` sırası |
| 7 İçerik: 7 yeni patika | Bekliyor | Katalog hâlâ 3 patika (`breath`, `evening`, `focus`) |
| 8 Görseller + doğrulama | Kısmen | 8 PNG teslim edildi; imageset kaydı, ≤600 KB küçültme ve görsel doğrulama açık |

Plandan sapmalar ve nedenleri:

- **`knownRegions`'a `tr` eklenmedi.** Derlenmiş pakette `tr.lproj` zaten var; `.pbxproj`
  düzenlemek gereksizdi. Asıl hata başkaydı: `String(localized:locale:)` yalnızca
  biçimlendirmeyi etkiliyor, çeviri dilini seçmiyor — içerik Türkçe, arayüz İngilizce
  çıkıyordu. `DiscoverCopy` artık çeviriyi `tr.lproj` alt paketinden okuyor.
- **Ekrandaki konuşulan metin arayüz diline değil ses diline uyar.** Ses ilk sürümde
  İngilizce; oturumda görünen cümle duyulan cümledir (`DiscoverLibrary.audioLocale`).
  Arayüz metni TR olsa bile oturum metni EN kalır.
- **`isPreview` katılıma bağlı.** Keşfet'ten açılan detay, katılınmış patikada canlı
  durumu (tamamlanan adımlar, sıradaki adım, oturum başlatma) gösterir; katılınmamışta
  önizlemedir. Katılma artık ekranı değiştirmez (aşama 6): önizleme canlı duruma döner.
- **Detayın kaydırma miktarı `ScrollOffsetBox`ta.** Ekran bu değeri okumaz, yalnızca hero
  okur; her kaydırma pikselinde bütün detay yeniden çizilmez.
- **Yolum'a dokunuldu (refactor):** başlık kaydırma algılayıcısı, manzara ve rota çizimi
  paylaşıma çıkarıldı. Yolum ekranı yeniden derlenip simülatörde doğrulandı.
- **Durak görünümü paylaşılmadı.** Yalnızca rota çizimi ve basma stili ortak;
  `DiscoverTrailStop` `IllustratedPathStop`un ikizi. Yolum'a dokunma riskini artırmamak
  için bilinçli bırakıldı; iki durak zamanla ayrışırsa tek `SignpostStop`a birleştirilmeli.
- **DEBUG bayrakları:** `-patika-debug-discover-scroll <pt>`, `-patika-debug-discover-expanded <n>`,
  `-patika-debug-discover-enrolled a,b`, `-patika-debug-discover-progress <n>` (katılım
  bayrağı simülatörün UserDefaults'una yazar). `-patika-debug-discover-preview <id>` artık
  sheet değil push açar.

**Aşama 5–6 sapmaları ve nedenleri:**

- **`PathSessionViewModel` `Source` enum'u aldı** (`.personal` / `.prepared`). Plan "dallar
  `pathKind == .prepared` ile atlanır" diyordu; ViewModel'in `path`/`step` alanları kişisel
  tipler (`ActivePath`, `PathStepRecord`) olduğu için dallar tek noktada, `personal` özelliği
  üzerinden ayrıldı: ağ, ölçüm, rozet, kriz ve soru koduna hazır patikadan girilemiyor.
- **Hazır patikada sessiz sürüm yok.** Kişisel patikada ses gelmezse oturum sessiz tamamlanır;
  hazır patikada ses içeriğin kendisi. Kayıt çalınamazsa yeni `Phase.audioUnavailable`
  ("Bu kayıt açılamadı. İlerlemen değişmedi." + "Yeniden dene") gösterilir ve adım
  tamamlanmaz. Tamamlanma yalnızca ses gerçekten başlamış ve sonuna kadar gitmişse yazılır
  (`preparedAudioStarted`). Yeniden deneme için `runner` artık `private(set) var`.
- **Son adımda "Sıradaki adımın seni bekler" denmez.** Bitiş ekranı patikanın son adımıysa
  `allDone`/`allDoneBody` metnini kullanır (`finishedPreparedPath`). "İlk adım tamam"
  (G2 cümlesi) hazır patikada hiç kullanılmaz.
- **`Saved.activeID` alandan tamamen çıkarıldı**, yok sayma için ayrı kod gerekmedi:
  `Codable` bilinmeyen anahtarı okurken atlıyor. Eski bir kayıtla test edildi.
- **"Kaldığın yerden" sırası** `activeID` yerine `Enrollment.recency` ile belirlenir (en son
  *yeni adım* tamamlayan ya da katılan başta; yeniden dinleme sırayı değiştirmez). Alan
  opsiyonel: bu alandan önce yazılmış kayıtlar okunabilmeli, aksi hâlde ilerleme kaybolurdu.
- **Kişisel patika kartı** artık onay diyaloğu açmaz, doğrudan Yolum'a geçirir
  (`personalConfirm*` metinleri silindi). `joinTitle` "Bu patikaya katılmak ister misin?"
  oldu; "mevcut patikan" kavramı kalktı.
- **Hazır patika oturumu profile dokunmaz:** haftalık ritim, rozet ve `ProfileRecord`
  güncellenmez. Bunun "Ben"deki ritme yansıyıp yansımayacağı ayrı bir ürün kararıdır.
- **`-patika-debug-discover-session <n>`** katılınmış patikada n. adımın oturumunu doğrudan açar.
- **Doğrulama komutu düzeltildi:** aşağıdaki `swiftc` satırı `DiscoverSection.swift` ve
  `DiscoverCopy.swift` olmadan derlenmiyordu; eski ikili dosya kaldığı için test geçmiş
  görünüyordu. Test çalıştırmadan önce `rm /tmp/discovertest`.

Bilinen sınır: kaydırılan içerik durum çubuğundaki saatin altına giriyor (simülatörde
üst kenar efekti görünmüyor; Yolum ve Ben'de de aynı). `discover-world` manzarası ve yedi
yeni kart görseli teslim edildi ama `Assets.xcassets/Discover/` altında düz `.png` olarak
duruyor; imageset olmadıkları için `UIImage(named:)` bulamıyor ve `PatikaArt.exists` hâlâ
false döner. Ekran varlık yokken kırılmıyor (`-patika-debug-no-art` ile doğrulandı), bu
yüzden görseller hiç görünmüyor ama hata da yok.

---

## Context

"Ben" v2 (2026-09-19) ve "Yolum" manzara patikası (2026-09-17) tamamlandıktan sonra
uygulamanın üç sekmesinden ikisi ortak bir görsel dile oturdu: guaj manzara zemini →
krem kâğıt içerik → yalnızca gezinmede cam (`PatikaSurface.swift:5-12` üç katman
kuralı). **Keşfet bu geçişin dışında kaldı** ve ölçülebilir biçimde başka bir üründen
gelmiş gibi duruyor:

- `DiscoverStyle` (`DiscoverView.swift:140-144`) `WoodlandStyle`'ın üç rengini
  bayt bayt yeniden tanımlıyor; paletle (`PaletteController`) hiç konuşmuyor.
- Ekran ham sistem fontlarını (`.largeTitle`, `.caption`) kullanıyor — bunlar SF Pro
  döndürüyor, uygulamanın geri kalanı `Theme.TypeFace.product(_:_:)` ile Rounded.
  **Kullanıcının "Explore yazısının fontu berbat" dediği şey tam olarak bu**
  (`Theme.swift:85-94` bu tokenleri zaten bu sorun için kurmuş).
- Zemin yok, parallax yok, reveal yok, zoom geçişi yok, erişilebilirlik dalı yok
  (`reduceMotion` `DiscoverView.swift:5`'te tanımlı ama hiç okunmuyor).
- Kart yüzeyleri elle çiziliyor; `ProfileCard`/`paperSurface()` kullanılmıyor.
- `DiscoverArtwork` `PatikaArt.exists` sormuyor — görsel eksikse 194 pt boşluk kalıyor.
- Kütüphane **3 patika**; kategori/gruplama alanı yok, `DiscoverPath` yalnızca
  `{id, title, summary, artwork, steps}` (`DiscoverCatalog.swift:17-23`).
- Metin hem arayüzde hem içerikte **İngilizceye sabitlenmiş** (`DiscoverCopy.swift:52`,
  `DiscoverCatalog.swift:6`), oysa katalogda her metnin TR karşılığı hazır duruyor.
- Katılınan hazır patika **Yolum sekmesini ele geçiriyor** (`RootView.swift:73-83`);
  10 patikalık bir kütüphanede kişisel yolu görünmez kılardı.

Bu çalışma Keşfet'i ve hazır patika detay ekranını ortak dile taşır, kütüphaneyi
A2'deki on problem kategorisine birebir karşılık gelen 10 patikaya çıkarır, alt
bölümlere ayırır ve gereken yeni illüstrasyonların prompt'larını üretir.

**Ses engeli duruyor:** `MyApp/Resources/DiscoverAudio/` boş, ElevenLabs 402
döndürüyor, dolayısıyla `audioIsReady` bugün her patika için `false` ve katılım
kapalı. Bu plan bilerek sesten bağımsız ilerler: sesi olmayan patika listede
görünür, "Yakında" durumuyla işaretlenir, katılım düğmesi açılmaz. Sahte ses veya
sahte süre üretilmez.

### Onaylanan kararlar (bu oturum)

1. Kütüphane **10 patika**, kategori başına bir tane (7 adım, sabit).
2. Gruplama **bölüm başlıklarıyla dikey akış**; her bölüm yatay kart şeridi.
3. Dil `AppLocale.current`'e uyar (TR/EN); ses ilk sürümde İngilizce kalır.
4. Tasarım + içerik metinleri şimdi, ses üretimi sonra.
5. Katılınan hazır patika **Keşfet'te kalır** — Yolum devralması kalkar, aynı anda
   birden fazla hazır patikaya katılmak serbestleşir.
6. Keşfet'e **özgü yeni manzara** (`discover-world`), Yolum'unkini paylaşmaz.

---

## Tasarım

### Keşfet ana ekranı

Katman düzeni birebir Yolum'un: `WoodlandStyle.background` → `BreathingMeshBackground(palette: palette.current)`
→ `DiscoverLandscapeScene` (kaydırılan içeriğin `.background`'ı) → krem kâğıt kartlar
→ yüzen cam başlık.

```
[yüzen cam başlık]  "Kendine küçük bir alan"            ← Theme.TypeFace.screenTitle
                    "Hazır patikalar · 7 adım · İngilizce ses"   ← screenNote
                    (28 pt aşağı kaydırınca saklanır, 18 pt yukarıda geri gelir)

Devam ettiğin           ← yalnızca kayıt varsa; açık krem kâğıt kart(lar), 3/7 izi
Kişisel patikan         ← mevcut discover-personal kartı, Yolum'a götürür

Yükü hafifletmek        ← PatikaSectionLabel
  [breath] [beat] [pressure]        ← yatay şerit, .scrollClipDisabled()
Gün sonu ve dinlenme
  [evening] [refill]
Dikkat ve bulunmak
  [focus] [rooms]
Kendine karşı
  [kinder] [carry] [unnamed]
```

- **"Explore" üst etiketi tamamen kalkar** (`discover.title` artık çizilmez); tracked
  `.caption` fontu da. Başlık cümlesi yüzen cam başlığa taşınır ve `screenTitle`
  kullanır — Yolum'un `PathHomeHeader`'ıyla aynı malzeme ve aynı davranış.
- Kart = krem kâğıt (`paperSurface()`), üstte guaj görsel, altında koyu mürekkep
  metin. Yazı **görselin üstüne binmez** (`discover-design.md` "Görsel yön").
- Bölümler `woodlandReveal(index)` ile sırayla belirir (0.045 sn aralık).
- Durum renk dışında da okunur: "Yakında" (ses yok) / "3 / 7" (devam) / kilit yok.

### Patika detayı

Sheet yerine **push**: Keşfet sekmesi `NavigationStack` kazanır, kart
`.matchedTransitionSource(id:in:)`, hedef `.navigationTransition(.zoom(sourceID:in:))`
— "Ben"deki defter geçişinin birebir aynısı (`MeView.swift:65-75`, `:153`).

- **Hero görsel** `MeBackdrop` matematiğiyle: 220 pt'de sönen fade, en çok 10 pt
  parallax, `reduceMotion`/`reduceTransparency`/AX'te hiç çizilmez.
- **Zemin patikanın kendi kategorisinden**: `BreathingMeshBackground(palette:
  Palette.forCategory(path.category))`. Keşfet ana ekranı kullanıcının kendi paletini,
  detay patikanın paletini kullanır — 10 patika 10 farklı yer gibi hissedilir, tek
  satır kodla.
- **Adımlar Yolum'un tabela rotası dilinde**: dönüşümlü iki kolon, çapa tabanlı
  kesintisiz üç katmanlı rota (20 pt gölge / 11 pt krem / 2 pt vurgu), açık duran tek
  kart, "Buradasın" işareti, kilitli adım açılır ama başlamaz.
- **Katılım** yüzen krem eylem satırında; ses yoksa düğme kapalı ve gerekçesi yazılı.
  AX boyutlarında `safeAreaInset` sabitlemesi kalkar, içerikle kayar (mevcut düzeltme
  korunur).

### Oturum birleştirme

`DiscoverSessionView` + `DiscoverSessionViewModel` (125 satır) **silinir**; hazır
oturum da `SessionRunner` + `SessionStageView` üzerinden çalışır.

- Kişisel soru zaten üç katmanda engelli (`SessionManifest.swift:36`, `:58-60`;
  `PathSessionViewModel.swift:81-84`, `:120-132`) — `pathKind == .prepared` yeterli.
- Kazanılan: 15 sn geri/ileri, kilit ekranı kontrolleri, nefesle ölçeklenen faz
  görseli, duraklama durumunun sesten okunması.
- Düzelen hata: `DiscoverSessionViewModel.swift:28` sessizliği sabit `* 10` sn
  sayıyor, `SessionScript.swift:137` ise `BreathCycle.period` kullanıyor.
- Faz görseli için hazır patikaya **yalnızca görsel seçiminde** `PathPlan.phase(on:
  length: .short)` uygulanır. Ölçüm, rozet, kova ve soru **hazır patikada yok**;
  bu sınır değişmez.

---

## Uygulama aşamaları

### Aşama 0 — Doküman ve prompt'lar (yapıldı)
- [x] `docs/discover-design.md` v2: yukarıdaki altı kararı, bölüm taksonomisini ve
  "ses yoksa Yakında" kuralını yazar; mevcut "Açık engel" bölümü korunur.
- [x] `assets/illustrations/discover/prompts.md` — aşağıdaki prompt'lar,
  `assets/illustrations/me-v2/prompts.md` iskeletiyle (yerleşim tablosu → teknik
  şartlar → ortak stil blokları → varlık başına sahne cümlesi → kabul kontrolü).
- [x] `CLAUDE.md`'ye "20 Eylül 2026 — Keşfet v2" karar notu.

### Aşama 1 — Model: kategori, bölüm, dil (yapıldı)
- [x] `DiscoverCatalog.swift`: `DiscoverPath`'e `category: ProblemCategory` ekle;
  `DiscoverSection` enum'u (`relief`, `rest`, `attention`, `self`) ve
  `ProblemCategory → DiscoverSection` eşlemesi. `load` doğrulamasına "her patikanın
  kategorisi benzersiz" eklenir (10 kategori, 10 patika).
  *Uygulama:* dördüncü bölüm `self` değil `toSelf`; ayrıca `DiscoverShelf` ve
  `DiscoverLibrary.Status` eklendi.
- [x] `DiscoverText.value` → `AppLocale.current == .turkish ? tr : en`.
- [x] `DiscoverCopy.localized` → `Locale(identifier: AppLocale.current.rawValue)`
  (`Copy+Me.swift:438-444` zaten bu kalıbı kullanıyor).
  *Uygulama:* bu kalıp dili seçmiyor (yalnızca biçimlendirme); bunun yerine çeviri
  `tr.lproj` alt paketinden okunuyor.
- [ ] ~~`patika.xcodeproj` `knownRegions`'a `tr` eklenmeli — bugün `tr.lproj` hiç
  derlenmiyor, katalogdaki Türkçe karşılıklar ulaşılamıyor.~~
  **Yapılmadı, gerekmedi:** derlenmiş pakette `tr.lproj` zaten var. Asıl hata
  `String(localized:locale:)`in dili seçmemesiydi; `DiscoverCopy` artık çeviriyi
  alt paketten okuyor (bkz. Uygulama durumu).
- [x] `Discover.xcstrings`: yeni bölüm başlıkları, "Yakında", "Devam ettiğin" anahtarları.

### Aşama 2 — Ortak dile geçiş (saf refactor, yerleşim değişmez) (yapıldı)
- [x] `enum DiscoverStyle` **silinir**; tüm çağrılar `WoodlandStyle`'a.
- [x] Bütün ham fontlar `Theme.TypeFace.*` ile değiştirilir (`coverTitle`, `sectionTitle`,
  `cardTitle`, `cardMeta`, `rowCaption`, `rowAction`, `action`). Satır içi
  `.weight(...)` kalmaz.
- [x] `DiscoverArtwork` `PatikaArt.exists(_:)` sorar; yoksa yer kaplamaz.
  `-patika-debug-no-art` artık Keşfet'i de etkiler.
- [x] Kart yüzeyleri `paperSurface()` / `ProfileCard`'a geçer.

### Aşama 3 — Keşfet ana ekranı v2 (yapıldı)
- [x] ~~Yeni: `DiscoverLandscapeScene.swift`~~ Ayrı dosya yazılmadı, `PathLandscapeScene`
  parametrik yapıldı (`assetName`) — `PathLandscapeScene`'in birebir tekniği
  (`width*3` karo, %12 örtüşme, `-1..<count+1`, `.visualEffect` 24 pt parallax,
  `reduceTransparency`/AX'te hiç çizilmez), tek fark varlık adı `discover-world`.
  → `PathLandscapeScene` **parametrik hale getirilip paylaşılır** (`assetName`), iki
  kopya bırakılmaz.
- [x] `DiscoverView` yeniden yazılır: `onScrollGeometryChange` + `PathHeaderScrollTracking`
  kalıbıyla saklanan yüzen cam başlık (bu tracking sınıfı da paylaşıma çıkarılır;
  *uygulama:* `ScrollHidesHeader.swift` içinde `scrollHidesHeader(_:)` modifier'ı,
  Yolum da onu kullanıyor),
  bölümler, `BadgeShelf.swift:51-71`'deki yatay şerit kalıbı, `woodlandReveal`.
- [x] `DiscoverPathCard` krem kâğıt karta dönüşür.

### Aşama 4 — Patika detayı v2 (yapıldı)
- [x] Keşfet sekmesi `NavigationStack` + `[DiscoverRoute]`; sheet kaldırılır.
- [x] `@Namespace` + `matchedTransitionSource` / `.navigationTransition(.zoom(...))`.
- [x] Yeni: `DiscoverTrailMap.swift` — adım rotası.
- [x] **Ortak çıkarım:** `IllustratedPathMap.swift`'teki `PathStopAnchors` PreferenceKey,
  `continuousRoute(_:)` ve üç katmanlı çizim `MyApp/DesignSystem/Components/SignpostRoute.swift`'e
  taşınır; hem Yolum hem Keşfet oradan kullanır. İki ayrı rota çizimi bırakmak, ikisinin
  zamanla ayrışması demekti.
- [x] Hero görsel `MeBackdrop` fade/parallax matematiğiyle.

### Aşama 5 — Oturum birleştirme (yapıldı)
- [x] `DiscoverSessionView.swift` ve `DiscoverSessionViewModel.swift` silinir.
- [x] `PathSessionViewModel`'e hazır patika girişi: `DiscoverLibrary.playback(for:in:)`'ten
  gelen `SessionPlayback` doğrudan verilir (ağ isteği, ölçüm, rozet, `completeStep`
  dalları `pathKind == .prepared` ile atlanır); tamamlanınca
  `library.complete(step, in: path)`.
- [x] `SessionArtwork` faz eşlemesi yalnızca görsel için (yukarıdaki sınır).

### Aşama 6 — Katılım Keşfet'te kalır (yapıldı)
- [x] `RootView.MyPathTab` sadeleşir → `MyPathView()`. `DiscoverView`'ın `onOpenPath`
  parametresi kişisel kart için kalır, katılım için kalkar.
- [x] `DiscoverLibrary`: `Saved.activeID` kullanımdan kalkar (çözümlenir, yok sayılır —
  eski kurulum kırılmaz); `enrollments` birden fazla aktif kayda izin verir;
  `openPersonalPath()` silinir. Depolama anahtarı `discover.library.v1` **aynı kalır**.
- [x] `Tests/DiscoverLibraryTests/main.swift` bu sözleşmeye göre güncellenir + yeni vaka:
  "iki patikaya aynı anda katılım ilerlemeleri karıştırmaz".

### Aşama 7 — İçerik: 7 yeni patika (bekliyor)
`MyApp/Content/Discover/discover-catalog.json` + **birebir aynısı**
`supabase/functions/render-discover-audio/catalog.json`. Her adım TR/EN `guidance`
(~270-320 karakter) + paylaşılan `closing` + `quietSeconds: 40`.

| id | kategori | TR | EN | bölüm |
|---|---|---|---|---|
| `breath` ✔ | anxiety | Nefese yer aç | Room to breathe | Yükü hafifletmek |
| `beat` | anger | Tepkiden önce bir an | A beat before | Yükü hafifletmek |
| `pressure` | exam | Baskı günlerinde | On pressure days | Yükü hafifletmek |
| `evening` ✔ | sleep | Akşamı yavaşlat | Evening, unhurried | Gün sonu ve dinlenme |
| `refill` | burnout | Yavaşça toparlan | Slowly refill | Gün sonu ve dinlenme |
| `focus` ✔ | focus | Bir seferde tek şey | One thing at a time | Dikkat ve bulunmak |
| `rooms` | social | İnsanların arasında | Among other people | Dikkat ve bulunmak |
| `kinder` | selfcrit | Kendine daha yumuşak | Kinder to yourself | Kendine karşı |
| `carry` | grief | Yanında taşımak | Carrying it with you | Kendine karşı |
| `unnamed` | unnamed | Adını koyamadığında | When you can't name it | Kendine karşı |

> Metinler `Tone.swift` yasaklı ifade taramasından geçmeli ve teşhis/garanti dili
> içermemeli. `docs/discover-design.md`'deki "kişiselleştirilmiş program veya klinik
> müdahale değildir" sınırı korunur. Yeni metinler klinik gözden geçirme beklemeden
> yayına alınmaz (PRD-Ek Path Üretimi §2.3 ile aynı süreç kuralı).

### Aşama 8 — Görseller + doğrulama (kısmen)
Görseller `MyApp/Assets.xcassets/Discover/` altına **birebir bu adlarla** konur.

- [x] Sekiz görsel üretildi ve `Assets.xcassets/Discover/` altına kondu (`discover-world`,
  `-beat`, `-pressure`, `-refill`, `-rooms`, `-kinder`, `-carry`, `-unnamed`).
- [ ] Her biri `discover-*.imageset` klasörüne taşınır (`Contents.json` + `artwork.png`,
  mevcut `discover-evening.imageset` ile aynı kalıp). Şu an düz `.png`; katalog bunları
  görmüyor.
- [ ] Boyut ≤600 KB'a indirilir. Sekizi de ~3 MB (toplam ~24 MB); hedef toplam ≤8 MB.
- [ ] `discover-world` ölçüsü: istenen 1024×3072, gelen 724×2172 (oran aynı, 1:3). Yeterli
  netlik mi, simülatörde bakılır.
- [ ] `discover-world` dikiş kontrolü: üst üste iki kez döşenince görünür kesit var mı,
  orta %65 kartların altında sakin mi.
- [ ] Yedi kart görselinin kartta (üstten kırpılma) ve detay hero'sunda görsel doğrulaması.
- [ ] Aşağıdaki "Doğrulama" tablosundaki açık maddeler.

---

## Gereken illüstrasyonlar (8 yeni varlık)

| Image Set | Boyut | Nerede |
|---|---|---|
| `discover-world` | 1024×3072, opak, dikey döşenebilir | Keşfet zemin manzarası |
| `discover-beat` | 1536×1024, opak | Öfke patikası kartı + detay hero |
| `discover-pressure` | 1536×1024, opak | Sınav/performans |
| `discover-refill` | 1536×1024, opak | Tükenmişlik |
| `discover-rooms` | 1536×1024, opak | Sosyal |
| `discover-kinder` | 1536×1024, opak | Kendine sertlik |
| `discover-carry` | 1536×1024, opak | Kayıp |
| `discover-unnamed` | 1536×1024, opak | Adı konmamış |

Mevcut `discover-evening`, `discover-breath`, `discover-focus`, `discover-personal`
değişmez.

> **Boyut uyarısı:** mevcut dört PNG ~2,7 MB/adet, toplam ~11 MB. On patikada bu 27 MB'a
> çıkar. Üretimden sonra hepsi ImageOptim/`pngquant` ile **≤600 KB**'a indirilmeli;
> hedef toplam ≤8 MB.

### Ortak stil bloğu — opak sahne

```
Use case: illustration-story. Create ONE production-ready opaque PNG illustration for the native iOS app Patika. Reference images are STYLE REFERENCES ONLY, not edit targets. Match their handmade gouache, rich dry-brush pigment texture, flat editorial storybook depth; absolutely not 3D, glossy, clay, glass, photorealistic or vector clipart. Palette: dark teal, muted sage, dusty cobalt blue, warm cream and a little apricot/ochre. The image fills the canvas completely edge to edge; no frame, no border, no vignette, no text, no letters, no watermark, no people, no faces, no hands. Very calm, quiet, matte, soft even light. No summit, no staircase, no flag, no rising achievement curve, no game world, no trophy, no celebration. Landscape 1536x1024.
```

Referans görseller: `illustration-trail`, `illustration-rest`, `illustration-shelter`.

### 1. `discover-world` — Keşfet manzarası (1024×3072)

Yolum'un tek patikasına karşılık Keşfet'in **çok yönlü açıklığı**. `PathLandscapeScene`
tekniğiyle %12 örtüşerek tekrar edeceği için üst ve alt %12'nin birebir eşleşmesi zorunlu.

```
Create a vertically tileable very tall 1024x3072 gouache landscape background for a scrolling wellness discovery screen. Use reference only for hand painted gouache style and sage/teal palette. Elevated top-down open meadow landscape where three or four soft cream footpaths gently diverge and wander apart, never converging to a single destination. A small still pond in the upper third right, a low sage grove at left middle, a shallow stream curving across the lower third. Wide calm sage clearing down the central 65 percent for overlay interface. CRITICAL top and bottom edges must match seamlessly: both have identical medium sage meadow ground and sparse low shrubs only at extreme lateral edges. No dark vignette, no dark border, no foreground leaves, no horizon, no objects across upper/lower edges, no dark horizontal bands. Keep last and first 12 percent almost uniform sage meadow textured brushwork, same brightness and color, allowing vertical repeat. Trees clustered only at lateral edges in middle 75 percent. Continuous soft natural terrain with consistent brightness, no panel separations. No single dominant path, no text, no UI, no people. Full bleed opaque image. Long aspect ratio 1:3.
```

Kontrol: üst üste iki kez döşendiğinde dikiş görünüyor mu? Orta %65 kartların altında
sakin kalıyor mu?

### 2–8. Patika kartı görselleri

Hepsi `[ortak stil bloğu]` + aşağıdaki sahne cümlesi. Her biri geniş yatay kompozisyon;
kartta üstten kırpılacağı için **ilgi merkezi karenin alt yarısında değil, ortasında**
durmalı.

| Varlık | Sahne cümlesi | Feeling |
|---|---|---|
| `discover-beat` | `A single smooth cream stone resting in a shallow teal stream, the water parting calmly around it and rejoining just past it; low sage grasses on both banks; the moment before the current closes again.` | Bir an duraklamak |
| `discover-pressure` | `A wide open sage field under a broad quiet sky, with one clear unhurried cream path running straight across it from edge to edge; a few low shrubs at the far lateral edges; nothing blocking the way, nothing rushing.` | Baskı varken alanın olması |
| `discover-refill` | `A slow narrow stream feeding a small still pool in a sheltered sage hollow at first light; warm cream light gathering on the water surface; the pool is only partly full and filling without hurry.` | Yavaşça dolmak |
| `discover-rooms` | `A loose grove of slender dark teal trees with generous warm cream gaps of light between them, and an unhurried cream path passing through the gaps rather than around the grove; open on both sides.` | Aralarında geçebilmek |
| `discover-kinder` | `A low sheltering canopy of muted sage leaves arching over a small warm cream clearing, one soft apricot lantern glow resting on the ground beneath it; nothing enclosed, one side open to the meadow.` | Kendine sığınak açmak |
| `discover-carry` | `A quiet evening riverbank in deep teal and dusty blue, a single small cream boat moored at the near edge, its long soft reflection on the still water, one small apricot lantern at its bow; the river continues past the frame.` | Yanında taşıyarak yürümek |
| `discover-unnamed` | `Soft low morning mist over rolling sage hills, where a warm cream path clearly begins in the foreground and then fades gently into the mist without a visible end; the beginning is certain, the destination is not.` | Adını bilmeden başlamak |

---

## Değiştirilmeyen sınırlar

- Hazır patikada **ölçüm, rozet, kova, kişisel soru ve sunucuya cevap yazımı yok**.
  Faz eşlemesi yalnızca görsel seçimi içindir.
- Ses yoksa katılım açılmaz; sahte süre veya sahte ilerleme üretilmez.
- Kriz modunda dekoratif görsel ve hareket gösterilmez.
- Sayısal sosyal kanıt yok ("89 bin kişi başladı" tipi satır eklenmez).
- Hazır patika ilerlemesi cihazda kalır, kişisel sunucu patikasını hiçbir koşulda
  silmez veya üzerine yazmaz.
- Tüm animasyonlar 800 ms altı; parallax ≤24 pt; `reduceMotion`/`reduceTransparency`/
  AX dalları `MeBackdrop`, `PathLandscapeScene` ve `MyPathView`'daki kalıpların aynısı.

---

## Doğrulama

```bash
# Derleme
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Hazır patika sözleşmesi (test hedefi yok, elle derlenir)
# Son çalıştırma 20 Eylül 2026: PASS. Katalog aynası: birebir aynı (3 patika).
rm -f /tmp/discovertest
swiftc -o /tmp/discovertest MyApp/Content/Tone.swift MyApp/Models/DomainEnums.swift \
  MyApp/Models/SessionManifest.swift MyApp/Features/Discover/DiscoverCatalog.swift \
  MyApp/Features/Discover/DiscoverSection.swift MyApp/Content/Discover/DiscoverCopy.swift \
  MyApp/Features/Discover/DiscoverLibrary.swift \
  Tests/DiscoverLibraryTests/main.swift && /tmp/discovertest

# Katalog aynası birebir mi?
diff MyApp/Content/Discover/discover-catalog.json \
     supabase/functions/render-discover-audio/catalog.json
```

Simülatörde görsel doğrulama (`xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp <bayrak>`):

| Kontrol | Nasıl | Durum |
|---|---|---|
| Başlık fontu ve "Explore" etiketinin kalktığı | `-patika-debug-tab kesfet` | Tamam |
| Bölümler, şeritler, reveal sırası | aynı | Tamam |
| Görsel yokken ekran kırılmıyor | `-patika-debug-no-art` | Tamam |
| Kart → detay geçişi açılıyor | `-patika-debug-discover-preview evening` | Tamam; zoom animasyonu ekran görüntüsünde görünmez, açık |
| AX5'te başlık akışa giriyor, hero ve manzara saklanıyor | `-patika-debug-ax5` | Tamam (aşama 0–4) |
| Devam ettiğin bölümü | `-patika-debug-discover-enrolled evening` | Tamam (1 / 7 kartı) |
| Aynı anda iki patikaya katılım, ilerlemeler ayrı | `-patika-debug-discover-enrolled evening,focus` | Testte tamam; arayüzde iki kartla henüz bakılmadı |
| Yolum kişisel patikada kalıyor (devralma yok) | katılımdan sonra Yolum sekmesi | Tamam |
| Oturum: hazır patika `PathSessionView` ile çalışıyor, bitiş ekranı, ilerleme cihazda | `-patika-debug-discover-session 1` | Tamam, geçici test kayıtlarıyla (repoda yok) |
| Ses yokken oturum hata ekranı, adım tamamlanmıyor | aynı, gerçek pakette | Tamam |
| Gerçek ElevenLabs kaydıyla çalma, kilit ekranı, kesinti, arka plan | cihaz | Açık (ses üretimi engeli) |
| `discover-world` ve yedi kart görseli | imageset'ler eklendikten sonra | Açık (Aşama 8) |
| Reduce Motion / Reduce Transparency / Increase Contrast | Ayarlar > Erişilebilirlik | Açık |
| VoiceOver turu | cihaz | Açık |

Kapanmadan önce: `docs/discover-design.md` "Doğrulama" bölümü gerçekte koşturulanlarla
güncellenir; ses hâlâ üretilmediği için **uçtan uca çalma/tamamlanma doğrulaması açık
kalır** ve bu doküman ile `CLAUDE.md`'de açıkça yazılı durur.
